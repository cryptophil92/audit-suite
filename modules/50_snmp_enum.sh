#!/usr/bin/env bash
# modules/50_snmp_enum.sh
# @version 0.1.0
set -Eeuo pipefail
MOD_ID="50_snmp_enum"
MOD_NAME="SNMP enum (si présent)"
MOD_PRIO=50
MOD_REQUIRES=( "snmpwalk" )
MOD_TIMEOUT=1800
MOD_TAGS=("snmp")

mod_pre(){ return 0; }
mod_run(){
  local out="$RUN_DIR/$MOD_ID"; mkdir -p "$out"
  # Exemple: essayer public sur les hôtes /24 trouvés (placeholder)
  echo "TODO SNMP enum" > "$out/README.txt"
}
mod_post(){ return 0; }
