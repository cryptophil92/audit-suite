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
MOD_MATURITY="experimental"
MOD_CAPABILITIES=("http_port_detection" "web_fingerprinting")
MOD_INTRUSIVENESS="moderate"
MOD_PRIVILEGES=("standard_user")
MOD_SELECTABLE=1
MOD_LIMITATIONS="Empreinte WhatWeb sur les services 80/443 détectés ; ne remplace pas un audit applicatif."

mod_pre(){ return 0; }
mod_run(){
  local out="$RUN_DIR/$MOD_ID"
  local http_targets
  local -a targets=()

  mkdir -p "$out"
  read -r -a targets <<< "$TARGETS"
  http_targets="$out/http_targets.txt"

  # Simple: scanner IP:80/443 avec whatweb; outils avancés optionnels non forcés
  nmap -Pn -p 80,443 --open -oG - "${targets[@]}" | awk '/open/{print $2}' > "$http_targets"
  whatweb --color=never --aggression=1 -a 1 -v -i "$http_targets" | tee "$out/whatweb.txt"
}
mod_post(){ return 0; }
