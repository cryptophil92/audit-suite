#!/usr/bin/env bash
set -Eeuo pipefail
MOD_ID="XX_name"; MOD_NAME="Name"; MOD_PRIO=50
MOD_REQUIRES=("nmap"); MOD_TIMEOUT=1800; MOD_TAGS=("category")
mod_pre()  { emit INFO "$MOD_ID" "pre"; }
mod_run()  { emit INFO "$MOD_ID" "run targets=$TARGETS profile=$PROFILE"; mkdir -p "$RUN_DIR/$MOD_ID"; }
mod_post() { emit INFO "$MOD_ID" "post"; }
