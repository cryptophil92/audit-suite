#!/usr/bin/env bash
# core/lib_logging.sh
# @version 0.1.0
set -Eeuo pipefail

init_logging() {
  RUN_ID="$1"; shift || true
  LOG_DIR="logs/$RUN_ID"; mkdir -p "$LOG_DIR"
  LOG_FILE="$LOG_DIR/combined.log"
  LOG_BUS="tmp/eventbus.$RUN_ID"
  [[ -p "$LOG_BUS" ]] || mkfifo "$LOG_BUS" 2>/dev/null || true
}

emit() { # emit LEVEL MODULE MSG...
  local lvl="$1" mod="$2"; shift 2
  local msg
  msg="$(date -Is) [$lvl] [$mod] $*"
  echo "$msg" | tee -a "$LOG_FILE" >/dev/null
  if [[ -p "$LOG_BUS" ]]; then
    printf '%s\n' "$msg" > "$LOG_BUS" 2>/dev/null || true
  fi
}

with_log() { # with_log MODULE CMD...
  local mod="$1"; shift
  { "$@" 2>&1 | while IFS= read -r line; do emit INFO "$mod" "$line"; done; } || {
    emit ERROR "$mod" "command failed: $*"
    return 1
  }
}
