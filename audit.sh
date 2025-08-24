#!/usr/bin/env bash
# audit.sh - Launcher principal de la suite d'audit
# @version 0.1.1
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Charger libs
for lib in core/lib_logging.sh core/lib_detect.sh core/lib_menu.sh core/lib_runner.sh core/lib_update.sh; do
  # shellcheck source=/dev/null
  source "$lib"
done

# Pré-traitement signaux
cleanup() {
  [[ -n "${LOG_BUS:-}" && -p "${LOG_BUS}" ]] && rm -f "${LOG_BUS}" || true
}
trap 'emit ERROR "launcher" "interrupted"; cleanup' INT TERM
trap 'cleanup' EXIT

# Vérifier dépendances (retourne toujours 0)
bin/check_deps.sh || true

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
emit INFO "launcher" "Start profile=$PROFILE targets=$TARGETS opts=no-udp:$OPTS_NO_UDP,no-zeek:$OPTS_NO_ZEEK,no-suricata:$OPTS_NO_SURICATA"

# Lancer UI logger tmux si dispo
if command -v tmux >/dev/null 2>&1; then
  ( RUN_ID="$RUN_ID" ui/ui_tmux_logger.sh ) || true
fi

# Export env standard pour les modules
export RUN_ID TARGETS PROFILE RUN_DIR LOG_DIR LOG_FILE LOG_BUS OPTS_NO_UDP OPTS_NO_ZEEK OPTS_NO_SURICATA DEF_IFACE DEF_CIDR HAVE_X11 HAVE_TMUX

# Orchestration
discover_modules_sorted >"$TMP_DIR/modules.list"
SELECTED="$(printf '%s' "$CATEGORIES" | tr ',' ' ')"   # runner accepte espaces
run_modules "$SELECTED"

# Manifest de run
write_manifest_json "$RUN_DIR/manifest.json" "$SELECTED"

emit INFO "launcher" "Terminé. Dossier: $RUN_DIR"
echo "Audit terminé. Résultats: $RUN_DIR"
