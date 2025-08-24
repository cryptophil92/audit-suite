#!/usr/bin/env bash

set -Eeuo pipefail



# --- CLI ---

TARGETS=""

DURATION="600"

PROFILE="fast"



usage() {

  cat <<USAGE

Usage: $0 -t "CIDR[,CIDR]" [-d seconds] [-p fast|full|stealth]

USAGE

}



while getopts ":t:d:p:h" opt; do

  case "$opt" in

    t) TARGETS="$OPTARG" ;;

    d) DURATION="$OPTARG" ;;

    p) PROFILE="$OPTARG" ;;

    h) usage; exit 0 ;;

    *) usage; exit 1 ;;

  esac

done



[[ -z "${TARGETS}" ]] && { echo "[-] -t requis (ex: 192.168.1.0/24)"; exit 1; }

[[ "${PROFILE}" =~ ^(fast|full|stealth)$ ]] || { echo "[-] profil invalide: ${PROFILE}"; exit 1; }



# --- chemins ---

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

ETC_DIR="${ROOT_DIR}/etc"

MOD_DIR="${ROOT_DIR}/modules"

LOG_ROOT="${ROOT_DIR}/logs"

OUT_ROOT="${ROOT_DIR}/output"



TS="${TS:-$(date +%Y%m%d_%H%M%S)}"

RUN_DIR="${LOG_ROOT}/${TS}"

mkdir -p "${RUN_DIR}" "${OUT_ROOT}"



COMBINED="${RUN_DIR}/combined.log"

touch "${COMBINED}"



# --- env par défaut + profil ---

# etc/defaults.env (générique) puis etc/profiles/${PROFILE}.env (spécifique)

if [[ -f "${ETC_DIR}/defaults.env" ]]; then

  # shellcheck disable=SC1090

  source "${ETC_DIR}/defaults.env"

fi

if [[ -f "${ETC_DIR}/profiles/${PROFILE}.env" ]]; then

  # shellcheck disable=SC1090

  source "${ETC_DIR}/profiles/${PROFILE}.env"

else

  echo "[-] Profil introuvable: ${ETC_DIR}/profiles/${PROFILE}.env" | tee -a "${COMBINED}"

  exit 1

fi



# Variables d’environnement transmises aux modules

export TS TARGETS DURATION PROFILE ROOT_DIR ETC_DIR OUT_ROOT RUN_DIR



# --- utilitaires ---

log() { echo "[$(date +%H:%M:%S)] $*" | tee -a "${COMBINED}"; }

run_module() {

  local mod="$1"

  [[ -x "${mod}" ]] || { log "skip $(basename "$mod") (non exécutable)"; return 0; }

  log ">>> START $(basename "$mod")"

  if ! "${mod}" 2>&1 | tee -a "${COMBINED}"; then

    log "!!! FAIL  $(basename "$mod")"

    return 1

  fi

  log "<<< DONE  $(basename "$mod")"

}



# --- prévol ---

log "[i] audit-suite :: profile=${PROFILE} targets=${TARGETS} duration=${D



OEF

