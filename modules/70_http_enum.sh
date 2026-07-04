#!/usr/bin/env bash
# modules/70_http_enum.sh
# @version 0.2.0
# shellcheck disable=SC2034,SC2153,SC2154
set -Eeuo pipefail
MOD_ID="70_http_enum"
MOD_NAME="HTTP enum"
MOD_PRIO=70
MOD_REQUIRES=( "whatweb" "nmap" )
MOD_TIMEOUT=7200
MOD_TAGS=("http" "web")

mod_pre(){ return 0; }
mod_run(){
  local out="$RUN_DIR/$MOD_ID"
  local -a targets=()

  mkdir -p "$out"
  read -r -a targets <<< "$TARGETS"

  # Simple: scanner IP:80/443 avec whatweb; outils avancés optionnels non forcés
  whatweb --color=never --aggression=1 -a 1 -v -i <(nmap -Pn -p 80,443 --open -oG - "${targets[@]}" | awk '/open/{print $2}') | tee "$out/whatweb.txt" || true
}
mod_post(){ return 0; }
