#!/usr/bin/env bash
# modules/60_smb_enum.sh
# @version 0.1.0
set -Eeuo pipefail
MOD_ID="60_smb_enum"
MOD_NAME="SMB enum (si présent)"
MOD_PRIO=60
MOD_REQUIRES=( "nmap" )
MOD_TIMEOUT=3600
MOD_TAGS=("smb")

mod_pre(){ return 0; }
mod_run(){
  local out="$RUN_DIR/$MOD_ID"; mkdir -p "$out"
  # Détecter SMB rapidement
  nmap -Pn -p 139,445 --open -oG "$out/smb.gnmap" $TARGETS || true
}
mod_post(){ return 0; }
