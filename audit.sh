#!/usr/bin/env bash
# audit.sh - Launcher principal de la suite d'audit
# @version 0.2.9
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Charger le parsing CLI en premier pour exposer usage()
# shellcheck source=/dev/null
source "core/lib_args.sh"

if ! parse_audit_args "$@"; then
  usage >&2
  exit 2
fi

if [[ "$AUDIT_ARG_HELP" == "1" ]]; then
  usage
  exit 0
fi

ALLOW_PUBLIC="$AUDIT_ARG_ALLOW_PUBLIC"

# Charger libs
for lib in core/lib_logging.sh core/lib_detect.sh core/lib_menu.sh core/lib_validate.sh core/lib_modules.sh core/lib_runner.sh core/lib_history.sh core/lib_update.sh; do
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

finalize_run_outputs() {
  local manifest_path="$1"
  local finalize_output

  if finalize_output="$(bash bin/finalize_reports.sh "$manifest_path" 2>&1)"; then
    while IFS= read -r line; do
      [[ -n "$line" ]] && emit INFO "report" "$line"
    done <<< "$finalize_output"
  else
    emit WARN "report" "Final report generation failed: $finalize_output"
  fi
}

print_available_modules() {
  discover_modules_sorted | sed 's#^modules/##'
}

print_dry_run_plan() {
  local selected="$1"

  cat <<EOF
AUDIT-SUITE dry run
Profile: $PROFILE
Targets: $TARGETS
Categories: $CATEGORIES
Selected modules: $selected
Options:
  allow_public: $ALLOW_PUBLIC
  no_udp: $OPTS_NO_UDP
  no_zeek: $OPTS_NO_ZEEK
  no_suricata: $OPTS_NO_SURICATA
EOF
}

if [[ "$AUDIT_ARG_LIST_MODULES" == "1" ]]; then
  print_available_modules
  exit 0
fi

# Pré-traitement signaux
cleanup() {
  if [[ -n "${LOG_BUS:-}" && -p "${LOG_BUS}" ]]; then
    rm -f "${LOG_BUS}"
  fi
}
trap 'safe_emit ERROR "launcher" "interrupted"; cleanup' INT TERM
trap 'cleanup' EXIT

# Profil, cibles, catégories & options : CLI prioritaire, UI en fallback
PROFILE="$AUDIT_ARG_PROFILE"
if [[ -z "${PROFILE:-}" ]]; then
  PROFILE="$(ui_pick_profile || true)"
fi
[[ -z "${PROFILE:-}" ]] && PROFILE="fast"

TARGETS="$AUDIT_ARG_TARGETS"
if [[ -z "${TARGETS:-}" ]]; then
  TARGETS="$(ui_enter_targets || true)"
fi
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

CATEGORIES="$AUDIT_ARG_CATEGORIES"
if [[ -z "${CATEGORIES:-}" ]]; then
  CATEGORIES="$(ui_pick_categories || true)"
fi
CATEGORIES="$(normalize_csv_to_commas "$CATEGORIES")"

if ! validate_selected_modules "$CATEGORIES"; then
  echo "Sélection de modules invalide. Utiliser --list-modules pour voir les modules disponibles." >&2
  exit 1
fi

OPTS="$AUDIT_ARG_OPTS"
if [[ -z "${OPTS:-}" ]]; then
  OPTS="$(ui_confirm_opts || true)"
fi
OPTS="$(normalize_csv_to_commas "$OPTS")"

OPTS_NO_UDP=0; OPTS_NO_ZEEK=0; OPTS_NO_SURICATA=0
[[ "$OPTS" == *"no-udp"* ]] && OPTS_NO_UDP=1
[[ "$OPTS" == *"no-zeek"* ]] && OPTS_NO_ZEEK=1
[[ "$OPTS" == *"no-suricata"* ]] && OPTS_NO_SURICATA=1

SELECTED="$(selected_modules_to_runner_args "$CATEGORIES")"

if [[ "$AUDIT_ARG_DRY_RUN" == "1" ]]; then
  print_dry_run_plan "$SELECTED"
  exit 0
fi

# Préflight dépendances requises
bin/check_deps.sh

# Détecter environnement
detect_env

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
run_modules "$SELECTED"

# Manifest de run + historique local + exports finaux
MANIFEST_PATH="$RUN_DIR/manifest.json"
write_manifest_json "$MANIFEST_PATH" "$SELECTED"
finalize_run_outputs "$MANIFEST_PATH"
history_record_run "$MANIFEST_PATH"

emit INFO "launcher" "Terminé. Dossier: $RUN_DIR"
echo "Audit terminé. Résultats: $RUN_DIR"
