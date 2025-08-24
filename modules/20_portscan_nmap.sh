#!/usr/bin/env bash
set -Eeuo pipefail
MOD_ID="20_portscan_nmap"; MOD_NAME="Portscan Nmap"; MOD_PRIO=20
MOD_REQUIRES=("nmap"); MOD_TIMEOUT=7200; MOD_TAGS=("network" "ports")
mod_pre(){ :; }
mod_run(){
  local out="$RUN_DIR/$MOD_ID"; mkdir -p "$out"
  case "$PROFILE" in
    fast)    nmap -Pn -T4 --top-ports 200 -sV -oA "$out/fast"  $TARGETS ;;
    full)    nmap -Pn -T4 -p- -sS -sV -O  -oA "$out/full"       $TARGETS ;;
    stealth) nmap -Pn -T2 --top-ports 100 -sS -oA "$out/stealth" $TARGETS ;;
  esac
  [[ "${OPTS_NO_UDP:-0}" == 1 ]] || nmap -sU --top-ports 50 -oA "$out/udp_top" $TARGETS || true
}
mod_post(){ :; }
