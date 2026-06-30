#!/usr/bin/env bash
# modules/30_vuln_nmap_nse.sh
# @version 0.2.2
# shellcheck disable=SC2034,SC2153,SC2154
set -Eeuo pipefail
MOD_ID="30_vuln_nmap_nse"
MOD_NAME="Nmap NSE Vuln"
MOD_PRIO=30
MOD_REQUIRES=( "nmap" )
MOD_TIMEOUT=7200
MOD_TAGS=("vuln" "nse")

mod_pre(){ return 0; }
mod_run(){
  local out="$RUN_DIR/$MOD_ID"
  local -a targets=()

  mkdir -p "$out"
  read -r -a targets <<< "$TARGETS"

  nmap -Pn -sV --script vuln -oA "$out/vuln" "${targets[@]}" || true
}
mod_post(){ return 0; }
