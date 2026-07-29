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
MOD_MATURITY="experimental"
MOD_CAPABILITIES=("nmap_nse_vulnerability_checks")
MOD_INTRUSIVENESS="high"
MOD_PRIVILEGES=("standard_user")
MOD_SELECTABLE=1
MOD_LIMITATIONS="Les scripts NSE peuvent produire des faux positifs ; leurs résultats exigent une validation humaine."

mod_pre(){ return 0; }
mod_run(){
  local out="$RUN_DIR/$MOD_ID"
  local -a targets=()

  mkdir -p "$out"
  read -r -a targets <<< "$TARGETS"

  nmap -Pn -sV --script vuln -oA "$out/vuln" "${targets[@]}"
}
mod_post(){ return 0; }
