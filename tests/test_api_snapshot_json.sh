#!/usr/bin/env bash
# tests/test_api_snapshot_json.sh
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

tmp_history="$(mktemp -d)"
trap 'rm -rf "$tmp_history"' EXIT
export AUDIT_HISTORY_DIR="$tmp_history/history"
mkdir -p "$AUDIT_HISTORY_DIR"

cat >"$AUDIT_HISTORY_DIR/runs.jsonl" <<'JSONL'
{"run_id":"RUN_API_1","created_at":"2026-07-01T10:00:00Z"}
JSONL
cat >"$AUDIT_HISTORY_DIR/latest.json" <<'JSON'
{"run_id":"RUN_API_1","created_at":"2026-07-01T10:00:00Z"}
JSON

snapshot_json="$(bash bin/api_snapshot_json.sh)"

printf '%s\n' "$snapshot_json" | jq -e '.kind == "audit-suite.api_snapshot"' >/dev/null
printf '%s\n' "$snapshot_json" | jq -e '.schema_version == "1.0.0"' >/dev/null
printf '%s\n' "$snapshot_json" | jq -e '.generated_at | type == "string"' >/dev/null
printf '%s\n' "$snapshot_json" | jq -e '.status.kind == "audit-suite.status"' >/dev/null
printf '%s\n' "$snapshot_json" | jq -e '.modules.kind == "audit-suite.modules"' >/dev/null
printf '%s\n' "$snapshot_json" | jq -e '.history.kind == "audit-suite.history"' >/dev/null
printf '%s\n' "$snapshot_json" | jq -e '.latest.kind == "audit-suite.history.latest"' >/dev/null
printf '%s\n' "$snapshot_json" | jq -e '.history.count == 1' >/dev/null
printf '%s\n' "$snapshot_json" | jq -e '.latest.latest.run_id == "RUN_API_1"' >/dev/null
printf '%s\n' "$snapshot_json" | jq -e '.modules.count > 0' >/dev/null

if bash bin/api_snapshot_json.sh --unknown >/tmp/api-snapshot.out 2>/tmp/api-snapshot.err; then
  echo 'unknown option accepted' >&2
  exit 1
fi

grep -q 'Option inconnue' /tmp/api-snapshot.err
rm -f /tmp/api-snapshot.out /tmp/api-snapshot.err

printf '[OK] API snapshot JSON tests passed\n'
