#!/usr/bin/env bash
# bin/api_snapshot_json.sh
# @version 0.2.17
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

usage_api_snapshot_json() {
  cat <<'EOF'
Usage: bash bin/api_snapshot_json.sh

Options:
  -h, --help
EOF
}

require_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    echo "jq requis pour produire le snapshot JSON." >&2
    return 1
  fi
}

emit_api_snapshot_json() (
  local tmp_dir status_file modules_file history_file latest_file command_failed
  local -a command_pids=()

  tmp_dir="$(mktemp -d)"
  trap 'rm -rf -- "$tmp_dir"' EXIT
  status_file="$tmp_dir/status.json"
  modules_file="$tmp_dir/modules.json"
  history_file="$tmp_dir/history.json"
  latest_file="$tmp_dir/latest.json"

  bash bin/status_json.sh > "$status_file" &
  command_pids+=("$!")
  bash bin/modules_json.sh > "$modules_file" &
  command_pids+=("$!")
  bash bin/history_json.sh list > "$history_file" &
  command_pids+=("$!")
  bash bin/history_json.sh latest > "$latest_file" &
  command_pids+=("$!")

  command_failed=0
  for command_pid in "${command_pids[@]}"; do
    if ! wait "$command_pid"; then
      command_failed=1
    fi
  done
  if (( command_failed != 0 )); then
    echo "Échec d'une commande du snapshot JSON." >&2
    return 1
  fi

  jq -n \
    --arg kind "audit-suite.api_snapshot" \
    --arg schema_version "1.0.0" \
    --arg generated_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --slurpfile status "$status_file" \
    --slurpfile modules "$modules_file" \
    --slurpfile history "$history_file" \
    --slurpfile latest "$latest_file" \
    '{
      kind: $kind,
      schema_version: $schema_version,
      generated_at: $generated_at,
      degraded: (($history[0].degraded // false) or ($latest[0].degraded // false)),
      error_count: (($history[0].error_count // 0) + ($latest[0].error_count // 0)),
      status: $status[0],
      modules: $modules[0],
      history: $history[0],
      latest: $latest[0]
    }'

)

case "${1:-}" in
  -h|--help)
    usage_api_snapshot_json
    exit 0
    ;;
  "")
    ;;
  *)
    echo "Option inconnue: $1" >&2
    usage_api_snapshot_json >&2
    exit 2
    ;;
esac

require_jq
emit_api_snapshot_json
