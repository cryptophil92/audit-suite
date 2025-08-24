#!/usr/bin/env bash
set -Eeuo pipefail
init_logging(){ RUN_ID="$1"; LOG_DIR="logs/$RUN_ID"; mkdir -p "$LOG_DIR" tmp; LOG_FILE="$LOG_DIR/combined.log"; LOG_BUS="tmp/eventbus.$RUN_ID"; mkfifo "$LOG_BUS" 2>/dev/null || true; }
emit(){ local lvl="$1" mod="$2"; shift 2; local msg="$(date -Is) [$lvl] [$mod] $*"; echo "$msg" | tee -a "$LOG_FILE" >/dev/null; printf '%s\n' "$msg" > "$LOG_BUS" 2>/dev/null || true; }
with_log(){ local mod="$1"; shift; "$@" 1> >(sed "s/^/[$mod][OUT] /" | tee -a "$LOG_FILE") 2> >(sed "s/^/[$mod][ERR] /" | tee -a "$LOG_FILE" >&2); }
