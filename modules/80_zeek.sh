#!/usr/bin/env bash
# modules/80_zeek.sh
# @version 0.1.0
set -Eeuo pipefail
MOD_ID="80_zeek"
MOD_NAME="Zeek PCAP (option)"
MOD_PRIO=80
MOD_REQUIRES=( "zeek" )
MOD_TIMEOUT=7200
MOD_TAGS=("pcap" "ids")
MOD_SKIP_OPTION="OPTS_NO_ZEEK"

mod_pre(){ return 0; }
mod_run(){
  local out="$RUN_DIR/$MOD_ID"; mkdir -p "$out"
  echo "Zeek placeholder (activer si désiré)" > "$out/README.txt"
}
mod_post(){ return 0; }
