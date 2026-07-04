#!/usr/bin/env bash
# tests/test_report_html.sh
# Tests pour core/lib_report_html.sh et bin/report_html.sh
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

# shellcheck source=../core/lib_report_html.sh
source "core/lib_report_html.sh"

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

manifest_path="$TMP_ROOT/manifest.json"
report_path="$TMP_ROOT/report.html"
default_report_path="$TMP_ROOT/default/report.html"
mkdir -p "$TMP_ROOT/default"

cat > "$manifest_path" <<'JSON'
{
  "schema_version": "1.0.0",
  "kind": "audit-suite.manifest",
  "run_id": "AUDIT_HTML_TEST",
  "created_at": "2026-07-01T00:00:00+00:00",
  "profile": "fast",
  "targets": ["192.168.1.0/24"],
  "options": {
    "no_udp": false,
    "no_zeek": true,
    "no_suricata": true,
    "allow_public": false
  },
  "paths": {
    "output": "output/AUDIT_HTML_TEST",
    "logs": "logs/AUDIT_HTML_TEST",
    "manifest": "output/AUDIT_HTML_TEST/manifest.json"
  },
  "summary": {
    "module_count": 2,
    "success_count": 1,
    "failed_count": 1,
    "skipped_count": 0,
    "total_duration_seconds": 7,
    "status": "failed"
  },
  "modules": [
    {
      "id": "10_network_discovery",
      "name": "Découverte réseau",
      "path": "modules/10_network_discovery.sh",
      "status": "success",
      "rc": 0,
      "duration_seconds": 2,
      "output_path": "output/AUDIT_HTML_TEST/10_network_discovery",
      "reason": ""
    },
    {
      "id": "xss_test",
      "name": "<script>alert('x')</script>",
      "path": "modules/xss_test.sh",
      "status": "failed",
      "rc": 1,
      "duration_seconds": 5,
      "output_path": "output/AUDIT_HTML_TEST/xss_test",
      "reason": "module returned rc=1 <unsafe>"
    }
  ]
}
JSON

report_html_generate "$manifest_path" "$report_path" >/dev/null

[[ -f "$report_path" ]]
grep -q '<!doctype html>' "$report_path"
grep -q 'Rapport AUDIT-SUITE' "$report_path"
grep -q 'AUDIT_HTML_TEST' "$report_path"
grep -q 'status-failed' "$report_path"
grep -q 'xss_test' "$report_path"
grep -q '&lt;script&gt;alert' "$report_path"
grep -q 'module returned rc=1 &lt;unsafe&gt;' "$report_path"
if grep -q '<script>alert' "$report_path"; then
  echo 'Raw script tag found in generated report' >&2
  exit 1
fi

cp "$manifest_path" "$TMP_ROOT/default/manifest.json"
bash bin/report_html.sh "$TMP_ROOT/default/manifest.json" >/dev/null
[[ -f "$default_report_path" ]]

bash bin/report_html.sh "$manifest_path" "$TMP_ROOT/cli-report.html" >/dev/null
[[ -f "$TMP_ROOT/cli-report.html" ]]

printf '[OK] HTML report tests passed\n'
