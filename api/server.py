#!/usr/bin/env python3
"""Local read-only API server for AUDIT-SUITE."""
from __future__ import annotations

import argparse
import json
import os
import subprocess
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any
from urllib.parse import parse_qs, urlparse

REPO_DIR = Path(__file__).resolve().parent.parent
WEB_INDEX = REPO_DIR / "web" / "index.html"

ROUTES: dict[str, list[str]] = {
    "/api/status": ["bash", "bin/status_json.sh"],
    "/api/modules": ["bash", "bin/modules_json.sh"],
    "/api/history": ["bash", "bin/history_json.sh", "list"],
    "/api/latest": ["bash", "bin/history_json.sh", "latest"],
    "/api/snapshot": ["bash", "bin/api_snapshot_json.sh"],
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
        return result.returncode, {
            "kind": "audit-suite.api_error",
            "command": command,
            "returncode": result.returncode,
            "stderr": result.stderr.strip(),
        }

    try:
        return 0, json.loads(result.stdout)
    except json.JSONDecodeError as exc:
        return 1, {
            "kind": "audit-suite.api_error",
            "command": command,
            "returncode": 1,
            "stderr": f"Invalid JSON output: {exc}",
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
    server_version = "AuditSuiteReadOnlyAPI/0.2.21"

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

    def _write_html(self, status: HTTPStatus, html_path: Path) -> None:
        if not html_path.is_file():
            self._write_json(
                HTTPStatus.NOT_FOUND,
                {
                    "kind": "audit-suite.api_error",
                    "error": "web_index_missing",
                    "path": str(html_path),
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


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="AUDIT-SUITE local read-only API")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8765)
    parser.add_argument("--quiet", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    server = ThreadingHTTPServer((args.host, args.port), AuditSuiteHandler)
    server.quiet = args.quiet  # type: ignore[attr-defined]
    print(f"AUDIT-SUITE read-only API listening on http://{args.host}:{args.port}", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        return 130
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
