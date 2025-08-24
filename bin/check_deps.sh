#!/usr/bin/env bash
# bin/check_deps.sh
# @version 0.1.0
set -Eeuo pipefail

DEPS=( nmap whatweb tmux whiptail zenity fzf jq tar gzip )
OPT_DEPS=( arp-scan fping sslscan nuclei zeek suricata )

ask_install() {
  local pkg="$1"
  echo "[?] Installer $pkg ? [Y/n]"
  read -r ans || true
  [[ -z "$ans" || "$ans" =~ ^[Yy]$ ]] || return 1
  if command -v sudo >/dev/null 2>&1; then
    sudo apt-get update -y && sudo apt-get install -y "$pkg" || true
  else
    apt-get update -y && apt-get install -y "$pkg" || true
  fi
}

for d in "${DEPS[@]}"; do
  if ! command -v "$d" >/dev/null 2>&1; then
    echo "[!] Dépendance manquante: $d"
    ask_install "$d" || echo "-> Ignorée (fonctionnalité dégradée)"
  fi
done

for d in "${OPT_DEPS[@]}"; do
  command -v "$d" >/dev/null 2>&1 || echo "[i] Optionnel manquant: $d"
done

exit 0
