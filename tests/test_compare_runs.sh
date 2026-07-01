#!/usr/bin/env bash
# tests/test_compare_runs.sh
# Tests pour core/lib_compare.sh et bin/compare_runs.sh
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

# shellcheck source=../core/lib_compare.sh
source "core/lib_compare.sh"

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

before_manifest="$TMP_ROOT/before.json"
after_manifest="$TMP_ROOT/after.json"
compare_json="$TMP_ROOT/compare.json"

cat > "$before_manifest" <<'JSON'
{
  "schema_version": "1.0.0",
  "kind": "audit-suite.manifest",
  "run_id": "AUDIT_BEFORE",
  "created_at": "2026-07-01T00:00:00+00:00",
  "profile": "fast",
  "targets": ["192.168.1.0/24"],
  "summary": {
    "module_count": 3,
    "success_count": 2,
    "failed_count": 0,
    "skipped_count": 1,
    "total_duration_seconds": 12,
    "status": "success"
  },
  "modules": [
    {
      "id": "10_network_discovery",
      "name": "Découverte réseau",
      "path": "modules/10_network_discovery.sh",
      "status": "success",
      "rc": 0,
      "duration_seconds": 5,
      "reason": ""
    },
    {
      "id": "20_portscan_nmap",
      "name": "Portscan Nmap",
      "path": "modules/20_portscan_nmap.sh",
      "status": "success",
      "rc": 0,
      "duration_seconds": 7,
      "reason": ""
    },
    {
      "id": "70_http_enum",
      "name": "HTTP enum",
      "path": "modules/70_http_enum.sh",
      "status": "skipped",
      "rc": 127,
      "duration_seconds": 0,
      "reason": "missing dependency"
    }
  ]
}
JSON

cat > "$after_manifest" <<'JSON'
{
  "schema_version": "1.0.0",
  "kind": "audit-suite.manifest",
  "run_id": "AUDIT_AFTER",
  "created_at": "2026-07-01T01:00:00+00:00",
  "profile": "fast",
  "targets": ["192.168.1.0/24"],
  "summary": {
    "module_count": 3,
    "success_count": 2,
    "failed_count": 1,
    "skipped_count": 0,
    "total_duration_seconds": 17,
    "status": "failed"
  },
  "modules": [
    {
      "id": "10_network_discovery",
      "name": "Découverte réseau",
      "path": "modules/10_network_discovery.sh",
      "status": "success",
      "rc": 0,
      "duration_seconds": 6,
      "reason": ""
    },
    {
      "id": "20_portscan_nmap",
      "name": "Portscan Nmap",
      "path": "modules/20_portscan_nmap.sh",
      "status": "failed",
      "rc": 1,
      "duration_seconds": 8,
      "reason": "module returned rc=1"
    },
    {
      "id": "30_vuln_nmap_nse",
      "name": "Nmap NSE Vuln",
      "path": "modules/30_vuln_nmap_nse.sh",
      "status": "success",
      "rc": 0,
      "duration_seconds": 3,
      "reason": ""
    }
  ]
}
JSON

compare_runs_json "$before_manifest" "$after_manifest" > "$compare_json"

jq -e '.kind == "audit-suite.compare"' "$compare_json" >/dev/null
jq -e '.schema_version == "1.0.0"' "$compare_json" >/dev/null
jq -e '.before.run_id == "AUDIT_BEFORE"' "$compare_json" >/dev/null
jq -e '.after.run_id == "AUDIT_AFTER"' "$compare_json" >/dev/null
jq -e '.summary.total_modules_compared == 4' "$compare_json" >/dev/null
jq -e '.summary.added_count == 1' "$compare_json" >/dev/null
jq -e '.summary.removed_count == 1' "$compare_json" >/dev/null
jq -e '.summary.status_changed_count == 1' "$compare_json" >/dev/null
jq -e '.summary.unchanged_count == 1' "$compare_json" >/dev/null
jq -e '.summary.regression_count == 1' "$compare_json" >/dev/null
jq -e '.summary.improvement_count == 0' "$compare_json" >/dev/null
jq -e '.modules[] | select(.id == "30_vuln_nmap_nse" and .change == "added")' "$compare_json" >/dev/null
jq -e '.modules[] | select(.id == "70_http_enum" and .change == "removed")' "$compare_json" >/dev/null
jq -e '.modules[] | select(.id == "20_portscan_nmap" and .change == "status_changed")' "$compare_json" >/dev/null

bash bin/compare_runs.sh --json "$before_manifest" "$after_manifest" | jq -e '.summary.regression_count == 1' >/dev/null
bash bin/compare_runs.sh "$before_manifest" "$after_manifest" | grep -q 'status_changed'

printf '[OK] compare runs tests passed\n'
