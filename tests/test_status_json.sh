#!/usr/bin/env bash
# tests/test_status_json.sh
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

tmp_history="$(mktemp -d)"
trap 'rm -rf "$tmp_history"' EXIT
export AUDIT_HISTORY_DIR="$tmp_history/history"

mkdir -p "$AUDIT_HISTORY_DIR"
cat >"$AUDIT_HISTORY_DIR/runs.jsonl" <<'JSONL'
{"run_id":"RUN_STATUS_1"}
{"run_id":"RUN_STATUS_2"}
JSONL
cat >"$AUDIT_HISTORY_DIR/latest.json" <<'JSON'
{"run_id":"RUN_STATUS_2"}
JSON

status_json="$(bash bin/status_json.sh)"

printf '%s\n' "$status_json" | jq -e '.kind == "audit-suite.status"' >/dev/null
printf '%s\n' "$status_json" | jq -e '.schema_version == "1.0.0"' >/dev/null
printf '%s\n' "$status_json" | jq -e '.cwd | type == "string"' >/dev/null
printf '%s\n' "$status_json" | jq -e '.checks.modules_dir_exists == true' >/dev/null
printf '%s\n' "$status_json" | jq -e '.checks.history_index_exists == true' >/dev/null
printf '%s\n' "$status_json" | jq -e '.checks.latest_exists == true' >/dev/null
printf '%s\n' "$status_json" | jq -e '.counts.modules > 0' >/dev/null
printf '%s\n' "$status_json" | jq -e '.counts.history_runs == 2' >/dev/null
printf '%s\n' "$status_json" | jq -e '.paths.history | endswith("history")' >/dev/null
printf '%s\n' "$status_json" | jq -e '.dependencies.required | type == "array"' >/dev/null
printf '%s\n' "$status_json" | jq -e '.dependencies.optional | type == "array"' >/dev/null
printf '%s\n' "$status_json" | jq -e 'all(.dependencies.required[]; (.name | type == "string") and (.available | type == "boolean"))' >/dev/null
printf '%s\n' "$status_json" | jq -e 'all(.dependencies.optional[]; (.name | type == "string") and (.available | type == "boolean"))' >/dev/null

if bash bin/status_json.sh --unknown >/tmp/status-json.out 2>/tmp/status-json.err; then
  echo 'unknown option accepted' >&2
  exit 1
fi

grep -q 'Option inconnue' /tmp/status-json.err
rm -f /tmp/status-json.out /tmp/status-json.err

printf '[OK] status JSON tests passed\n'
