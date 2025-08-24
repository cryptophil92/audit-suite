#!/usr/bin/env bash
set -Eeuo pipefail
MOD_ID="10_network_discovery"; MOD_NAME="Network Discovery"; MOD_PRIO=10
MOD_REQUIRES=("arp-scan" "fping"); MOD_TIMEOUT=1200; MOD_TAGS=("network" "discovery")
mod_pre(){ :; }
mod_run(){
  local out="$RUN_DIR/$MOD_ID"; mkdir -p "$out"
  emit INFO "$MOD_ID" "arp-scan on $TARGETS"
  command -v arp-scan >/dev/null 2>&1 && with_log "$MOD_ID" bash -c "for c in \${TARGETS//,/ }; do arp-scan -lgI \"\$DEF_IFACE\" \"\$c\" || true; done" | tee "$out/arp-scan.txt" >/dev/null || true
}
mod_post(){ :; }
