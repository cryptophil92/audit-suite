#!/usr/bin/env python3
"""Subprocess budget tests for the local API."""
from __future__ import annotations

import importlib.util
import json
import sys
import time
import unittest
from argparse import ArgumentTypeError
from pathlib import Path

REPO_DIR = Path(__file__).resolve().parent.parent
SERVER_PATH = REPO_DIR / "api" / "server.py"
SPEC = importlib.util.spec_from_file_location("audit_suite_api_server", SERVER_PATH)
assert SPEC is not None and SPEC.loader is not None
server_module = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(server_module)


class CommandBudgetTests(unittest.TestCase):
    def test_slow_command_within_budget_succeeds(self) -> None:
        returncode, payload = server_module.run_json_command(
            [
                sys.executable,
                "-c",
                "import time; time.sleep(0.05); print('{\"ok\": true}')",
            ],
            timeout_seconds=2,
            max_output_bytes=4096,
        )
        self.assertEqual(returncode, 0)
        self.assertEqual(payload, {"ok": True})

    def test_timeout_is_cancelled_and_structured(self) -> None:
        started_at = time.monotonic()
        returncode, payload = server_module.run_json_command(
            [sys.executable, "-c", "import time; time.sleep(5)"],
            timeout_seconds=0.1,
            max_output_bytes=4096,
        )
        elapsed = time.monotonic() - started_at

        self.assertEqual(returncode, 124)
        self.assertEqual(payload["kind"], "audit-suite.api_error")
        self.assertEqual(payload["error"], "command_timeout")
        self.assertEqual(payload["timeout_seconds"], 0.1)
        self.assertLess(elapsed, 2)
        self.assertNotIn("Traceback", json.dumps(payload))
        self.assertEqual(
            server_module.command_error_status(payload, server_module.HTTPStatus.BAD_REQUEST),
            server_module.HTTPStatus.GATEWAY_TIMEOUT,
        )

    def test_stdout_limit_is_enforced(self) -> None:
        returncode, payload = server_module.run_json_command(
            [
                sys.executable,
                "-c",
                "import sys; sys.stdout.buffer.write(b'x' * 200000); sys.stdout.flush()",
            ],
            timeout_seconds=2,
            max_output_bytes=4096,
        )

        self.assertEqual(returncode, 125)
        self.assertEqual(payload["error"], "output_limit_exceeded")
        self.assertEqual(payload["max_output_bytes"], 4096)
        self.assertNotIn("Traceback", json.dumps(payload))
        self.assertEqual(
            server_module.command_error_status(
                payload, server_module.HTTPStatus.INTERNAL_SERVER_ERROR
            ),
            server_module.HTTPStatus.BAD_GATEWAY,
        )

    def test_stderr_limit_is_enforced(self) -> None:
        returncode, payload = server_module.run_json_command(
            [
                sys.executable,
                "-c",
                "import sys; sys.stderr.buffer.write(b'x' * 200000); sys.stderr.flush()",
            ],
            timeout_seconds=2,
            max_output_bytes=4096,
        )

        self.assertEqual(returncode, 125)
        self.assertEqual(payload["error"], "output_limit_exceeded")

    def test_start_failure_is_structured(self) -> None:
        returncode, payload = server_module.run_json_command(
            ["audit-suite-command-that-does-not-exist"],
            timeout_seconds=1,
            max_output_bytes=4096,
        )
        self.assertEqual(returncode, 127)
        self.assertEqual(payload["error"], "command_start_failed")
        self.assertIn("duration_ms", payload)
        self.assertNotIn("Traceback", json.dumps(payload))

    def test_default_budgets_are_safe_and_documented(self) -> None:
        self.assertEqual(server_module.ROUTE_TIMEOUT_SECONDS["/api/snapshot"], 15)
        self.assertEqual(server_module.ROUTE_TIMEOUT_SECONDS["/api/status"], 10)
        self.assertEqual(server_module.DEFAULT_MAX_OUTPUT_BYTES, 1024 * 1024)
        routes = server_module.api_routes_payload()
        snapshot_route = next(
            route for route in routes["routes"] if route["path"] == "/api/snapshot"
        )
        self.assertEqual(snapshot_route["timeout_seconds"], 15)
        self.assertEqual(routes["limits"]["max_output_bytes"], 1024 * 1024)

    def test_configured_budget_is_reflected_in_route_catalog(self) -> None:
        routes = server_module.api_routes_payload(3.5, 8192)
        dynamic_routes = [
            route
            for route in routes["routes"]
            if route["path"] in server_module.ROUTE_TIMEOUT_SECONDS
        ]
        self.assertTrue(dynamic_routes)
        self.assertTrue(
            all(route["timeout_seconds"] == 3.5 for route in dynamic_routes)
        )
        self.assertEqual(routes["limits"]["max_output_bytes"], 8192)

    def test_invalid_limit_values_are_rejected(self) -> None:
        for value in ("0", "-1", "nan", "inf"):
            with self.subTest(value=value):
                with self.assertRaises(ArgumentTypeError):
                    server_module.positive_float(value)
        for value in ("0", "-1"):
            with self.subTest(value=value):
                with self.assertRaises(ArgumentTypeError):
                    server_module.positive_int(value)


if __name__ == "__main__":
    unittest.main()
