#!/usr/bin/env python3
"""Local read-only API server for AUDIT-SUITE."""
from __future__ import annotations

import argparse
import ipaddress
import json
import logging
import math
import os
import signal
import socket
import subprocess
import threading
import time
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any
from urllib.parse import parse_qs, urlparse

from version import APP_COMMIT, APP_VERSION

REPO_DIR = Path(__file__).resolve().parent.parent
WEB_DIR = REPO_DIR / "web"
WEB_ASSETS = {
    "/": (WEB_DIR / "index.html", "text/html; charset=utf-8"),
    "/index.html": (WEB_DIR / "index.html", "text/html; charset=utf-8"),
    "/app.js": (WEB_DIR / "app.js", "text/javascript; charset=utf-8"),
    "/styles.css": (WEB_DIR / "styles.css", "text/css; charset=utf-8"),
}
OPENAPI_SPEC = REPO_DIR / "api" / "openapi.json"
DEFAULT_MAX_OUTPUT_BYTES = 1024 * 1024
CONTENT_SECURITY_POLICY = (
    "default-src 'self'; "
    "base-uri 'none'; "
    "connect-src 'self'; "
    "form-action 'self'; "
    "frame-ancestors 'none'; "
    "img-src 'self' data:; "
    "object-src 'none'; "
    "script-src 'self'; "
    "style-src 'self'"
)
ROUTE_TIMEOUT_SECONDS = {
    "/api/status": 10.0,
    "/api/modules": 10.0,
    "/api/history": 10.0,
    "/api/history/paths": 10.0,
    "/api/latest": 10.0,
    "/api/snapshot": 15.0,
    "/api/plan": 10.0,
}
LOGGER = logging.getLogger("audit_suite.api")

ROUTES: dict[str, list[str]] = {
    "/api/status": ["bash", "bin/status_json.sh"],
    "/api/modules": ["bash", "bin/modules_json.sh"],
    "/api/history": ["bash", "bin/history_json.sh", "list"],
    "/api/history/paths": ["bash", "bin/history_json.sh", "paths"],
    "/api/latest": ["bash", "bin/history_json.sh", "latest"],
    "/api/snapshot": ["bash", "bin/api_snapshot_json.sh"],
}


def api_routes_payload(
    timeout_override: float | None = None,
    max_output_bytes: int = DEFAULT_MAX_OUTPUT_BYTES,
) -> dict[str, Any]:
    payload: dict[str, Any] = {
        "kind": "audit-suite.api_routes",
        "schema_version": "1.0.0",
        "limits": {
            "max_output_bytes": max_output_bytes,
            "timeout_override_seconds": timeout_override,
        },
        "routes": [
            {"method": "GET", "path": "/", "type": "html"},
            {"method": "GET", "path": "/index.html", "type": "html"},
            {"method": "GET", "path": "/app.js", "type": "javascript"},
            {"method": "GET", "path": "/styles.css", "type": "css"},
            {"method": "GET", "path": "/api/health", "type": "json"},
            {"method": "GET", "path": "/api/status", "type": "json"},
            {"method": "GET", "path": "/api/modules", "type": "json"},
            {"method": "GET", "path": "/api/history", "type": "json"},
            {"method": "GET", "path": "/api/history/paths", "type": "json"},
            {"method": "GET", "path": "/api/latest", "type": "json"},
            {"method": "GET", "path": "/api/snapshot", "type": "json"},
            {
                "method": "GET",
                "path": "/api/plan",
                "type": "json",
                "requires_query": ["targets"],
            },
            {"method": "GET", "path": "/api/openapi.json", "type": "json"},
            {"method": "GET", "path": "/api/routes", "type": "json"},
        ],
    }
    for route in payload["routes"]:
        path = route["path"]
        if path in ROUTE_TIMEOUT_SECONDS:
            route["timeout_seconds"] = timeout_override or ROUTE_TIMEOUT_SECONDS[path]
    return payload


