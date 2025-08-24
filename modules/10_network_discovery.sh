#!/usr/bin/env bash
# modules/10_network_discovery.sh
# @version 0.1.0
set -Eeuo pipefail
MOD_ID="10_network_discovery"
MOD_NAME="Découverte réseau"
MOD_PRIO=10
MOD_REQUIRES=( "nmap" )
MOD_TIMEOUT=1200
MOD_TAGS=("network" "discovery")

mod_pre(){ return 0; }
mod_run(){
  local out="$RUN_DIR/$MOD_ID"; mkdir -p "$out"
  emit INFO "$MOD_ID" "Ping sweep / ARP / Top hosts"
  # Ping sweep de base via nmap (fallback si arp-scan indisponible)
  nmap -sn -oA "$out/pingsweep" $TARGETS || true
}
mod_post(){ return 0; }
