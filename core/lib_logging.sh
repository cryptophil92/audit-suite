#!/usr/bin/env bash
# core/lib_logging.sh
# @version 0.2.0
set -Eeuo pipefail

init_logging() {
  RUN_ID="$1"; shift || true
  LOG_DIR="logs/$RUN_ID"; mkdir -p "$LOG_DIR"
  LOG_FILE="$LOG_DIR/combined.log"
  # No event-bus consumer exists today. Keep the variable for compatibility,
  # but never create or write to a FIFO that could block without a reader.
  LOG_BUS=""
}

emit() { # emit LEVEL MODULE MSG...
  local lvl="$1" mod="$2"; shift 2
  local msg log_file

  log_file="${LOG_FILE:-/dev/stderr}"
  msg="$(date -Is) [$lvl] [$mod] $*"

  echo "$msg" | tee -a "$log_file" >/dev/null
}

with_log() { # with_log MODULE CMD...
  local mod="$1"; shift
  { "$@" 2>&1 | while IFS= read -r line; do emit INFO "$mod" "$line"; done; } || {
    emit ERROR "$mod" "command failed: $*"
    return 1
  }
}
