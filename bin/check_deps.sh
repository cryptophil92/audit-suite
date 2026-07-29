#!/usr/bin/env bash
# bin/check_deps.sh
# @version 0.3.0
set -Eeuo pipefail

INSTALL_MISSING=0

CORE_DEPS=( jq timeout tar gzip )
ENVIRONMENT_DEPS=( ip )
API_DEPS=( python3 )
MODULE_DEPS=( nmap snmpwalk whatweb zeek suricata )
OPTIONAL_DEPS=( tmux whiptail zenity fzf arp-scan fping sslscan nuclei )

usage() {
  cat <<'EOF'
Usage: bin/check_deps.sh [options]

Options:
  --install    Propose l'installation des dépendances requises manquantes.
  -h, --help   Affiche cette aide.

Par défaut, ce script vérifie uniquement les dépendances et n'installe rien.
Seules les commandes du socle moteur sont bloquantes. Les autres capacités
indiquent le module, l'API ou le confort qui sera indisponible.
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
  local command_name="$1"
  local pkg="$command_name"
  local ans

  case "$command_name" in
    timeout) pkg="coreutils" ;;
    ip) pkg="iproute2" ;;
  esac

  echo "[?] Installer $pkg pour fournir $command_name ? [y/N]"
  read -r ans || true
  [[ "$ans" =~ ^[Yy]$ ]] || return 1

  if command -v sudo >/dev/null 2>&1; then
    sudo apt-get update -y && sudo apt-get install -y "$pkg"
  else
    apt-get update -y && apt-get install -y "$pkg"
  fi
}

check_group() {
  local status="$1"
  local role="$2"
  shift 2

  local dep
  for dep in "$@"; do
    if command -v "$dep" >/dev/null 2>&1; then
      printf '[OK] %s : %s disponible.\n' "$role" "$dep"
    else
      printf '[%s] %s : %s absent.\n' "$status" "$role" "$dep"
    fi
  done
}

missing_core=()
for dep in "${CORE_DEPS[@]}"; do
  if ! command -v "$dep" >/dev/null 2>&1; then
    missing_core+=("$dep")
  fi
done

check_group "BLOQUANT" "Socle moteur" "${CORE_DEPS[@]}"
check_group "DÉGRADÉ" "Détection réseau (paquet iproute2)" "${ENVIRONMENT_DEPS[@]}"
check_group "INFO" "API locale et dashboard" "${API_DEPS[@]}"
check_group "INFO" "Modules sélectionnables" "${MODULE_DEPS[@]}"
check_group "INFO" "Confort facultatif" "${OPTIONAL_DEPS[@]}"

if (( ${#missing_core[@]} > 0 )); then
  if (( INSTALL_MISSING == 1 )); then
    for dep in "${missing_core[@]}"; do
      install_pkg "$dep" || echo "-> Installation ignorée ou échouée: $dep"
    done
  else
    echo "[ARRÊT] Socle moteur incomplet. Relancer avec --install pour proposer l'installation."
    exit 1
  fi
fi

echo "[PRÊT] Diagnostic terminé. Les outils absents hors socle produiront un mode dégradé ou un skip explicite."
exit 0
