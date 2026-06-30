#!/usr/bin/env bash
# modules/40_service_enum.sh
# @version 0.2.1
# shellcheck disable=SC2154
set -Eeuo pipefail
MOD_ID="40_service_enum"
MOD_NAME="Énumération services"
MOD_PRIO=40
MOD_REQUIRES=( "nmap" )
MOD_TIMEOUT=7200
MOD_TAGS=("service" "enum")

mod_pre(){ return 0; }
mod_run(){
  local out="$RUN_DIR/$MOD_ID"
  local -a targets=()

  mkdir -p "$out"
  read -r -a targets <<< "$TARGETS"

  # Bannières via nmap -sV
  nmap -Pn -sV -oA "$out/sv" "${targets[@]}" || true
}
mod_post(){ return 0; }
