#!/usr/bin/env bash
# tests/test_api_server.sh
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

PORT="${API_TEST_PORT:-9876}"
PYTHON_COMMAND="${AUDIT_SUITE_PYTHON:-python3}"
if ! command -v "$PYTHON_COMMAND" >/dev/null 2>&1; then
  printf '[FAIL] Python 3 is required for the API server test\n' >&2
  exit 127
fi
tmp_history="$(mktemp -d)"
server_log="$(mktemp)"
export AUDIT_HISTORY_DIR="$tmp_history/history"
export API_TEST_RUN_ID="API_RESULTS_$$"
run_output="$REPO_DIR/output/$API_TEST_RUN_ID"
if [[ -e "$run_output" ]]; then
  printf '[FAIL] API result fixture path already exists: %s\n' "$run_output" >&2
  exit 1
fi

cleanup() {
  if [[ -n "${server_pid:-}" ]]; then
    kill "$server_pid" >/dev/null 2>&1 || true
    wait "$server_pid" >/dev/null 2>&1 || true
  fi
  rm -rf "$tmp_history" "$server_log"
  rm -rf -- "$run_output"
}
trap cleanup EXIT

mkdir -p "$AUDIT_HISTORY_DIR"
mkdir -p "$run_output"

cat >"$run_output/manifest.json" <<JSON
{
  "schema_version": "1.2.0",
  "kind": "audit-suite.manifest",
  "findings_schema_version": "1.0.0",
  "version": "0.2.34",
  "commit": "synthetic",
  "run_id": "$API_TEST_RUN_ID",
  "created_at": "2026-07-30T10:00:00Z",
  "profile": "fast",
  "targets": ["192.0.2.0/24"],
  "options": {
    "no_udp": false,
    "no_zeek": true,
    "no_suricata": true,
    "allow_public": false
  },
  "paths": {
    "output": "output/$API_TEST_RUN_ID",
    "logs": "logs/$API_TEST_RUN_ID",
    "manifest": "output/$API_TEST_RUN_ID/manifest.json"
  },
  "selected_modules": ["20_portscan_nmap.sh", "70_http_enum.sh"],
  "summary": {
    "module_count": 2,
    "success_count": 0,
    "partial_count": 1,
    "failed_count": 1,
    "skipped_count": 0,
    "total_duration_seconds": 4,
    "status": "failed",
    "findings": {
      "total_count": 1,
      "scored_count": 0,
      "unscored_count": 1
    }
  },
  "modules": [
    {
      "id": "20_portscan_nmap",
      "name": "Portscan Nmap",
      "status": "partial",
      "duration_seconds": 3,
      "reason": "fixture synthétique partielle"
    },
    {
      "id": "70_http_enum",
      "name": "HTTP enum",
      "status": "failed",
      "duration_seconds": 1,
      "reason": "fixture synthétique en échec"
    }
  ],
  "findings": [
    {
      "id": "finding.synthetic.http.001",
      "title": "Service HTTP synthétique observé",
      "severity": "informational",
      "validation_status": "observed",
      "observation": "Fixture locale sans scan réel.",
      "impact": "Inventaire uniquement.",
      "asset": {
        "id": "asset.synthetic.1",
        "address": "192.0.2.10",
        "hostname": "fixture.example.invalid"
      },
      "evidence": [
        {
          "source": "20_portscan_nmap",
          "path": "20_portscan_nmap/fixture.gnmap"
        }
      ],
      "remediation": {
        "action": "Confirmer le besoin du service."
      }
    }
  ]
}
JSON

cat >"$AUDIT_HISTORY_DIR/runs.jsonl" <<JSONL
{"run_id":"$API_TEST_RUN_ID","created_at":"2026-07-30T10:00:00Z","profile":"fast","targets":["192.0.2.0/24"],"status":"failed","module_count":2,"success_count":0,"partial_count":1,"failed_count":1,"skipped_count":0,"finding_count":1,"manifest_path":"output/$API_TEST_RUN_ID/manifest.json"}
JSONL
cp "$run_output/manifest.json" "$AUDIT_HISTORY_DIR/latest.json"
printf '<!doctype html><html lang="fr"><body>RAPPORT PRIVE SYNTHETIQUE</body></html>\n' >"$run_output/report.html"
printf '<!doctype html><html lang="fr"><body>RAPPORT PARTAGEABLE SYNTHETIQUE</body></html>\n' >"$run_output/report-shareable.html"

