#!/usr/bin/env bash
# modules/20_portscan_nmap.sh
# @version 0.2.1
# shellcheck disable=SC2154
set -Eeuo pipefail
MOD_ID="20_portscan_nmap"
MOD_NAME="Portscan Nmap"
MOD_PRIO=20
MOD_REQUIRES=( "nmap" )
MOD_TIMEOUT=7200
MOD_TAGS=("network" "ports")

mod_pre(){ return 0; }
mod_run(){
  local out="$RUN_DIR/$MOD_ID"
  local -a targets=()

  mkdir -p "$out"
  read -r -a targets <<< "$TARGETS"

  case "$PROFILE" in
    fast) nmap -Pn -T4 --top-ports 200 -sV -oA "$out/fast" "${targets[@]}" ;;
    full) nmap -Pn -T4 -p- -sS -sV -O -oA "$out/full" "${targets[@]}" ;;
    stealth) nmap -Pn -T2 --top-ports 100 -sS -oA "$out/stealth" "${targets[@]}" ;;
    *)
      emit ERROR "$MOD_ID" "unknown profile: $PROFILE"
      return 2
      ;;
  esac

  [[ "${OPTS_NO_UDP:-0}" == 1 ]] || nmap -sU --top-ports 50 -oA "$out/udp_top" "${targets[@]}" || true
}
mod_post(){ return 0; }