def terminate_process(process: subprocess.Popen[bytes]) -> None:
    if process.poll() is not None:
        return

    try:
        if os.name == "posix":
            os.killpg(process.pid, signal.SIGKILL)
        elif os.name == "nt":
            result = subprocess.run(
                ["taskkill", "/PID", str(process.pid), "/T", "/F"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                check=False,
                timeout=1,
            )
            if result.returncode != 0:
                process.kill()
        else:
            process.kill()
    except (OSError, subprocess.SubprocessError):
        try:
            process.kill()
        except OSError:
            pass


def read_bounded_stream(
    stream: Any,
    chunks: list[bytes],
    state: dict[str, int],
    state_lock: threading.Lock,
    limit_exceeded: threading.Event,
    process: subprocess.Popen[bytes],
    max_output_bytes: int,
) -> None:
    try:
        while True:
            chunk = stream.read(65536)
            if not chunk:
                break

            with state_lock:
                remaining = max(0, max_output_bytes - state["captured_bytes"])
                if remaining:
                    captured = chunk[:remaining]
                    chunks.append(captured)
                    state["captured_bytes"] += len(captured)
                state["observed_bytes"] += len(chunk)
                exceeded = state["observed_bytes"] > max_output_bytes

                should_terminate = exceeded and not limit_exceeded.is_set()
                if should_terminate:
                    limit_exceeded.set()

            if should_terminate:
                terminate_process(process)
                break
    except (OSError, ValueError):
        return
    finally:
        stream.close()


def run_json_command(
    command: list[str],
    *,
    timeout_seconds: float = 10.0,
    max_output_bytes: int = DEFAULT_MAX_OUTPUT_BYTES,
) -> tuple[int, dict[str, Any]]:
    env = os.environ.copy()
    started_at = time.monotonic()
    popen_options: dict[str, Any] = {}
    if os.name == "posix":
        popen_options["start_new_session"] = True
    elif os.name == "nt":
        popen_options["creationflags"] = subprocess.CREATE_NEW_PROCESS_GROUP

    try:
        process = subprocess.Popen(
            command,
            cwd=REPO_DIR,
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            **popen_options,
        )
    except OSError as exc:
        LOGGER.error("JSON command failed to start: command=%r error=%s", command, exc)
        return 127, {
            "kind": "audit-suite.api_error",
            "error": "command_start_failed",
            "returncode": 127,
            "duration_ms": round((time.monotonic() - started_at) * 1000),
        }

    assert process.stdout is not None
    assert process.stderr is not None
    stdout_chunks: list[bytes] = []
    stderr_chunks: list[bytes] = []
    state = {"captured_bytes": 0, "observed_bytes": 0}
    state_lock = threading.Lock()
    limit_exceeded = threading.Event()
    readers = [
        threading.Thread(
            target=read_bounded_stream,
            args=(
                process.stdout,
                stdout_chunks,
                state,
                state_lock,
                limit_exceeded,
                process,
                max_output_bytes,
            ),
            daemon=True,
        ),
        threading.Thread(
            target=read_bounded_stream,
            args=(
                process.stderr,
                stderr_chunks,
                state,
                state_lock,
                limit_exceeded,
                process,
                max_output_bytes,
            ),
            daemon=True,
        ),
    ]
    for reader in readers:
        reader.start()

    timed_out = False
    try:
        process.wait(timeout=timeout_seconds)
    except subprocess.TimeoutExpired:
        timed_out = True
        terminate_process(process)
        try:
            process.wait(timeout=1)
        except subprocess.TimeoutExpired:
            process.kill()
            try:
                process.wait(timeout=1)
            except subprocess.TimeoutExpired:
                pass

    for reader in readers:
        reader.join(timeout=1)
    for stream in (process.stdout, process.stderr):
        if not stream.closed:
            stream.close()

    duration_ms = round((time.monotonic() - started_at) * 1000)
    stdout = b"".join(stdout_chunks).decode("utf-8", errors="replace")
    stderr = b"".join(stderr_chunks).decode("utf-8", errors="replace")

    if timed_out:
        LOGGER.error(
            "JSON command timed out: command=%r timeout_seconds=%s",
            command,
            timeout_seconds,
        )
        return 124, {
            "kind": "audit-suite.api_error",
            "error": "command_timeout",
            "returncode": 124,
            "timeout_seconds": timeout_seconds,
            "duration_ms": duration_ms,
        }

    if limit_exceeded.is_set():
        LOGGER.error(
            "JSON command output limit exceeded: command=%r max_output_bytes=%d",
            command,
            max_output_bytes,
        )
        return 125, {
            "kind": "audit-suite.api_error",
            "error": "output_limit_exceeded",
            "returncode": 125,
            "max_output_bytes": max_output_bytes,
            "duration_ms": duration_ms,
        }

    if process.returncode != 0:
        LOGGER.error(
            "JSON command failed: command=%r returncode=%d stderr=%s",
            command,
            process.returncode,
            stderr.strip(),
        )
        return process.returncode, {
            "kind": "audit-suite.api_error",
            "error": "command_failed",
            "returncode": process.returncode,
            "duration_ms": duration_ms,
        }

    try:
        return 0, json.loads(stdout)
    except json.JSONDecodeError as exc:
        LOGGER.error("JSON command returned invalid JSON: command=%r error=%s", command, exc)
        return 1, {
            "kind": "audit-suite.api_error",
            "error": "invalid_command_output",
            "returncode": 1,
            "duration_ms": duration_ms,
        }


def command_error_status(
    payload: dict[str, Any], fallback: HTTPStatus
) -> HTTPStatus:
    if payload.get("error") == "command_timeout":
        return HTTPStatus.GATEWAY_TIMEOUT
    if payload.get("error") == "output_limit_exceeded":
        return HTTPStatus.BAD_GATEWAY
    return fallback


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
    server_version = f"AuditSuiteReadOnlyAPI/{APP_VERSION}"

    def log_message(self, format: str, *args: Any) -> None:  # noqa: A002
        if getattr(self.server, "quiet", False):
            return
        super().log_message(format, *args)

    def _write_security_headers(self) -> None:
        self.send_header("Content-Security-Policy", CONTENT_SECURITY_POLICY)
        self.send_header("Cross-Origin-Resource-Policy", "same-origin")
        self.send_header("Referrer-Policy", "no-referrer")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("X-Frame-Options", "DENY")

    def _write_json(self, status: HTTPStatus, payload: dict[str, Any]) -> None:
        body = json.dumps(payload, ensure_ascii=False, indent=2).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self._write_security_headers()
        self.end_headers()
        self.wfile.write(body)

    def _command_limits(self, path: str) -> tuple[float, int]:
        timeout_override = getattr(self.server, "command_timeout", None)
        timeout_seconds = timeout_override or ROUTE_TIMEOUT_SECONDS[path]
        max_output_bytes = getattr(
            self.server, "max_output_bytes", DEFAULT_MAX_OUTPUT_BYTES
        )
        return timeout_seconds, max_output_bytes

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
        self._write_security_headers()
        self.end_headers()
        self.wfile.write(body)

    def _write_openapi(self) -> None:
        if not OPENAPI_SPEC.is_file():
            LOGGER.error("OpenAPI document is missing: path=%s", OPENAPI_SPEC)
            self._write_json(
                HTTPStatus.NOT_FOUND,
                {
                    "kind": "audit-suite.api_error",
                    "error": "json_file_missing",
                },
            )
            return

        try:
            payload = json.loads(OPENAPI_SPEC.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            LOGGER.error(
                "OpenAPI document could not be loaded: path=%s error=%s",
                OPENAPI_SPEC,
                exc,
            )
            self._write_json(
                HTTPStatus.INTERNAL_SERVER_ERROR,
                {
                    "kind": "audit-suite.api_error",
                    "error": "invalid_openapi_document",
                },
            )
            return

        payload.setdefault("info", {})["version"] = APP_VERSION
        payload["info"]["x-audit-suite-commit"] = APP_COMMIT
        self._write_json(HTTPStatus.OK, payload)

    def _write_static(
        self, status: HTTPStatus, asset_path: Path, content_type: str
    ) -> None:
        if not asset_path.is_file():
            self._write_json(
                HTTPStatus.NOT_FOUND,
                {
                    "kind": "audit-suite.api_error",
                    "error": "web_asset_missing",
                },
            )
            return
        body = asset_path.read_bytes()
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self._write_security_headers()
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self) -> None:  # noqa: N802
        parsed_url = urlparse(self.path)
        path = parsed_url.path

        asset = WEB_ASSETS.get(path)
        if asset is not None:
            asset_path, content_type = asset
            self._write_static(HTTPStatus.OK, asset_path, content_type)
            return

        if path == "/api/routes":
            self._write_json(
                HTTPStatus.OK,
                api_routes_payload(
                    getattr(self.server, "command_timeout", None),
                    getattr(
                        self.server, "max_output_bytes", DEFAULT_MAX_OUTPUT_BYTES
                    ),
                ),
            )
            return

        if path == "/api/openapi.json":
            self._write_openapi()
            return

        if path == "/api/health":
            self._write_json(
                HTTPStatus.OK,
                {
                    "kind": "audit-suite.api_health",
                    "status": "ok",
                    "read_only": True,
                    "version": APP_VERSION,
                    "commit": APP_COMMIT,
                },
            )
            return

        if path == "/api/plan":
            command, error_payload = build_plan_command(parse_qs(parsed_url.query))
            if error_payload is not None or command is None:
                self._write_json(HTTPStatus.BAD_REQUEST, error_payload or {})
                return
            timeout_seconds, max_output_bytes = self._command_limits(path)
            returncode, payload = run_json_command(
                command,
                timeout_seconds=timeout_seconds,
                max_output_bytes=max_output_bytes,
            )
            if returncode == 0:
                self._write_json(HTTPStatus.OK, payload)
            else:
                self._write_json(
                    command_error_status(payload, HTTPStatus.BAD_REQUEST), payload
                )
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

        timeout_seconds, max_output_bytes = self._command_limits(path)
        returncode, payload = run_json_command(
            command,
            timeout_seconds=timeout_seconds,
            max_output_bytes=max_output_bytes,
        )
        if returncode == 0:
            self._write_json(HTTPStatus.OK, payload)
        else:
            self._write_json(
                command_error_status(payload, HTTPStatus.INTERNAL_SERVER_ERROR),
                payload,
            )

    def do_POST(self) -> None:  # noqa: N802
        self._write_json(
            HTTPStatus.METHOD_NOT_ALLOWED,
            {
                "kind": "audit-suite.api_error",
                "error": "read_only",
                "method": "POST",
            },
        )


def positive_float(value: str) -> float:
    parsed = float(value)
    if not math.isfinite(parsed) or parsed <= 0:
        raise argparse.ArgumentTypeError("value must be greater than zero")
    return parsed


def positive_int(value: str) -> int:
    parsed = int(value)
    if parsed <= 0:
        raise argparse.ArgumentTypeError("value must be greater than zero")
    return parsed


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
    parser.add_argument(
        "--command-timeout",
        type=positive_float,
        default=None,
        help="override every dynamic route timeout in seconds",
    )
    parser.add_argument(
        "--max-output-bytes",
        type=positive_int,
        default=DEFAULT_MAX_OUTPUT_BYTES,
        help="combined stdout/stderr limit per command",
    )
    parser.add_argument("--quiet", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    server = create_server(args.host, args.port)
    server.quiet = args.quiet  # type: ignore[attr-defined]
    server.command_timeout = args.command_timeout  # type: ignore[attr-defined]
    server.max_output_bytes = args.max_output_bytes  # type: ignore[attr-defined]
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
