#!/usr/bin/env python3
"""Security tests for the local read-only API."""
from __future__ import annotations

import argparse
import importlib.util
import json
import socket
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

REPO_DIR = Path(__file__).resolve().parent.parent
SERVER_PATH = REPO_DIR / "api" / "server.py"
sys.path.insert(0, str(SERVER_PATH.parent))
SPEC = importlib.util.spec_from_file_location("audit_suite_api_server", SERVER_PATH)
assert SPEC is not None and SPEC.loader is not None
server_module = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(server_module)


class LoopbackHostTests(unittest.TestCase):
    def test_ipv4_loopback_is_accepted(self) -> None:
        self.assertEqual(server_module.loopback_host("127.0.0.1"), "127.0.0.1")
        self.assertEqual(server_module.loopback_host("127.42.0.9"), "127.42.0.9")

    def test_ipv6_loopback_is_accepted(self) -> None:
        self.assertEqual(server_module.loopback_host("::1"), "::1")
        self.assertEqual(server_module.server_url("::1", 8765), "http://[::1]:8765")

    def test_non_loopback_addresses_are_rejected(self) -> None:
        for host in ("0.0.0.0", "192.168.1.20", "::", "2001:db8::1"):
            with self.subTest(host=host):
                with self.assertRaises(argparse.ArgumentTypeError):
                    server_module.loopback_host(host)

    def test_hostnames_are_rejected(self) -> None:
        with self.assertRaises(argparse.ArgumentTypeError):
            server_module.loopback_host("localhost")

    def test_ipv4_server_binds_only_to_loopback(self) -> None:
        httpd = server_module.create_server("127.0.0.1", 0)
        try:
            self.assertEqual(httpd.server_address[0], "127.0.0.1")
        finally:
            httpd.server_close()

    def test_ipv6_server_uses_ipv6_family(self) -> None:
        self.assertEqual(server_module.ThreadingIPv6HTTPServer.address_family, socket.AF_INET6)
        try:
            httpd = server_module.create_server("::1", 0)
        except OSError as exc:
            self.skipTest(f"IPv6 loopback unavailable in test environment: {exc}")
        try:
            self.assertEqual(httpd.address_family, socket.AF_INET6)
        finally:
            httpd.server_close()


class PublicErrorTests(unittest.TestCase):
    def test_missing_openapi_hides_local_path(self) -> None:
        hidden_path = Path("C:/sensitive/internal/openapi.json")
        handler = object.__new__(server_module.AuditSuiteHandler)
        handler._write_json = mock.Mock()

        with mock.patch.object(server_module, "OPENAPI_SPEC", hidden_path):
            with self.assertLogs(server_module.LOGGER, level="ERROR") as private_logs:
                handler._write_openapi()

        status, payload = handler._write_json.call_args.args
        self.assertEqual(status, server_module.HTTPStatus.NOT_FOUND)
        self.assertEqual(payload["error"], "json_file_missing")
        self.assertNotIn("path", payload)
        self.assertNotIn(str(hidden_path), json.dumps(payload))
        self.assertIn(str(hidden_path), "\n".join(private_logs.output))

    def test_command_failure_hides_command_and_stderr(self) -> None:
        with self.assertLogs(server_module.LOGGER, level="ERROR") as private_logs:
            returncode, payload = server_module.run_json_command(
                [
                    sys.executable,
                    "-c",
                    "import sys; sys.stderr.write('sensitive internal detail'); "
                    "raise SystemExit(7)",
                ],
                timeout_seconds=2,
                max_output_bytes=4096,
            )

        self.assertEqual(returncode, 7)
        self.assertEqual(payload["error"], "command_failed")
        self.assertEqual(payload["returncode"], 7)
        self.assertNotIn("command", payload)
        self.assertNotIn("stderr", payload)
        self.assertNotIn("sensitive internal detail", json.dumps(payload))
        self.assertIn("sensitive internal detail", "\n".join(private_logs.output))

    def test_invalid_json_hides_parser_and_command_details(self) -> None:
        with self.assertLogs(server_module.LOGGER, level="ERROR") as private_logs:
            returncode, payload = server_module.run_json_command(
                [
                    sys.executable,
                    "-c",
                    "print('{invalid')  # internal-command",
                ],
                timeout_seconds=2,
                max_output_bytes=4096,
            )

        self.assertEqual(returncode, 1)
        self.assertEqual(payload["error"], "invalid_command_output")
        self.assertNotIn("command", payload)
        self.assertNotIn("stderr", payload)
        self.assertNotIn("internal-command", json.dumps(payload))
        self.assertIn("internal-command", "\n".join(private_logs.output))


class RunArtifactSecurityTests(unittest.TestCase):
    def test_run_identifier_requires_safe_leading_character(self) -> None:
        for value in ("AUDIT_1", "run-1.2", "A:B"):
            with self.subTest(value=value):
                self.assertTrue(server_module.valid_run_id(value))
        for value in ("", "..", ".hidden", "../private", "run/name", " run"):
            with self.subTest(value=value):
                self.assertFalse(server_module.valid_run_id(value))

    def test_manifest_must_match_the_verified_output_location(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            repo_dir = Path(temp_dir)
            run_id = "AUDIT_SAFE_1"
            run_dir = repo_dir / "output" / run_id
            run_dir.mkdir(parents=True)
            manifest = {
                "kind": "audit-suite.manifest",
                "run_id": run_id,
                "targets": [],
                "modules": [],
                "findings": [],
            }
            (run_dir / "manifest.json").write_text(
                json.dumps(manifest), encoding="utf-8"
            )

            with mock.patch.object(server_module, "REPO_DIR", repo_dir):
                loaded, resolved_run_dir, error = server_module.load_verified_manifest(
                    run_id,
                    {"manifest_path": f"output/{run_id}/manifest.json"},
                )
                self.assertEqual(loaded, manifest)
                self.assertEqual(resolved_run_dir, run_dir.resolve())
                self.assertIsNone(error)

                loaded, _, error = server_module.load_verified_manifest(
                    run_id,
                    {"manifest_path": "api/openapi.json"},
                )
                self.assertIsNone(loaded)
                self.assertEqual(error, "unsafe_manifest_path")

    def test_report_urls_are_created_only_for_known_files(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            run_dir = Path(temp_dir).resolve()
            (run_dir / "report.html").write_text("private", encoding="utf-8")
            inventory = server_module.report_inventory("AUDIT_SAFE_1", run_dir)

        reports = {item["kind"]: item for item in inventory}
        self.assertTrue(reports["private"]["available"])
        self.assertTrue(reports["private"]["url"].startswith("/api/report?"))
        self.assertFalse(reports["shareable"]["available"])
        self.assertFalse(reports["technical"]["available"])
        self.assertNotIn(str(run_dir), json.dumps(inventory))

    def test_sensitive_preview_reports_values_without_inventing_them(self) -> None:
        preview = server_module.sensitive_value_preview(
            {
                "targets": ["192.0.2.0/24"],
                "findings": [
                    {
                        "asset": {
                            "address": "192.0.2.10",
                            "hostname": "fixture.example.invalid",
                        },
                        "evidence": [{"path": "module/evidence.json"}],
                    }
                ],
            }
        )
        self.assertEqual(preview["targets"]["values"], ["192.0.2.0/24"])
        self.assertEqual(preview["asset_addresses"]["values"], ["192.0.2.10"])
        self.assertEqual(
            preview["hostnames"]["values"], ["fixture.example.invalid"]
        )
        self.assertEqual(
            preview["evidence_paths"]["values"], ["module/evidence.json"]
        )


if __name__ == "__main__":
    unittest.main()
