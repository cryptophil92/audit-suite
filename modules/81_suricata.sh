#!/usr/bin/env bash
# modules/81_suricata.sh
# @version 0.1.0
set -Eeuo pipefail
MOD_ID="81_suricata"
MOD_NAME="Suricata IDS (option)"
MOD_PRIO=81
MOD_REQUIRES=( "suricata" )
MOD_TIMEOUT=7200
MOD_TAGS=("ids")
MOD_SKIP_OPTION="OPTS_NO_SURICATA"

mod_pre(){ return 0; }
mod_run(){
  local out="$RUN_DIR/$MOD_ID"; mkdir -p "$out"
  echo "Suricata placeholder (activer si désiré)" > "$out/README.txt"
}
mod_post(){ return 0; }
