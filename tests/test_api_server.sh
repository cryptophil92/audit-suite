#!/usr/bin/env bash
# tests/test_api_server.sh
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

PORT="${API_TEST_PORT:-9876}"
tmp_history="$(mktemp -d)"
server_log="$(mktemp)"
export AUDIT_HISTORY_DIR="$tmp_history/history"
mkdir -p "$AUDIT_HISTORY_DIR"

cleanup() {
  if [[ -n "${server_pid:-}" ]]; then
    kill "$server_pid" >/dev/null 2>&1 || true
    wait "$server_pid" >/dev/null 2>&1 || true
  fi
  rm -rf "$tmp_history" "$server_log"
}
trap cleanup EXIT

python3 api/server.py --host 127.0.0.1 --port "$PORT" --quiet >"$server_log" 2>&1 &
server_pid="$!"

python3 - <<'PY'
import os
import sys
import time
import urllib.request

port = os.environ.get("API_TEST_PORT", "9876")
url = f"http://127.0.0.1:{port}/api/health"
for _ in range(30):
    try:
        with urllib.request.urlopen(url, timeout=1) as response:
            if response.status == 200:
                sys.exit(0)
    except Exception:
        time.sleep(0.2)
sys.exit(1)
PY

python3 - <<'PY'
import json
import os
import urllib.error
import urllib.parse
import urllib.request

port = os.environ.get("API_TEST_PORT", "9876")
base = f"http://127.0.0.1:{port}"


def get_json(path):
    with urllib.request.urlopen(base + path, timeout=5) as response:
        assert response.status == 200
        return json.loads(response.read().decode("utf-8"))


def get_text(path):
    with urllib.request.urlopen(base + path, timeout=5) as response:
        assert response.status == 200
        content_type = response.headers.get("Content-Type", "")
        body = response.read().decode("utf-8")
        return content_type, body

content_type, body = get_text("/")
assert "text/html" in content_type
assert "AUDIT-SUITE" in body
assert "/api/snapshot" in body
assert "/api/plan" in body
assert "Aperçu de plan" in body
assert "WEB_PLAN_PREVIEW" in body
assert "plan-categories-mode" in body
assert "plan-module-selector" in body
assert "Modules sélectionnés" in body

content_type, body = get_text("/index.html")
assert "text/html" in content_type
assert "Interface locale" in body
assert "Afficher le plan JSON" in body
assert "name=\"plan-module\"" in body

openapi = get_json("/api/openapi.json")
assert openapi["openapi"] == "3.0.3"
assert "/api/plan" in openapi["paths"]
assert "/api/snapshot" in openapi["paths"]

assert get_json("/api/health")["kind"] == "audit-suite.api_health"
assert get_json("/api/status")["kind"] == "audit-suite.status"
assert get_json("/api/modules")["kind"] == "audit-suite.modules"
assert get_json("/api/history")["kind"] == "audit-suite.history"
assert get_json("/api/latest")["kind"] == "audit-suite.history.latest"
assert get_json("/api/snapshot")["kind"] == "audit-suite.api_snapshot"

query = urllib.parse.urlencode({
    "targets": "192.168.1.0/24",
    "profile": "fast",
    "categories": "all",
    "run_id": "API_PLAN_TEST",
    "no_zeek": "1",
    "no_suricata": "1",
})
plan = get_json(f"/api/plan?{query}")
assert plan["kind"] == "audit-suite.plan"
assert plan["run_id"] == "API_PLAN_TEST"
assert plan["profile"] == "fast"
assert plan["targets"] == ["192.168.1.0/24"]
assert plan["options"]["no_zeek"] is True
assert plan["options"]["no_suricata"] is True

try:
    urllib.request.urlopen(base + "/api/plan", timeout=5)
    raise AssertionError("plan without targets accepted")
except urllib.error.HTTPError as exc:
    assert exc.code == 400

try:
    urllib.request.urlopen(base + "/api/missing", timeout=5)
    raise AssertionError("missing route accepted")
except urllib.error.HTTPError as exc:
    assert exc.code == 404

request = urllib.request.Request(base + "/api/status", method="POST")
try:
    urllib.request.urlopen(request, timeout=5)
    raise AssertionError("POST accepted")
except urllib.error.HTTPError as exc:
    assert exc.code == 405
PY

printf '[OK] API server tests passed\n'
