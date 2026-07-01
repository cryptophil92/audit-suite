#!/usr/bin/env bash
# tests/test_report_pack.sh
# Tests pour core/lib_report_pack.sh et bin/report_pack.sh
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

# shellcheck source=../core/lib_report_pack.sh
source "core/lib_report_pack.sh"

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

run_id="AUDIT_PACK_TEST"
run_dir="$TMP_ROOT/output/$run_id"
logs_dir="$TMP_ROOT/logs/$run_id"
manifest_path="$run_dir/manifest.json"
report_path="$run_dir/report.html"
pack_path="$run_dir/${run_id}_report_pack.tar.gz"
extract_dir="$TMP_ROOT/extract"

mkdir -p "$run_dir/module_a" "$run_dir/module_b" "$logs_dir" "$extract_dir"

cat > "$manifest_path" <<JSON
{
  "schema_version": "1.0.0",
  "kind": "audit-suite.manifest",
  "run_id": "$run_id",
  "created_at": "2026-07-01T00:00:00+00:00",
  "profile": "fast",
  "targets": ["192.168.1.0/24"],
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
  "modules": []
}
JSON

cat > "$report_path" <<'HTML'
<!doctype html>
<html><body>Report</body></html>
HTML

printf 'module output A\n' > "$run_dir/module_a/result.txt"
printf 'module output B\n' > "$run_dir/module_b/result.txt"
printf 'combined log\n' > "$logs_dir/combined.log"
printf 'should be excluded\n' > "$run_dir/old_report_pack.tar.gz"
mkdir -p "$run_dir/tmp" "$run_dir/temp"
printf 'tmp file\n' > "$run_dir/tmp/file.txt"
printf 'temp file\n' > "$run_dir/temp/file.txt"

report_pack_build "$manifest_path" "$pack_path" >/dev/null

[[ -f "$pack_path" ]]
tar -tzf "$pack_path" > "$TMP_ROOT/list.txt"

grep -q "AUDIT_SUITE_REPORT_PACK_${run_id}/manifest.json" "$TMP_ROOT/list.txt"
grep -q "AUDIT_SUITE_REPORT_PACK_${run_id}/report.html" "$TMP_ROOT/list.txt"
grep -q "AUDIT_SUITE_REPORT_PACK_${run_id}/README.txt" "$TMP_ROOT/list.txt"
grep -q "AUDIT_SUITE_REPORT_PACK_${run_id}/PACK_CONTENTS.txt" "$TMP_ROOT/list.txt"
grep -q "AUDIT_SUITE_REPORT_PACK_${run_id}/logs/combined.log" "$TMP_ROOT/list.txt"
grep -q "AUDIT_SUITE_REPORT_PACK_${run_id}/results/module_a/result.txt" "$TMP_ROOT/list.txt"
grep -q "AUDIT_SUITE_REPORT_PACK_${run_id}/results/module_b/result.txt" "$TMP_ROOT/list.txt"

if grep -q 'tmp/file.txt' "$TMP_ROOT/list.txt"; then
  echo 'tmp directory leaked into report pack' >&2
  exit 1
fi

if grep -q 'temp/file.txt' "$TMP_ROOT/list.txt"; then
  echo 'temp directory leaked into report pack' >&2
  exit 1
fi

if grep -q 'old_report_pack.tar.gz' "$TMP_ROOT/list.txt"; then
  echo 'old report pack leaked into report pack' >&2
  exit 1
fi

tar -xzf "$pack_path" -C "$extract_dir"
[[ -f "$extract_dir/AUDIT_SUITE_REPORT_PACK_${run_id}/manifest.json" ]]
[[ -f "$extract_dir/AUDIT_SUITE_REPORT_PACK_${run_id}/PACK_CONTENTS.txt" ]]

bash bin/report_pack.sh "$manifest_path" "$run_dir/cli_pack.tar.gz" >/dev/null
[[ -f "$run_dir/cli_pack.tar.gz" ]]

printf '[OK] report pack tests passed\n'