if "$PYTHON_COMMAND" api/server.py --host 0.0.0.0 --port "$PORT" --quiet >"$server_log" 2>&1; then
  echo 'non-loopback bind accepted' >&2
  exit 1
fi
grep -q 'non-loopback API binds are not supported' "$server_log"
if grep -q 'listening on' "$server_log"; then
  echo 'server started before rejecting non-loopback bind' >&2
  exit 1
fi

"$PYTHON_COMMAND" api/server.py --host 127.0.0.1 --port "$PORT" --quiet >"$server_log" 2>&1 &
server_pid="$!"

"$PYTHON_COMMAND" - <<'PY'
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

"$PYTHON_COMMAND" - <<'PY'
import json
import os
import time
import urllib.error
import urllib.parse
import urllib.request

port = os.environ.get("API_TEST_PORT", "9876")
base = f"http://127.0.0.1:{port}"


def get_json(path, timeout=5):
    with urllib.request.urlopen(base + path, timeout=timeout) as response:
        assert response.status == 200
        return json.loads(response.read().decode("utf-8"))


def get_text(path):
    with urllib.request.urlopen(base + path, timeout=5) as response:
        assert response.status == 200
        content_type = response.headers.get("Content-Type", "")
        csp = response.headers.get("Content-Security-Policy", "")
        body = response.read().decode("utf-8")
        assert response.headers.get("X-Content-Type-Options") == "nosniff"
        assert response.headers.get("X-Frame-Options") == "DENY"
        assert response.headers.get("Referrer-Policy") == "no-referrer"
        return content_type, csp, body

content_type, csp, body = get_text("/")
assert "text/html" in content_type
assert "default-src 'self'" in csp
assert "script-src 'self'" in csp
assert "style-src 'self'" in csp
assert "object-src 'none'" in csp
assert "frame-ancestors 'none'" in csp
assert "AUDIT-SUITE" in body
assert "Aperçu de plan" in body
assert "Historique et résultats" in body
assert "results-retry" in body
assert "history-list" in body
assert "run-detail" in body
assert "Prévisualiser les données sensibles" not in body
assert "Routes API locales" in body
assert "routes-table" in body
assert "WEB_PLAN_PREVIEW" in body
assert "plan-categories-mode" in body
assert "plan-module-selector" in body
assert "Modules sélectionnés" in body
assert '<link rel="stylesheet" href="/styles.css">' in body
assert '<script src="/app.js" defer></script>' in body
assert "<style" not in body
assert "style=" not in body

content_type, _, body = get_text("/index.html")
assert "text/html" in content_type
assert "Interface locale" in body
assert "Afficher le plan JSON" in body

content_type, _, app = get_text("/app.js")
assert "text/javascript" in content_type
assert "/api/snapshot" in app
assert "/api/run" in app
assert "/api/report" in app
assert "/api/plan" in app
assert "/api/routes" in app
assert 'checkbox.name = "plan-module"' in app
assert "renderRoutes" in app
assert "renderRunDetail" in app
assert "safeLocalReportUrl" in app
assert "textContent" in app

content_type, _, styles = get_text("/styles.css")
assert "text/css" in content_type
assert ".module-selector" in styles
assert ".section-spaced" in styles
assert ".results-layout" in styles
assert ".history-item" in styles
assert ".sensitive-preview" in styles
assert ".report-link.is-disabled" in styles

