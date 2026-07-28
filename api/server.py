#!/usr/bin/env python3
"""Local read-only API server for AUDIT-SUITE."""
from __future__ import annotations

import argparse
import ipaddress
import json
import logging
import os
import socket
import subprocess
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any
from urllib.parse import parse_qs, urlparse

REPO_DIR = Path(__file__).resolve().parent.parent
WEB_INDEX = REPO_DIR / "web" / "index.html"
OPENAPI_SPEC = REPO_DIR / "api" / "openapi.json"
LOGGER = logging.getLogger("audit_suite.api")

ROUTES: dict[str, list[str]] = {
    "/api/status": ["bash", "bin/status_json.sh"],
    "/api/modules": ["bash", "bin/modules_json.sh"],
    "/api/history": ["bash", "bin/history_json.sh", "list"],
    "/api/history/paths": ["bash", "bin/history_json.sh", "paths"],
    "/api/latest": ["bash", "bin/history_json.sh", "latest"],
    "/api/snapshot": ["bash", "bin/api_snapshot_json.sh"],
}


def api_routes_payload() -> dict[str, Any]:
    return {
        "kind": "audit-suite.api_routes",
        "schema_version": "1.0.0",
        "routes": [
            {"method": "GET", "path": "/", "type": "html"},
            {"method": "GET", "path": "/index.html", "type": "html"},
            {"method": "GET", "path": "/api/health", "type": "json"},
            {"method": "GET", "path": "/api/status", "type": "json"},
            {"method": "GET", "path": "/api/modules", "type": "json"},
            {"method": "GET", "path": "/api/history", "type": "json"},
            {"method": "GET", "path": "/api/history/paths", "type": "json"},
            {"method": "GET", "path": "/api/latest", "type": "json"},
            {"method": "GET", "path": "/api/snapshot", "type": "json"},
            {"method": "GET", "path": "/api/plan", "type": "json", "requires_query": ["targets"]},
            {"method": "GET", "path": "/api/openapi.json", "type": "json"},
            {"method": "GET", "path": "/api/routes", "type": "json"},
        ],
    }


def run_json_command(command: list[str]) -> tuple[int, dict[str, Any]]:
    env = os.environ.copy()
    result = subprocess.run(
        command,
        cwd=REPO_DIR,
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )

    if result.returncode != 0:
        LOGGER.error(
            "JSON command failed: command=%r returncode=%d stderr=%s",
            command,
            result.returncode,
            result.stderr.strip(),
        )
        return result.returncode, {
            "kind": "audit-suite.api_error",
            "error": "command_failed",
            "returncode": result.returncode,
        }

    try:
        return 0, json.loads(result.stdout)
    except json.JSONDecodeError as exc:
        LOGGER.error("JSON command returned invalid JSON: command=%r error=%s", command, exc)
        return 1, {
            "kind": "audit-suite.api_error",
            "error": "invalid_command_output",
            "returncode": 1,
        }


def first_query_value(query: dict[str, list[str]], key: str, default: str = "") -> str:
    values = query.get(key, [])
    if not values:
        return default
    return values[0]


def query_flag_enabled(value: str) -> bool:
    return value.lower() in {"1", "true", "yes", "on"}


def build_plan_command(query: dict[str, list[str]]) -> tuple[list[str] | None, dict[str, Any] | None]:
    targets = first_query_value(query, "targets")
    if not targets:
        return None, {
            "kind": "audit-suite.api_error",
            "error": "missing_query_param",
            "param": "targets",
        }

    command = [
        "bash",
        "bin/plan_json.sh",
        "--profile",
        first_query_value(query, "profile", "fast"),
        "--targets",
        targets,
        "--categories",
        first_query_value(query, "categories", "all"),
    ]

    run_id = first_query_value(query, "run_id")
    if run_id:
        command.extend(["--run-id", run_id])

    if query_flag_enabled(first_query_value(query, "allow_public")):
        command.append("--allow-public")
    if query_flag_enabled(first_query_value(query, "no_udp")):
        command.append("--no-udp")
    if query_flag_enabled(first_query_value(query, "no_zeek")):
        command.append("--no-zeek")
    if query_flag_enabled(first_query_value(query, "no_suricata")):
        command.append("--no-suricata")

    return command, None


