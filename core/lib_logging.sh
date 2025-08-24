#!/usr/bin/env bash
# shellcheck shell=bash
# vim: set ts=2 sw=2 et:
#
# core/lib_logging.sh — mini-lib de logging Bash
#
# Fonctions exposées :
#   - init_logging RUN_ID
#   - emit LEVEL MODULE MSG...
#   - with_log MODULE CMD...
#
# Caractéristiques :
#   - Crée logs/$RUN_ID/, tmp/, files: combined.log (TXT), events.jsonl
#   - Crée un FIFO tmp/eventbus.$RUN_ID (ignoré s'il existe déjà en tant que FIFO)
#   - Ecriture TXT + JSONL (fallback JSON si jq absent)
#   - Push non bloquant vers FIFO si ouvert (ouverture RDWR interne)
#   - Idempotent, quoting sûr, erreurs claires
#   - Compat POSIX raisonnable (Bash requis)
#
# Variables d'environnement optionnelles :
#   LOG_ROOT_DIR (defaut: logs)
#   TMP_ROOT_DIR (defaut: tmp)
#   LOG_TEE=1       -> with_log duplique vers stdout/stderr
#   LOG_TRUNCATE=1  -> tronque les fichiers logs à l'init (sinon append)
#
set -Eeuo pipefail

# --- Etat interne ---
LOG_RUN_ID=""
LOG_ROOT_DIR="${LOG_ROOT_DIR:-logs}"
TMP_ROOT_DIR="${TMP_ROOT_DIR:-tmp}"
LOG_DIR=""
LOG_FILE=""
EVENTS_FILE=""
EVENTBUS_PATH=""
LOG_EVENTBUS_FD=""

# --- Utilitaires internes ---

