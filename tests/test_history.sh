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

bash bin/history.sh list >/dev/null
AUDIT_HISTORY_DIR="$AUDIT_HISTORY_DIR" bash bin/history.sh latest >/dev/null

printf '[OK] history tests passed\n'
