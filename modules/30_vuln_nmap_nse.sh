#!/usr/bin/env bash
set -Eeuo pipefail
MOD_ID="30_vuln_nmap_nse"; MOD_NAME="Nmap NSE Vuln"; MOD_PRIO=30
MOD_REQUIRES=("nmap"); MOD_TIMEOUT=7200; MOD_TAGS=("vuln" "nse")
mod_pre(){ :; }
mod_run(){
  local out="$RUN_DIR/$MOD_ID"; mkdir -p "$out"
  nmap -Pn -T4 --script vuln -oA "$out/vuln" $TARGETS || true
}
mod_post(){ :; }