class AuditSuiteHandler(BaseHTTPRequestHandler):
    server_version = "AuditSuiteReadOnlyAPI/0.2.34"

    def log_message(self, format: str, *args: Any) -> None:  # noqa: A002
        if getattr(self.server, "quiet", False):
            return
        super().log_message(format, *args)

    def _write_json(self, status: HTTPStatus, payload: dict[str, Any]) -> None:
        body = json.dumps(payload, ensure_ascii=False, indent=2).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def _write_json_file(self, status: HTTPStatus, json_path: Path) -> None:
        if not json_path.is_file():
            self._write_json(
                HTTPStatus.NOT_FOUND,
                {
                    "kind": "audit-suite.api_error",
                    "error": "json_file_missing",
                },
            )
            return
        body = json_path.read_bytes()
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def _write_html(self, status: HTTPStatus, html_path: Path) -> None:
        if not html_path.is_file():
            self._write_json(
                HTTPStatus.NOT_FOUND,
                {
                    "kind": "audit-suite.api_error",
                    "error": "web_index_missing",
                },
            )
            return
        body = html_path.read_bytes()
        self.send_response(status)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self) -> None:  # noqa: N802
        parsed_url = urlparse(self.path)
        path = parsed_url.path

        if path in {"/", "/index.html"}:
            self._write_html(HTTPStatus.OK, WEB_INDEX)
            return

        if path == "/api/routes":
            self._write_json(HTTPStatus.OK, api_routes_payload())
            return

        if path == "/api/openapi.json":
            self._write_json_file(HTTPStatus.OK, OPENAPI_SPEC)
            return

        if path == "/api/health":
            self._write_json(
                HTTPStatus.OK,
                {
                    "kind": "audit-suite.api_health",
                    "status": "ok",
                    "read_only": True,
                },
            )
            return

        if path == "/api/plan":
            command, error_payload = build_plan_command(parse_qs(parsed_url.query))
            if error_payload is not None or command is None:
                self._write_json(HTTPStatus.BAD_REQUEST, error_payload or {})
                return
            returncode, payload = run_json_command(command)
            if returncode == 0:
                self._write_json(HTTPStatus.OK, payload)
            else:
                self._write_json(HTTPStatus.BAD_REQUEST, payload)
            return

        command = ROUTES.get(path)
        if command is None:
            self._write_json(
                HTTPStatus.NOT_FOUND,
                {
                    "kind": "audit-suite.api_error",
                    "error": "not_found",
                    "path": path,
                },
            )
            return

        returncode, payload = run_json_command(command)
        if returncode == 0:
            self._write_json(HTTPStatus.OK, payload)
        else:
            self._write_json(HTTPStatus.INTERNAL_SERVER_ERROR, payload)

    def do_POST(self) -> None:  # noqa: N802
        self._write_json(
            HTTPStatus.METHOD_NOT_ALLOWED,
            {
                "kind": "audit-suite.api_error",
                "error": "read_only",
                "method": "POST",
            },
        )


def loopback_host(value: str) -> str:
    try:
        address = ipaddress.ip_address(value)
    except ValueError as exc:
        raise argparse.ArgumentTypeError(
            "host must be a literal loopback IPv4 or IPv6 address"
        ) from exc

    if not address.is_loopback:
        raise argparse.ArgumentTypeError(
            "non-loopback API binds are not supported; use 127.0.0.1 or ::1"
        )
    return str(address)


class ThreadingIPv6HTTPServer(ThreadingHTTPServer):
    address_family = socket.AF_INET6


def create_server(host: str, port: int) -> ThreadingHTTPServer:
    safe_host = loopback_host(host)
    server_class = ThreadingIPv6HTTPServer if ":" in safe_host else ThreadingHTTPServer
    return server_class((safe_host, port), AuditSuiteHandler)


def server_url(host: str, port: int) -> str:
    formatted_host = f"[{host}]" if ":" in host else host
    return f"http://{formatted_host}:{port}"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="AUDIT-SUITE local read-only API")
    parser.add_argument(
        "--host",
        type=loopback_host,
        default="127.0.0.1",
        help="literal loopback address only (default: 127.0.0.1; IPv6: ::1)",
    )
    parser.add_argument("--port", type=int, default=8765)
    parser.add_argument("--quiet", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    server = create_server(args.host, args.port)
    server.quiet = args.quiet  # type: ignore[attr-defined]
    print(
        f"AUDIT-SUITE read-only API listening on {server_url(args.host, args.port)}",
        flush=True,
    )
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        return 130
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
