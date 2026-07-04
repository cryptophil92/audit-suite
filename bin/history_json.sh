#!/usr/bin/env bash
# bin/history_json.sh
# @version 0.2.34
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

# shellcheck source=../core/lib_history.sh
source "core/lib_history.sh"

usage_history_json() {
  cat <<'EOF'
Usage: bash bin/history_json.sh [command]

Commands:
  list          Export history index as JSON.
  latest        Export latest run as JSON.
  paths         Export history file paths as JSON.
  run RUN_ID    Export one run from the history index.
  help          Show this help.

Default: list
EOF
}

require_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    echo "jq requis pour produire l'historique JSON." >&2
    return 1
  fi
}

history_json_paths() {
  jq -n \
    --arg kind "audit-suite.history.paths" \
    --arg schema_version "1.0.0" \
    --arg dir "$(history_dir)" \
    --arg index "$(history_index_path)" \
    --arg latest "$(history_latest_path)" \
    '{kind: $kind, schema_version: $schema_version, paths: {history: $dir, index: $index, latest: $latest}}'
}

history_json_list() {
  local index_path
  index_path="$(history_index_path)"

  if [[ ! -s "$index_path" ]]; then
    jq -n \
      --arg kind "audit-suite.history" \
      --arg schema_version "1.0.0" \
      --arg index_path "$index_path" \
      '{kind: $kind, schema_version: $schema_version, count: 0, paths: {index: $index_path}, runs: []}'
    return 0
  fi

  jq -s \
    --arg kind "audit-suite.history" \
    --arg schema_version "1.0.0" \
    --arg index_path "$index_path" \
    '{kind: $kind, schema_version: $schema_version, count: length, paths: {index: $index_path}, runs: .}' \
    "$index_path"
}

history_json_latest() {
  local latest_path
  latest_path="$(history_latest_path)"

  if [[ ! -s "$latest_path" ]]; then
    jq -n \
      --arg kind "audit-suite.history.latest" \
      --arg schema_version "1.0.0" \
      --arg latest_path "$latest_path" \
      '{kind: $kind, schema_version: $schema_version, paths: {latest: $latest_path}, latest: null}'
    return 0
  fi

  jq \
    --arg kind "audit-suite.history.latest" \
    --arg schema_version "1.0.0" \
    --arg latest_path "$latest_path" \
    '{kind: $kind, schema_version: $schema_version, paths: {latest: $latest_path}, latest: .}' \
    "$latest_path"
}

history_json_run() {
  local run_id="$1"
  local index_path entry
  index_path="$(history_index_path)"

  if [[ -z "$run_id" ]]; then
    jq -n --arg kind "audit-suite.history.run" --arg schema_version "1.0.0" \
      '{kind: $kind, schema_version: $schema_version, error: "missing_run_id"}'
    return 0
  fi

  if [[ ! "$run_id" =~ ^[A-Za-z0-9._:-]+$ ]]; then
    jq -n --arg kind "audit-suite.history.run" --arg schema_version "1.0.0" --arg run_id "$run_id" \
      '{kind: $kind, schema_version: $schema_version, run_id: $run_id, error: "invalid_run_id"}'
    return 0
  fi

  if [[ ! -s "$index_path" ]]; then
    jq -n --arg kind "audit-suite.history.run" --arg schema_version "1.0.0" --arg run_id "$run_id" --arg index_path "$index_path" \
      '{kind: $kind, schema_version: $schema_version, run_id: $run_id, found: false, paths: {index: $index_path}, run: null}'
    return 0
  fi

  entry="$(jq -cs --arg run_id "$run_id" 'map(select(.run_id == $run_id)) | last // empty' "$index_path")"
  if [[ -z "$entry" ]]; then
    jq -n --arg kind "audit-suite.history.run" --arg schema_version "1.0.0" --arg run_id "$run_id" --arg index_path "$index_path" \
      '{kind: $kind, schema_version: $schema_version, run_id: $run_id, found: false, paths: {index: $index_path}, run: null}'
    return 0
  fi

  jq -n --arg kind "audit-suite.history.run" --arg schema_version "1.0.0" --arg run_id "$run_id" --arg index_path "$index_path" --argjson run "$entry" \
    '{kind: $kind, schema_version: $schema_version, run_id: $run_id, found: true, paths: {index: $index_path}, run: $run}'
}

cmd="${1:-list}"

case "$cmd" in
  list)
    require_jq
    history_json_list
    ;;
  latest)
    require_jq
    history_json_latest
    ;;
  paths|path)
    require_jq
    history_json_paths
    ;;
  run|detail)
    require_jq
    shift || true
    history_json_run "${1:-}"
    ;;
  help|-h|--help)
    usage_history_json
    ;;
  *)
    echo "Commande inconnue: $cmd" >&2
    usage_history_json >&2
    exit 2
    ;;
esac
