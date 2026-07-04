#!/usr/bin/env bash
# tests/test_report_pipeline.sh
# Tests pour bin/finalize_reports.sh
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

run_id="AUDIT_PIPELINE_TEST"
run_dir="$TMP_ROOT/output/$run_id"
logs_dir="$TMP_ROOT/logs/$run_id"
manifest_path="$run_dir/manifest.json"

mkdir -p "$run_dir/module_a" "$logs_dir"
printf 'module output\n' > "$run_dir/module_a/result.txt"
printf 'combined log\n' > "$logs_dir/combined.log"

cat > "$manifest_path" <<JSON
{
  "schema_version": "1.0.0",
  "kind": "audit-suite.manifest",
  "run_id": "$run_id",
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
    "output": "$run_dir",
    "logs": "$logs_dir",
    "manifest": "$manifest_path"
  },
  "summary": {
    "module_count": 1,
    "success_count": 1,
    "failed_count": 0,
    "skipped_count": 0,
    "total_duration_seconds": 1,
    "status": "success"
  },
  "modules": [
    {
      "id": "module_a",
      "name": "Module A",
      "path": "modules/module_a.sh",
      "status": "success",
      "rc": 0,
      "duration_seconds": 1,
      "output_path": "$run_dir/module_a",
      "reason": ""
    }
  ]
}
JSON

pipeline_output="$(bash bin/finalize_reports.sh "$manifest_path")"

printf '%s\n' "$pipeline_output" | grep -q '^HTML_REPORT='
printf '%s\n' "$pipeline_output" | grep -q '^REPORT_PACK='

[[ -f "$run_dir/report.html" ]]
[[ -f "$run_dir/${run_id}_report_pack.tar.gz" ]]

tar -tzf "$run_dir/${run_id}_report_pack.tar.gz" > "$TMP_ROOT/list.txt"
grep -q "AUDIT_SUITE_REPORT_PACK_${run_id}/manifest.json" "$TMP_ROOT/list.txt"
grep -q "AUDIT_SUITE_REPORT_PACK_${run_id}/report.html" "$TMP_ROOT/list.txt"
grep -q "AUDIT_SUITE_REPORT_PACK_${run_id}/logs/combined.log" "$TMP_ROOT/list.txt"
grep -q "AUDIT_SUITE_REPORT_PACK_${run_id}/results/module_a/result.txt" "$TMP_ROOT/list.txt"

printf '[OK] report pipeline tests passed\n'
