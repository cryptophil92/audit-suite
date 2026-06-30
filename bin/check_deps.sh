#!/usr/bin/env bash
# bin/check_deps.sh
# @version 0.2.0
set -Eeuo pipefail

INSTALL_MISSING=0

REQUIRED_DEPS=( nmap jq tar gzip timeout )
OPTIONAL_DEPS=( tmux whiptail zenity fzf whatweb arp-scan fping sslscan nuclei zeek suricata )

usage() {
  cat <<'EOF'
Usage: bin/check_deps.sh [options]

Options:
  --install    Propose l'installation des dépendances requises manquantes.
  -h, --help   Affiche cette aide.

Par défaut, ce script vérifie uniquement les dépendances et n'installe rien.
EOF
}

while (( $# > 0 )); do
  case "$1" in
    --install)
      INSTALL_MISSING=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Option inconnue: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

install_pkg() {
  local pkg="$1"
  local ans

  echo "[?] Installer $pkg ? [y/N]"
  read -r ans || true
  [[ "$ans" =~ ^[Yy]$ ]] || return 1

  if command -v sudo >/dev/null 2>&1; then
    sudo apt-get update -y && sudo apt-get install -y "$pkg"
  else
    apt-get update -y && apt-get install -y "$pkg"
  fi
}

missing_required=()

for dep in "${REQUIRED_DEPS[@]}"; do
  if ! command -v "$dep" >/dev/null 2>&1; then
    echo "[!] Dépendance requise manquante: $dep"
    missing_required+=("$dep")
  fi
done

for dep in "${OPTIONAL_DEPS[@]}"; do
  if ! command -v "$dep" >/dev/null 2>&1; then
    echo "[i] Optionnel manquant: $dep"
  fi
done

if (( ${#missing_required[@]} > 0 )); then
  if (( INSTALL_MISSING == 1 )); then
    for dep in "${missing_required[@]}"; do
      install_pkg "$dep" || echo "-> Installation ignorée ou échouée: $dep"
    done
  else
    echo "[!] Dépendances requises manquantes. Relancer avec --install pour proposer l'installation."
    exit 1
  fi
fi

exit 0