openapi = get_json("/api/openapi.json")
assert openapi["openapi"] == "3.0.3"
assert openapi["info"]["version"]
assert openapi["info"]["x-audit-suite-commit"]
assert "/api/plan" in openapi["paths"]
assert "/api/snapshot" in openapi["paths"]
assert "/api/run" in openapi["paths"]
assert "/api/report" in openapi["paths"]
assert "502" in openapi["paths"]["/api/snapshot"]["get"]["responses"]
assert "504" in openapi["paths"]["/api/snapshot"]["get"]["responses"]

routes = get_json("/api/routes")
assert routes["kind"] == "audit-suite.api_routes"
assert routes["schema_version"] == "1.0.0"
route_paths = {item["path"] for item in routes["routes"]}
assert "/api/plan" in route_paths
assert "/api/run" in route_paths
assert "/api/report" in route_paths
assert "/api/openapi.json" in route_paths
assert "/api/routes" in route_paths
assert "/app.js" in route_paths
assert "/styles.css" in route_paths
snapshot_route = next(item for item in routes["routes"] if item["path"] == "/api/snapshot")
assert snapshot_route["timeout_seconds"] == 15
assert routes["limits"]["max_output_bytes"] == 1048576

health = get_json("/api/health")
assert health["kind"] == "audit-suite.api_health"
assert health["version"] == openapi["info"]["version"]
assert health["commit"] == openapi["info"]["x-audit-suite-commit"]
assert get_json("/api/status")["kind"] == "audit-suite.status"
assert get_json("/api/modules")["kind"] == "audit-suite.modules"
assert get_json("/api/history")["kind"] == "audit-suite.history"
assert get_json("/api/latest")["kind"] == "audit-suite.history.latest"
snapshot_started_at = time.monotonic()
assert get_json("/api/snapshot", timeout=16)["kind"] == "audit-suite.api_snapshot"
assert time.monotonic() - snapshot_started_at < 15

run_id = os.environ["API_TEST_RUN_ID"]
run_query = urllib.parse.urlencode({"run_id": run_id})
detail = get_json(f"/api/run?{run_query}")
assert detail["kind"] == "audit-suite.history.run"
assert detail["found"] is True
assert detail["detail_source"] == "manifest"
assert detail["run"]["run_id"] == run_id
assert detail["run"]["summary"]["status"] == "failed"
assert [module["status"] for module in detail["run"]["modules"]] == [
    "partial",
    "failed",
]
reports = {report["kind"]: report for report in detail["reports"]}
assert reports["private"]["available"] is True
assert reports["shareable"]["available"] is True
assert reports["technical"]["available"] is False
assert reports["private"]["url"].startswith("/api/report?")
assert detail["export_review"]["review_required"] is True
assert detail["export_review"]["targets"]["values"] == ["192.0.2.0/24"]
assert detail["export_review"]["asset_addresses"]["values"] == ["192.0.2.10"]
assert detail["export_review"]["hostnames"]["values"] == [
    "fixture.example.invalid"
]
assert detail["export_review"]["evidence_paths"]["values"] == [
    "20_portscan_nmap/fixture.gnmap"
]

report_query = urllib.parse.urlencode({"run_id": run_id, "kind": "private"})
with urllib.request.urlopen(base + f"/api/report?{report_query}", timeout=5) as response:
    assert response.status == 200
    assert "text/html" in response.headers.get("Content-Type", "")
    assert "report.html" in response.headers.get("Content-Disposition", "")
    report_csp = response.headers.get("Content-Security-Policy", "")
    assert "default-src 'none'" in report_csp
    assert "script-src 'none'" in report_csp
    assert "style-src 'unsafe-inline'" in report_csp
    assert "RAPPORT PRIVE SYNTHETIQUE" in response.read().decode("utf-8")

for path, expected_status in (
    ("/api/run?run_id=..", 400),
    (f"/api/report?{urllib.parse.urlencode({'run_id': run_id, 'kind': 'unknown'})}", 400),
    (f"/api/report?{urllib.parse.urlencode({'run_id': run_id, 'kind': 'technical'})}", 404),
):
    try:
        urllib.request.urlopen(base + path, timeout=5)
        raise AssertionError(f"unexpected success for {path}")
    except urllib.error.HTTPError as exc:
        assert exc.code == expected_status

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
