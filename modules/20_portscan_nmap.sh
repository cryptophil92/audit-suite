#!/usr/bin/env bash
# modules/20_portscan_nmap.sh
# @version 0.2.2
# shellcheck disable=SC2034,SC2153,SC2154
set -Eeuo pipefail
MOD_ID="20_portscan_nmap"
MOD_NAME="Portscan Nmap"
MOD_PRIO=20
MOD_REQUIRES=( "nmap" )
MOD_TIMEOUT=7200
MOD_TAGS=("network" "ports")
MOD_RAW_SOCKET_PROFILES=("full" "stealth")
MOD_RAW_SOCKET_FOR_UDP=1
MOD_RAW_SOCKET_FALLBACK="Repli sûr : scan TCP connect (-sT), sans détection OS, et UDP ignoré. Relancez avec les capacités réseau adaptées pour la couverture complète."

mod_pre(){ return 0; }
mod_run(){
  local out="$RUN_DIR/$MOD_ID"
  local udp_rc
  local raw_socket_available="${AUDIT_RAW_SOCKET_AVAILABLE:-1}"
  local -a targets=()

  mkdir -p "$out"
  read -r -a targets <<< "$TARGETS"

  case "$PROFILE" in
    fast) nmap -Pn -T4 --top-ports 200 -sV -oA "$out/fast" "${targets[@]}" ;;
    full)
      if [[ "$raw_socket_available" == "1" ]]; then
        nmap -Pn -T4 -p- -sS -sV -O -oA "$out/full" "${targets[@]}"
      else
        module_mark_partial "raw socket unavailable: TCP connect fallback; OS detection and UDP skipped"
        nmap -Pn -T4 -p- -sT -sV -oA "$out/full" "${targets[@]}"
      fi
      ;;
    stealth)
      if [[ "$raw_socket_available" == "1" ]]; then
        nmap -Pn -T2 --top-ports 100 -sS -oA "$out/stealth" "${targets[@]}"
      else
        module_mark_partial "raw socket unavailable: TCP connect fallback; UDP skipped"
        nmap -Pn -T2 --top-ports 100 -sT -oA "$out/stealth" "${targets[@]}"
      fi
      ;;
    *)
      emit ERROR "$MOD_ID" "unknown profile: $PROFILE"
      return 2
      ;;
  esac

  if [[ "${OPTS_NO_UDP:-0}" != 1 && "$raw_socket_available" == "1" ]]; then
    if nmap -sU --top-ports 50 -oA "$out/udp_top" "${targets[@]}"; then
      :
    else
      udp_rc=$?
      module_mark_partial "optional UDP scan returned rc=$udp_rc"
    fi
  elif [[ "${OPTS_NO_UDP:-0}" != 1 ]]; then
    module_mark_partial "raw socket unavailable: UDP scan skipped"
  fi
}
mod_post(){ return 0; }
