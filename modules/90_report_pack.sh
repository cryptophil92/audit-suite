#!/usr/bin/env bash
# modules/90_report_pack.sh
# @version 0.1.0
set -Eeuo pipefail
MOD_ID="90_report_pack"
MOD_NAME="Pack rapport"
MOD_PRIO=90
MOD_REQUIRES=( "tar" "gzip" )
MOD_TIMEOUT=600
MOD_TAGS=("report")

mod_pre(){ return 0; }
mod_run(){
  local out="$RUN_DIR/$MOD_ID"; mkdir -p "$out"
  tar -C "$RUN_DIR/.." -czf "$out/../${RUN_ID}.tar.gz" "$RUN_ID" || true
  printf 'Run: %s\nProfile: %s\nTargets: %s\n' "$RUN_ID" "$PROFILE" "$TARGETS" > "$out/summary.txt"
  emit INFO "$MOD_ID" "Archive créée: $RUN_DIR/../${RUN_ID}.tar.gz"
}
mod_post(){ return 0; }
