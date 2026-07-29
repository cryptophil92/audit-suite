#!/usr/bin/env bash
# modules/60_smb_enum.sh
# @version 0.2.0
# shellcheck disable=SC2034,SC2153,SC2154
set -Eeuo pipefail
MOD_ID="60_smb_enum"
MOD_NAME="Détection SMB"
MOD_PRIO=60
MOD_REQUIRES=( "nmap" )
MOD_TIMEOUT=3600
MOD_TAGS=("smb")
MOD_MATURITY="partial"
MOD_CAPABILITIES=("smb_port_detection")
MOD_INTRUSIVENESS="low"
MOD_PRIVILEGES=("standard_user")
MOD_SELECTABLE=1
MOD_LIMITATIONS="Détecte uniquement les ports SMB 139/445 ouverts ; aucune énumération de partages, comptes ou configuration."

mod_pre(){ return 0; }
mod_run(){
  local out="$RUN_DIR/$MOD_ID"
  local -a targets=()

  mkdir -p "$out"
  read -r -a targets <<< "$TARGETS"

  # Détecter SMB rapidement
  nmap -Pn -p 139,445 --open -oG "$out/smb.gnmap" "${targets[@]}"
  module_mark_partial "SMB coverage is detection-only: open ports 139/445; no share, account or configuration enumeration"
}
mod_post(){ return 0; }
