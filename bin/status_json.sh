#!/usr/bin/env bash
# bin/status_json.sh
# @version 0.2.16
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

# shellcheck source=../core/lib_history.sh
source "core/lib_history.sh"
# shellcheck source=../core/lib_modules.sh
source "core/lib_modules.sh"

REQUIRED_DEPS=(nmap jq tar gzip timeout)
OPTIONAL_DEPS=(tmux whiptail zenity fzf whatweb arp-scan fping sslscan nuclei zeek suricata)

usage_status_json() {
  cat <<'EOF'
Usage: bash bin/status_json.sh

Options:
  -h, --help
EOF
}

require_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    echo "jq requis pour produire le status JSON." >&2
    return 1
  fi
}

command_available() {
  local name="$1"
  command -v "$name" >/dev/null 2>&1
}

dependency_array_json() {
  local tmp_json dep available tmp_next

  tmp_json="$(mktemp)"
  printf '[]\n' > "$tmp_json"

  for dep in "$@"; do
    available=false
    if command_available "$dep"; then
      available=true
    fi

    tmp_next="$(mktemp)"
    jq \
      --arg name "$dep" \
      --argjson available "$available" \
      '. + [{name: $name, available: $available}]' \
      "$tmp_json" > "$tmp_next"
    mv "$tmp_next" "$tmp_json"
  done

  cat "$tmp_json"
  rm -f "$tmp_json"
}

count_history_runs() {
  local index_path
  index_path="$(history_index_path)"

  if [[ ! -s "$index_path" ]]; then
    printf '0\n'
    return 0
  fi

  wc -l < "$index_path" | tr -d ' '
}

count_modules() {
  modules_discover_sorted | wc -l | tr -d ' '
}

emit_status_json() {
  local required_json optional_json modules_count history_count
  local modules_dir_exists=false history_index_exists=false latest_exists=false

  required_json="$(dependency_array_json "${REQUIRED_DEPS[@]}")"
  optional_json="$(dependency_array_json "${OPTIONAL_DEPS[@]}")"
  modules_count="$(count_modules)"
  history_count="$(count_history_runs)"

  [[ -d modules ]] && modules_dir_exists=true
  [[ -f "$(history_index_path)" ]] && history_index_exists=true
  [[ -f "$(history_latest_path)" ]] && latest_exists=true

  jq -n \
    --arg kind "audit-suite.status" \
    --arg schema_version "1.0.0" \
    --arg cwd "$REPO_DIR" \
    --arg history_dir "$(history_dir)" \
    --arg history_index "$(history_index_path)" \
    --arg history_latest "$(history_latest_path)" \
    --argjson required "$required_json" \
    --argjson optional "$optional_json" \
    --argjson modules_count "$modules_count" \
    --argjson history_count "$history_count" \
    --argjson modules_dir_exists "$modules_dir_exists" \
    --argjson history_index_exists "$history_index_exists" \
    --argjson latest_exists "$latest_exists" \
    '{
      kind: $kind,
      schema_version: $schema_version,
      cwd: $cwd,
      checks: {
        modules_dir_exists: $modules_dir_exists,
        history_index_exists: $history_index_exists,
        latest_exists: $latest_exists
      },
      counts: {
        modules: $modules_count,
        history_runs: $history_count
      },
      paths: {
        history: $history_dir,
        history_index: $history_index,
        history_latest: $history_latest
      },
      dependencies: {
        required: $required,
        optional: $optional
      }
    }'
}

case "${1:-}" in
  -h|--help)
    usage_status_json
    exit 0
    ;;
  "")
    ;;
  *)
    echo "Option inconnue: $1" >&2
    usage_status_json >&2
    exit 2
    ;;
esac

require_jq
emit_status_json
