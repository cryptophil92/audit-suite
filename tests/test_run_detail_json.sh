#!/usr/bin/env bash
# tests/test_run_detail_json.sh
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

tmp_history="$(mktemp -d)"
trap 'rm -rf "$tmp_history"' EXIT
export AUDIT_HISTORY_DIR="$tmp_history/history"

empty_run="$(bash bin/history_json.sh run RUN_NONE)"
printf '%s\n' "$empty_run" | jq -e '.kind == "audit-suite.history.run"' >/dev/null
printf '%s\n' "$empty_run" | jq -e '.schema_version == "1.0.0"' >/dev/null
printf '%s\n' "$empty_run" | jq -e '.found == false' >/dev/null
printf '%s\n' "$empty_run" | jq -e '.run == null' >/dev/null

missing_id="$(bash bin/history_json.sh run)"
printf '%s\n' "$missing_id" | jq -e '.error == "missing_run_id"' >/dev/null

invalid_id="$(bash bin/history_json.sh run '../bad')"
printf '%s\n' "$invalid_id" | jq -e '.error == "invalid_run_id"' >/dev/null

mkdir -p "$AUDIT_HISTORY_DIR"
cat >"$AUDIT_HISTORY_DIR/runs.jsonl" <<'JSONL'
{"run_id":"RUN_1","created_at":"2026-07-01T10:00:00Z","profile":"fast","targets":["192.168.1.0/24"],"status":"success","manifest_path":"output/RUN_1/manifest.json"}
{"run_id":"RUN_2","created_at":"2026-07-01T11:00:00Z","profile":"full","targets":["192.168.1.0/24"],"status":"failed","manifest_path":"output/RUN_2/manifest.json"}
JSONL

run_json="$(bash bin/history_json.sh run RUN_2)"
printf '%s\n' "$run_json" | jq -e '.found == true' >/dev/null
printf '%s\n' "$run_json" | jq -e '.run_id == "RUN_2"' >/dev/null
printf '%s\n' "$run_json" | jq -e '.run.profile == "full"' >/dev/null
printf '%s\n' "$run_json" | jq -e '.run.status == "failed"' >/dev/null
printf '%s\n' "$run_json" | jq -e '.paths.index | endswith("runs.jsonl")' >/dev/null

printf '[OK] run detail JSON tests passed\n'