_ts_iso() {
  # ISO-8601 UTC (secondes)
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

_require_inited() {
  if [[ -z "${LOG_DIR:-}" || -z "${LOG_FILE:-}" || -z "${EVENTS_FILE:-}" ]]; then
    printf 'ERROR: logging not initialized. Call init_logging RUN_ID first.\n' >&2
    return 1
  fi
}

# Echappement JSON minimal (fallback sans jq)
_json_escape() {
  # Entrée via stdin, sortie: chaîne échappée (sans guillemets)
  sed -e 's/\\/\\\\/g' \
      -e 's/"/\\"/g' \
      -e 's/\r/\\r/g' \
      -e 's/\t/\\t/g' \
      -e ':a;N;$!ba;s/\n/\\n/g'
}

_build_json_line() {
  # Args: ts level module msg
  local ts="$1" level="$2" module="$3" msg="$4"

  if command -v jq >/dev/null 2>&1; then
    jq -Rn \
      --arg ts "$ts" \
      --arg run_id "$LOG_RUN_ID" \
      --arg level "$level" \
      --arg module "$module" \
      --arg msg "$msg" \
      '{ts:$ts, run_id:$run_id, level:$level, module:$module, msg:$msg}'
  else
    # Fallback sans jq : utiliser process substitution pour éviter le sous-shell qui perd les variables
    local ts_e run_e lvl_e mod_e msg_e
    IFS= read -r ts_e  < <(printf '%s' "$ts"         | _json_escape)
    IFS= read -r run_e < <(printf '%s' "$LOG_RUN_ID" | _json_escape)
    IFS= read -r lvl_e < <(printf '%s' "$level"      | _json_escape)
    IFS= read -r mod_e < <(printf '%s' "$module"     | _json_escape)
    IFS= read -r msg_e < <(printf '%s' "$msg"        | _json_escape)
    printf '{"ts":"%s","run_id":"%s","level":"%s","module":"%s","msg":"%s"}\n' \
      "$ts_e" "$run_e" "$lvl_e" "$mod_e" "$msg_e"
  fi
}

_eventbus_write() {
  # Ecrit $1 (ligne) vers le FIFO si ouvert. Non-bloquant via FD RDWR.
  local line="$1"
  if [[ -n "${LOG_EVENTBUS_FD:-}" ]]; then
    # redirection vers FD dynamique
    printf '%s\n' "$line" >&"${LOG_EVENTBUS_FD}" || true
  fi
}

_prefix_pipe() {
  # Args: module stream_tag
  # Lit stdin, préfixe timestamp/stream/module et écrit une ligne formatée
  local module="$1" stream="$2"
  local line
  while IFS= read -r line; do
    printf '%s [%s] %s | %s\n' "$(_ts_iso)" "$stream" "$module" "$line"
  done
}

# --- API publique ---

init_logging() {
  # init_logging RUN_ID
  if [[ $# -ne 1 ]]; then
    printf 'ERROR: init_logging expects 1 arg: RUN_ID\n' >&2
    return 2
  fi
  local run_id="$1"

  LOG_RUN_ID="$run_id"
  LOG_DIR="${LOG_ROOT_DIR%/}/$LOG_RUN_ID"
  LOG_FILE="$LOG_DIR/combined.log"
  EVENTS_FILE="$LOG_DIR/events.jsonl"
  EVENTBUS_PATH="${TMP_ROOT_DIR%/}/eventbus.$LOG_RUN_ID"

  # Dossiers
  mkdir -p "$LOG_DIR" "$TMP_ROOT_DIR"

  # Fichiers idempotents (non destructif par défaut)
  umask 077
  if [[ "${LOG_TRUNCATE:-0}" = "1" ]]; then
    : >"$LOG_FILE"    || { printf 'ERROR: cannot write %s\n' "$LOG_FILE" >&2; return 3; }
    : >"$EVENTS_FILE" || { printf 'ERROR: cannot write %s\n' "$EVENTS_FILE" >&2; return 3; }
  else
    touch "$LOG_FILE" "$EVENTS_FILE" \
      || { printf 'ERROR: cannot touch log files in %s\n' "$LOG_DIR" >&2; return 3; }
  fi
  chmod 600 "$LOG_FILE" "$EVENTS_FILE" 2>/dev/null || true

  # FIFO idempotent (permission stricte)
  if [[ -e "$EVENTBUS_PATH" && ! -p "$EVENTBUS_PATH" ]]; then
    printf 'ERROR: %s exists and is not a FIFO\n' "$EVENTBUS_PATH" >&2
    return 4
  fi
  if [[ ! -p "$EVENTBUS_PATH" ]]; then
    umask 077
    mkfifo "$EVENTBUS_PATH"
  fi

  # Ouvrir le FIFO en RDWR pour éviter le blocage si aucun lecteur
  if [[ -z "${LOG_EVENTBUS_FD:-}" ]]; then
    # FD nommé (Bash)
    exec {LOG_EVENTBUS_FD}<>"$EVENTBUS_PATH" 2>/dev/null || true
  fi

  # Trace d'init
  local ts; ts="$(_ts_iso)"
  printf '%s [INFO] logging | initialized run_id=%s\n' "$ts" "$LOG_RUN_ID" >>"$LOG_FILE"
  _build_json_line "$ts" "INFO" "logging" "initialized run_id=$LOG_RUN_ID" >>"$EVENTS_FILE"
}

emit() {
  # emit LEVEL MODULE MSG...
  _require_inited || return $?
  if [[ $# -lt 3 ]]; then
    printf 'ERROR: emit expects LEVEL MODULE MSG...\n' >&2
    return 2
  fi
  local level="$1" module="$2"; shift 2
  local msg="$*"
  local ts; ts="$(_ts_iso)"

  # TXT
  printf '%s [%s] %s - %s\n' "$ts" "$level" "$module" "$msg" >>"$LOG_FILE"

  # JSONL
  local json
  json="$(_build_json_line "$ts" "$level" "$module" "$msg")"
  printf '%s\n' "$json" >>"$EVENTS_FILE"

  # Eventbus (non-bloquant)
  _eventbus_write "$json"
}

with_log() {
  # with_log MODULE CMD...
  _require_inited || return $?
  if [[ $# -lt 2 ]]; then
    printf 'ERROR: with_log expects MODULE CMD...\n' >&2
    return 2
  fi
  local module="$1"; shift
  local cmd_desc; cmd_desc="$*"

  emit "INFO" "$module" "BEGIN: $cmd_desc"

  # Option de duplication vers stdout/stderr si LOG_TEE=1
  if [[ "${LOG_TEE:-0}" = "1" ]]; then
    # Sauver les FD d'origine
    exec 3>&1 4>&2
    # shellcheck disable=SC2094
    "$@" \
      > >(
          tee /dev/fd/3 \
          | _prefix_pipe "$module" "STDOUT" \
          >>"$LOG_FILE"
        ) \
      2> >(
          tee /dev/fd/4 \
          | _prefix_pipe "$module" "STDERR" \
          >>"$LOG_FILE"
        )
    local rc=$?
    exec 3>&- 4>&-
  else
    # Logging silencieux uniquement vers combined.log
    # shellcheck disable=SC2094
    "$@" \
      > >(
          _prefix_pipe "$module" "STDOUT" \
          >>"$LOG_FILE"
        ) \
      2> >(
          _prefix_pipe "$module" "STDERR" \
          >>"$LOG_FILE"
        )
    local rc=$?
  fi

  if (( rc == 0 )); then
    emit "INFO" "$module" "END rc=0: $cmd_desc"
  else
    emit "ERROR" "$module" "END rc=$rc: $cmd_desc"
  fi
  return "$rc"
}

# --- Fin de la lib ---
# Cette lib est conçue pour être "sourcée".
# Si exécutée directement, on lance un mini self-test non intrusif.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set +e
  run="SELFTEST_$(date -u +%Y%m%dT%H%M%SZ)"
  init_logging "$run"
  emit INFO selftest "hello world"
  with_log demo bash -c 'echo out; echo err 1>&2'
  ! with_log demo-fail bash -c 'echo will-fail; echo err 1>&2; exit 3'
  printf 'Self-test done. See %s\n' "$LOG_DIR" >&2
fi

: <<'__DOC_TESTS__'
# ======================================================================
# Tests unitaires bash simples (exemples d’utilisation)
#
#   # 1) Charger la lib, initialiser
#   source core/lib_logging.sh
#   init_logging "TEST_$RANDOM"
#
#   # 2) Emit de base
#   emit INFO core "Démarrage OK"
#   emit WARN core "Espace disque faible"
#   emit ERROR net "Connexion KO 192.168.1.10"
#
#   # 3) with_log : capture stdout/err vers combined.log
#   with_log ls-run ls -la /tmp
#   with_log bad-run bash -c 'echo OOPS 1>&2; exit 2' || test "$?" -eq 2
#
#   # 4) Vérifications rapides
#   test -s "$LOG_FILE" || { echo "combined.log vide"; exit 1; }
#   test -s "$EVENTS_FILE" || { echo "events.jsonl vide"; exit 1; }
#   grep -q 'Démarrage OK' "$LOG_FILE"
#   grep -q '"level":"ERROR"' "$EVENTS_FILE"
#
#   # 5) FIFO: écouter le bus d'événements dans un autre terminal
#   #   cat tmp/eventbus.$RUN_ID
#   #   emit INFO demo "Ping eventbus"
#
#   echo "Tests simples OK"
# ======================================================================
__DOC_TESTS__
