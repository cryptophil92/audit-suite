#!/usr/bin/env bash
# tests/test_history_json.sh
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

tmp_history="$(mktemp -d)"
trap 'rm -rf "$tmp_history"' EXIT
export AUDIT_HISTORY_DIR="$tmp_history/history"

empty_list="$(bash bin/history_json.sh list)"
printf '%s\n' "$empty_list" | jq -e '.kind == "audit-suite.history"' >/dev/null
printf '%s\n' "$empty_list" | jq -e '.schema_version == "1.0.0"' >/dev/null
printf '%s\n' "$empty_list" | jq -e '.count == 0' >/dev/null
printf '%s\n' "$empty_list" | jq -e '.runs == []' >/dev/null

empty_latest="$(bash bin/history_json.sh latest)"
printf '%s\n' "$empty_latest" | jq -e '.kind == "audit-suite.history.latest"' >/dev/null
printf '%s\n' "$empty_latest" | jq -e '.latest == null' >/dev/null

mkdir -p "$AUDIT_HISTORY_DIR"
cat >"$AUDIT_HISTORY_DIR/runs.jsonl" <<'JSONL'
{"run_id":"RUN_1","created_at":"2026-07-01T10:00:00Z","profile":"fast","targets":["192.168.1.0/24"],"status":"success"}
{"run_id":"RUN_2","created_at":"2026-07-01T11:00:00Z","profile":"full","targets":["192.168.1.0/24"],"status":"failed"}
JSONL

cat >"$AUDIT_HISTORY_DIR/latest.json" <<'JSON'
{"run_id":"RUN_2","created_at":"2026-07-01T11:00:00Z","profile":"full","summary":{"status":"failed"}}
JSON

list_json="$(bash bin/history_json.sh list)"
printf '%s\n' "$list_json" | jq -e '.count == 2' >/dev/null
printf '%s\n' "$list_json" | jq -e '.runs[0].run_id == "RUN_1"' >/dev/null
printf '%s\n' "$list_json" | jq -e '.runs[1].run_id == "RUN_2"' >/dev/null

latest_json="$(bash bin/history_json.sh latest)"
printf '%s\n' "$latest_json" | jq -e '.latest.run_id == "RUN_2"' >/dev/null
printf '%s\n' "$latest_json" | jq -e '.latest.summary.status == "failed"' >/dev/null

paths_json="$(bash bin/history_json.sh paths)"
printf '%s\n' "$paths_json" | jq -e '.kind == "audit-suite.history.paths"' >/dev/null
printf '%s\n' "$paths_json" | jq -e '.paths.index | endswith("runs.jsonl")' >/dev/null
printf '%s\n' "$paths_json" | jq -e '.paths.latest | endswith("latest.json")' >/dev/null

if bash bin/history_json.sh unknown >/tmp/history-json.out 2>/tmp/history-json.err; then
  echo 'unknown command accepted' >&2
  exit 1
fi

grep -q 'Commande inconnue' /tmp/history-json.err
rm -f /tmp/history-json.out /tmp/history-json.err

printf '[OK] history JSON tests passed\n'
