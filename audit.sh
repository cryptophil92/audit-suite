#!/usr/bin/env bash
# audit.sh - Launcher principal de la suite d'audit
# @version 0.2.2
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

ALLOW_PUBLIC=0

usage() {
  cat <<'EOF'
Usage: ./audit.sh [options]

Options:
  --allow-public    Autorise les cibles publiques. À utiliser uniquement avec autorisation explicite.
  -h, --help        Affiche cette aide.

Par défaut, AUDIT-SUITE refuse les IP/plages publiques et accepte uniquement les périmètres locaux/lab.
EOF
}

while (( $# > 0 )); do
  case "$1" in
    --allow-public)
      ALLOW_PUBLIC=1
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

# Charger libs
for lib in core/lib_logging.sh core/lib_detect.sh core/lib_menu.sh core/lib_validate.sh core/lib_runner.sh core/lib_update.sh; do
  # shellcheck source=/dev/null
  source "$lib"
done

safe_emit() {
  local lvl="$1" mod="$2"
  shift 2 || true

  if [[ -n "${LOG_FILE:-}" ]]; then
    emit "$lvl" "$mod" "$@"
  else
    printf '%s [%s] [%s] %s\n' "$(date -Is)" "$lvl" "$mod" "$*" >&2
  fi
}

# Pré-traitement signaux
cleanup() {
  [[ -n "${LOG_BUS:-}" && -p "${LOG_BUS}" ]] && rm -f "${LOG_BUS}" || true
}
trap 'safe_emit ERROR "launcher" "interrupted"; cleanup' INT TERM
trap 'cleanup' EXIT

# Préflight dépendances requises
bin/check_deps.sh

# Détecter environnement
detect_env

# UI: profil, cibles, catégories & options
PROFILE="$(ui_pick_profile || true)"
[[ -z "${PROFILE:-}" ]] && PROFILE="fast"

TARGETS="$(ui_enter_targets || true)"
[[ -z "${TARGETS:-}" ]] && {
  echo "Aucune cible fournie. Exemple: 192.168.1.0/24,192.168.27.0/24"
  exit 1
}

if ! TARGETS="$(validate_targets "$TARGETS" "$ALLOW_PUBLIC")"; then
  echo "Validation des cibles échouée. Audit annulé." >&2
  exit 1
fi

if [[ "$ALLOW_PUBLIC" == "1" ]]; then
  echo "ATTENTION: cibles publiques autorisées pour cette exécution. Vérifier l'autorisation écrite."
fi

CATEGORIES="$(ui_pick_categories || true)"
# normalisation: espaces/nouvelles lignes -> virgules, trim
CATEGORIES="$(printf '%s' "$CATEGORIES" | tr ' \n' ',' | sed 's/,,*/,/g; s/^,//; s/,$//')"

OPTS="$(ui_confirm_opts || true)"
OPTS_NO_UDP=0; OPTS_NO_ZEEK=0; OPTS_NO_SURICATA=0
[[ "$OPTS" == *"no-udp"* ]] && OPTS_NO_UDP=1
[[ "$OPTS" == *"no-zeek"* ]] && OPTS_NO_ZEEK=1
[[ "$OPTS" == *"no-suricata"* ]] && OPTS_NO_SURICATA=1

# RUN_ID & dossiers
RUN_ID="AUDIT_$(date -u +%Y%m%dT%H%M%SZ)"
RUN_DIR="output/$RUN_ID"
LOG_DIR="logs/$RUN_ID"
TMP_DIR="tmp"
mkdir -p "$RUN_DIR" "$LOG_DIR" "$TMP_DIR"

# Logging + event bus
init_logging "$RUN_ID"
emit INFO "launcher" "Start profile=$PROFILE targets=$TARGETS allow_public=$ALLOW_PUBLIC opts=no-udp:$OPTS_NO_UDP,no-zeek:$OPTS_NO_ZEEK,no-suricata:$OPTS_NO_SURICATA"

# Lancer UI logger tmux si dispo
if command -v tmux >/dev/null 2>&1; then
  ( RUN_ID="$RUN_ID" ui/ui_tmux_logger.sh ) || true
fi

# Export env standard pour les modules
export RUN_ID TARGETS PROFILE RUN_DIR LOG_DIR LOG_FILE LOG_BUS OPTS_NO_UDP OPTS_NO_ZEEK OPTS_NO_SURICATA DEF_IFACE DEF_CIDR HAVE_X11 HAVE_TMUX ALLOW_PUBLIC

# Orchestration
discover_modules_sorted >"$TMP_DIR/modules.list"
SELECTED="$(printf '%s' "$CATEGORIES" | tr ',' ' ')"   # runner accepte espaces
run_modules "$SELECTED"

# Manifest de run
write_manifest_json "$RUN_DIR/manifest.json" "$SELECTED"

emit INFO "launcher" "Terminé. Dossier: $RUN_DIR"
echo "Audit terminé. Résultats: $RUN_DIR"
