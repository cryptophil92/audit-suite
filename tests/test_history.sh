#!/usr/bin/env bash
# tests/test_history.sh
# Tests simples pour core/lib_history.sh
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

# shellcheck source=../core/lib_logging.sh
source "core/lib_logging.sh"
# shellcheck source=../core/lib_history.sh
source "core/lib_history.sh"

export AUDIT_HISTORY_DIR
AUDIT_HISTORY_DIR="$(mktemp -d)"
trap 'rm -rf "$AUDIT_HISTORY_DIR"' EXIT

RUN_ID="AUDIT_TEST_001"
LOG_DIR="$AUDIT_HISTORY_DIR/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/test.log"
LOG_BUS=""
export RUN_ID LOG_DIR LOG_FILE LOG_BUS

manifest_path="$AUDIT_HISTORY_DIR/manifest.json"
cat > "$manifest_path" <<'JSON'
{
  "run_id": "AUDIT_TEST_001",
  "created_at": "2026-07-01T00:00:00+00:00",
  "profile": "fast",
  "targets": ["192.168.1.0/24"],
  "options": {
    "no_udp": false,
    "no_zeek": true,
    "no_suricata": true,
    "allow_public": false
  },
  "selected_modules": ["modules/10_network_discovery.sh"],
  "modules": [
    {
      "id": "10_network_discovery",
      "name": "Découverte réseau",
      "path": "modules/10_network_discovery.sh",
      "status": "success",
      "rc": 0,
      "started_at": "2026-07-01T00:00:01+00:00",
      "finished_at": "2026-07-01T00:00:02+00:00",
      "duration_seconds": 1,
      "output_path": "output/AUDIT_TEST_001/10_network_discovery",
      "reason": ""
    }
  ]
}
JSON

history_record_run "$manifest_path"

[[ -f "$(history_index_path)" ]]
[[ -f "$(history_latest_path)" ]]

grep -q 'AUDIT_TEST_001' "$(history_index_path)"
jq -e '.run_id == "AUDIT_TEST_001"' "$(history_latest_path)" >/dev/null
jq -e '.modules[0].status == "success"' "$(history_latest_path)" >/dev/null

writer_pids=()
for writer_id in $(seq 1 12); do
  writer_manifest="$AUDIT_HISTORY_DIR/manifest.concurrent.$writer_id.json"
  jq -n \
    --arg run_id "AUDIT_CONCURRENT_$writer_id" \
    --arg created_at "2026-07-01T00:00:${writer_id}Z" \
    '{
      schema_version: "1.0.0",
      run_id: $run_id,
      created_at: $created_at,
      profile: "fast",
      targets: ["192.168.1.0/24"],
      options: {},
      selected_modules: [],
      summary: {
        module_count: 0,
        success_count: 0,
        failed_count: 0,
        skipped_count: 0,
        total_duration_seconds: 0,
        status: "success"
      },
      modules: [],
      paths: {output: ("output/" + $run_id)}
    }' > "$writer_manifest"

  (
    history_record_run "$writer_manifest"
  ) &
  writer_pids+=("$!")
done

for writer_pid in "${writer_pids[@]}"; do
  wait "$writer_pid"
done

history_state="$(history_read_index_json)"
printf '%s\n' "$history_state" | jq -e '.invalid_line_count == 0' >/dev/null
printf '%s\n' "$history_state" | jq -e '.runs | length == 13' >/dev/null
printf '%s\n' "$history_state" | jq -e '[.runs[].run_id] | unique | length == 13' >/dev/null
jq -e '.run_id | startswith("AUDIT_")' "$(history_latest_path)" >/dev/null
[[ ! -e "$(history_lock_path)" ]]
if find "$AUDIT_HISTORY_DIR" -maxdepth 1 \( -name '.record.*' -o -name '.latest.*' \) | grep -q .; then
  echo 'temporary history files were not cleaned up' >&2
  exit 1
fi

bash bin/history.sh list >/dev/null
AUDIT_HISTORY_DIR="$AUDIT_HISTORY_DIR" bash bin/history.sh latest >/dev/null

printf '[OK] history tests passed\n'
