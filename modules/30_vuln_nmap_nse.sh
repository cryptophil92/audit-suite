#!/usr/bin/env bash
# modules/30_vuln_nmap_nse.sh
# @version 0.1.0
set -Eeuo pipefail
MOD_ID="30_vuln_nmap_nse"
MOD_NAME="Nmap NSE Vuln"
MOD_PRIO=30
MOD_REQUIRES=( "nmap" )
MOD_TIMEOUT=7200
MOD_TAGS=("vuln" "nse")

mod_pre(){ return 0; }
mod_run(){
  local out="$RUN_DIR/$MOD_ID"; mkdir -p "$out"
  nmap -Pn -sV --script vuln -oA "$out/vuln" $TARGETS || true
}
mod_post(){ return 0; }
