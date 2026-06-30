#!/usr/bin/env bash
# core/lib_runner.sh
# @version 0.2.0
set -Eeuo pipefail

discover_modules_sorted() {
  [[ -d modules ]] || return 0
  find modules -maxdepth 1 -type f -name '*.sh' ! -name '*_TEMPLATE*' -print | sort -V
}

_normalize_module_path() {
  local module="$1"

  [[ -n "$module" ]] || return 1
  [[ "$module" == modules/* ]] || module="modules/$module"

  # N'accepte que les modules directs du dossier modules/.
  [[ "$module" =~ ^modules/[A-Za-z0-9_.-]+\.sh$ ]] || return 1

  printf '%s\n' "$module"
}

_read_module_metadata() {
  local module="$1"

  bash -c '
    set -Eeuo pipefail
    module="$1"

    # Fonctions de logging disponibles si un module les référence au chargement.
    # shellcheck source=/dev/null
    source "core/lib_logging.sh"

    # Lecture des métadonnées dans un shell enfant pour éviter de polluer le runner.
    # shellcheck source=/dev/null
    source "$module" >/dev/null

    : "${MOD_ID:=unknown_module}"
    : "${MOD_NAME:=Unknown}"
    : "${MOD_TIMEOUT:=1800}"

    if ! [[ "$MOD_TIMEOUT" =~ ^[0-9]+$ ]] || (( MOD_TIMEOUT < 1 || MOD_TIMEOUT > 86400 )); then
      MOD_TIMEOUT=1800
    fi

    printf "%s\t%s\t%s\t" "$MOD_ID" "$MOD_NAME" "$MOD_TIMEOUT"

    if declare -p MOD_REQUIRES >/dev/null 2>&1; then
      if declare -p MOD_REQUIRES 2>/dev/null | grep -q "declare -[aA]"; then
        printf "%s" "${MOD_REQUIRES[*]}"
      else
        printf "%s" "$MOD_REQUIRES"
      fi
    fi

    printf "\n"
  ' _ "$module"
}

_requirements_are_met() {
  local module_id="$1"
  shift || true

  local dep
  for dep in "$@"; do
    [[ -n "$dep" ]] || continue

    if ! [[ "$dep" =~ ^[A-Za-z0-9._+-]+$ ]]; then
      emit WARN "$module_id" "invalid dependency name: $dep -> skipping module"
      return 1
    fi

    if ! command -v "$dep" >/dev/null 2>&1; then
      emit WARN "$module_id" "missing dep: $dep -> skipping module"
      return 1
    fi
  done
}

run_modules() {
  local selected="${1:-}"
  local -a list=()
  local -a raw_list=()
  local selected_norm raw_module module

  if [[ -n "$selected" ]]; then
    selected_norm="${selected//,/ }"
    read -r -a raw_list <<< "$selected_norm"

    for raw_module in "${raw_list[@]}"; do
      if module="$(_normalize_module_path "$raw_module")"; then
        list+=("$module")
      else
        emit WARN "runner" "skip invalid module reference: $raw_module"
      fi
    done
  else
    mapfile -t list < <(discover_modules_sorted)
  fi

  for module in "${list[@]}"; do
    [[ -f "$module" ]] || { emit WARN "runner" "skip missing $module"; continue; }

    local meta id name timeout requires_raw rc
    local -a requires=()

    if ! meta="$(_read_module_metadata "$module")"; then
      emit WARN "runner" "skip unreadable module metadata: $module"
      continue
    fi

    IFS=$'\t' read -r id name timeout requires_raw <<< "$meta"
    : "${id:=unknown_module}"
    : "${name:=Unknown}"
    : "${timeout:=1800}"

    if [[ -n "${requires_raw:-}" ]]; then
      read -r -a requires <<< "$requires_raw"
    fi

    emit INFO "$id" "start: $name"

    if ! _requirements_are_met "$id" "${requires[@]}"; then
      continue
    fi

    # Exécution réelle dans un shell enfant. Le module est sourcé uniquement dans ce shell.
    set +e
    timeout "$timeout" bash -c '
      set -Eeuo pipefail
      module="$1"

      # shellcheck source=/dev/null
      source "core/lib_logging.sh"

      # shellcheck source=/dev/null
      source "$module"

      for fn in mod_pre mod_run mod_post; do
        if ! declare -F "$fn" >/dev/null 2>&1; then
          emit ERROR "runner" "missing function $fn in $module"
          exit 2
        fi
      done

      mod_pre
      mod_run
      mod_post
    ' _ "$module"
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
    echo "  \"options\": { \"no_udp\": $OPTS_NO_UDP, \"no_zeek\": $OPTS_NO_ZEEK, \"no_suricata\": $OPTS_NO_SURICATA, \"allow_public\": ${ALLOW_PUBLIC:-0} },"
    echo "  \"selected_modules\": \"$selected\""
    echo "}"
  } > "$path"
}
