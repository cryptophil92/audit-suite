#!/usr/bin/env bash
set -Eeuo pipefail
deps=(nmap arp-scan fping whiptail tmux jq tar gzip)
missing=()
for d in "${deps[@]}"; do command -v "$d" >/dev/null 2>&1 || missing+=("$d"); done
if ((${#missing[@]})); then
  echo "[i] Manquants: ${missing[*]}"
  read -rp "Installer via apt? [o/N] " a
  if [[ "${a,,}" == o* ]]; then sudo apt update && sudo apt install -y "${missing[@]}"; else echo "[!] Continuer sans eux (dégradé)."; fi
fi
exit 0
