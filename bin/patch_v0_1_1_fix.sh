#!/usr/bin/env bash
set -euo pipefail

write() { mkdir -p "$(dirname "$1")"; cat > "$1"; chmod +x "$1" || true; }

# --- audit.sh (v0.1.1) ---
write "audit.sh" <<'EOS'
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
export TARGETS PROFILE RUN_DIR LOG_DIR LOG_FILE LOG_BUS OPTS_NO_UDP OPTS_NO_ZEEK OPTS_NO_SURICATA DEF_IFACE DEF_CIDR HAVE_X11 HAVE_TMUX

# Orchestration
discover_modules_sorted >"$TMP_DIR/modules.list"
SELECTED="$(printf '%s' "$CATEGORIES" | tr ',' ' ')"   # runner accepte espaces
run_modules "$SELECTED"

# Manifest de run
write_manifest_json "$RUN_DIR/manifest.json" "$SELECTED"

emit INFO "launcher" "Terminé. Dossier: $RUN_DIR"
echo "Audit terminé. Résultats: $RUN_DIR"
EOS

# --- core/lib_menu.sh (v0.1.1) ---
write "core/lib_menu.sh" <<'EOS'
#!/usr/bin/env bash
# core/lib_menu.sh
# @version 0.1.1
set -Eeuo pipefail

_has() { command -v "$1" >/dev/null 2>&1; }
_is_x11() { [[ -n "${DISPLAY:-}" ]]; }
use_zenity() { _has zenity && _is_x11; }
use_whiptail() { _has whiptail; }
use_fzf() { _has fzf; }

ui_pick_profile() {
  if use_zenity; then
    zenity --list --title="Profil d'audit" --column="Profil" fast full stealth
  elif use_whiptail; then
    local choice
    choice=$(whiptail --title "Profil d'audit" --menu "Choisir un profil" 15 60 3 \
      "fast" "Rapide" "full" "Complet" "stealth" "Discret" 3>&1 1>&2 2>&3) || return 1
    echo "$choice"
  elif use_fzf; then
    printf "fast\nfull\nstealth\n" | fzf --prompt="Profil> " --height=10
  else
    echo "fast"
  fi
}

ui_enter_targets() {
  if use_zenity; then
    zenity --entry --title="Cibles" --text="CIDR multiples séparés par des virgules" --entry-text="192.168.1.0/24"
  elif use_whiptail; then
    local t
    t=$(whiptail --inputbox "CIDR séparés par virgules" 10 70 "192.168.1.0/24" 3>&1 1>&2 2>&3) || return 1
    echo "$t"
  else
    echo "192.168.1.0/24"
  fi
}

ui_pick_categories() {
  local list
  list="$(printf "%s\n" modules/*.sh 2>/dev/null | sed 's#modules/##' | sort)"
  if use_whiptail; then
    local items=()
    while IFS= read -r m; do
      items+=("$m" "" ON)
    done <<< "$list"
    local out
    out=$(whiptail --checklist "Catégories d'audit" 20 80 10 "${items[@]}" 3>&1 1>&2 2>&3) || return 1
    # espaces -> virgules
    echo "$out" | tr -d '"' | tr ' ' ','
  elif use_zenity; then
    echo "$list" | tr '\n' ',' | sed 's/,$//'
  else
    echo "$list" | tr '\n' ',' | sed 's/,$//'
  fi
}

ui_confirm_opts() {
  if use_whiptail; then
    local out
    out=$(whiptail --checklist "Options" 15 70 5 \
      "no-udp" "Désactiver UDP" OFF \
      "no-zeek" "Désactiver Zeek" ON \
      "no-suricata" "Désactiver Suricata" ON 3>&1 1>&2 2>&3) || true
    echo "$out" | tr -d '"' | tr ' ' ','
  else
    echo "no-zeek,no-suricata"
  fi
}
EOS

# --- core/lib_runner.sh (v0.1.1) ---
write "core/lib_runner.sh" <<'EOS'
#!/usr/bin/env bash
# core/lib_runner.sh
# @version 0.1.1
set -Eeuo pipefail

discover_modules_sorted() {
  ls -1 modules/*.sh 2>/dev/null | sort -V
}

_get_var() {
  local var="$1"
  printf '%s' "${!var-}"
}

run_modules() {
  local selected="${1:-}"
  local -a list=()
  if [[ -n "$selected" ]]; then
    # accepte séparateurs espaces OU virgules
    # shellcheck disable=SC2206
    list=($selected)
    for i in "${!list[@]}"; do
      [[ "${list[$i]}" == modules/* ]] || list[$i]="modules/${list[$i]}"
    done
  else
    mapfile -t list < <(discover_modules_sorted)
  fi

  for m in "${list[@]}"; do
    [[ -f "$m" ]] || { emit WARN "runner" "skip missing $m"; continue; }
    # shellcheck disable=SC1090
    source "$m"
    local id name timeout
    id="$(_get_var MOD_ID)"; name="$(_get_var MOD_NAME)"; timeout="${MOD_TIMEOUT:-1800}"
    emit INFO "$id" "start: $name"
    if [[ "${#MOD_REQUIRES[@]:-0}" -gt 0 ]]; then
      for dep in "${MOD_REQUIRES[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
          emit WARN "$id" "missing dep: $dep -> skipping module"
          continue 2
        fi
      done
    fi
    set +e
    timeout "$timeout" bash -c 'mod_pre && mod_run && mod_post'
    rc=$?
    set -e
    if [[ $rc -eq 0 ]]; then
      emit INFO "$id" "success"
    else
      emit ERROR "$id" "failed rc=$rc"
    fi
  done
}

write_manifest_json() {
  local path="$1"; shift || true
  local selected="$1"; shift || true
  local now; now="$(date -Is)"
  {
    echo "{"
    echo "  \"run_id\": \"$RUN_ID\","
    echo "  \"created_at\": \"$now\","
    echo "  \"profile\": \"$PROFILE\","
    echo "  \"targets\": \"$TARGETS\","
    echo "  \"options\": { \"no_udp\": $OPTS_NO_UDP, \"no_zeek\": $OPTS_NO_ZEEK, \"no_suricata\": $OPTS_NO_SURICATA },"
    echo "  \"selected_modules\": \"$selected\""
    echo "}"
  } > "$path"
}
EOS

echo "[OK] patch v0.1.1 (files restored) applied."
