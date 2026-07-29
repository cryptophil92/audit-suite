#!/usr/bin/env bash
# modules/_TEMPLATE.module.sh
# @version 0.2.0
# shellcheck disable=SC2154
set -Eeuo pipefail

MOD_ID="XX_name"
MOD_NAME="Name"
MOD_PRIO=50
MOD_REQUIRES=( )
MOD_TIMEOUT=1800
MOD_TAGS=("category")
# État public du module dans le catalogue.
# Valeurs de maturité : experimental, partial, placeholder, deprecated.
MOD_MATURITY="experimental"
MOD_CAPABILITIES=("example_capability")
MOD_INTRUSIVENESS="low"
MOD_PRIVILEGES=("standard_user")
MOD_SELECTABLE=1
MOD_LIMITATIONS="Décrire ici ce que le module ne couvre pas."
# Profils nécessitant des sockets brutes, le cas échéant.
MOD_RAW_SOCKET_PROFILES=()
# Mettre à 1 si l'étape UDP facultative utilise des sockets brutes.
MOD_RAW_SOCKET_FOR_UDP=0
# Action ou couverture dégradée affichée avant lancement.
MOD_RAW_SOCKET_FALLBACK=""

mod_pre() { emit INFO "$MOD_ID" "pre"; return 0; }
mod_run() {
  emit INFO "$MOD_ID" "run targets=$TARGETS profile=$PROFILE"
  local out="$RUN_DIR/$MOD_ID"
  mkdir -p "$out"
  # actions...
}
mod_post() { emit INFO "$MOD_ID" "post"; return 0; }
