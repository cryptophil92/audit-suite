#!/usr/bin/env bash
# modules/_TEMPLATE.module.sh
# @version 0.1.0
set -Eeuo pipefail

MOD_ID="XX_name"
MOD_NAME="Name"
MOD_PRIO=50
MOD_REQUIRES=( )
MOD_TIMEOUT=1800
MOD_TAGS=("category")

mod_pre() { emit INFO "$MOD_ID" "pre"; return 0; }
mod_run() {
  emit INFO "$MOD_ID" "run targets=$TARGETS profile=$PROFILE"
  local out="$RUN_DIR/$MOD_ID"; mkdir -p "$out"
  # actions...
}
mod_post() { emit INFO "$MOD_ID" "post"; return 0; }
