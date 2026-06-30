#!/usr/bin/env bash
# core/lib_runner.sh
# @version 0.2.1
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

_module_results_file() {
  printf '%s\n' "${TMP_DIR:-tmp}/module_results.${RUN_ID:-unknown}.jsonl"
}

_append_module_result() {
  local module_id="$1"
  local module_name="$2"
  local module_path="$3"
  local status="$4"
  local rc="$5"
  local started_at="$6"
  local finished_at="$7"
  local duration_seconds="$8"
  local output_path="$9"
  local reason="${10:-}"
  local results_file

  results_file="$(_module_results_file)"
  mkdir -p "$(dirname -- "$results_file")"

  jq -n \
    --arg id "$module_id" \
    --arg name "$module_name" \
    --arg path "$module_path" \
    --arg status "$status" \
    --arg rc "$rc" \
    --arg started_at "$started_at" \
    --arg finished_at "$finished_at" \
    --arg duration_seconds "$duration_seconds" \
    --arg output_path "$output_path" \
    --arg reason "$reason" \
    '{
      id: $id,
      name: $name,
      path: $path,
      status: $status,
      rc: ($rc | tonumber),
      started_at: $started_at,
      finished_at: $finished_at,
      duration_seconds: ($duration_seconds | tonumber),
      output_path: $output_path,
      reason: $reason
    }' >> "$results_file"
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
  local results_file
  local -a list=()
  local -a raw_list=()
  local selected_norm raw_module module

  results_file="$(_module_results_file)"
  mkdir -p "$(dirname -- "$results_file")"
  : > "$results_file"

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

    local meta id name timeout requires_raw rc status reason
    local started_at finished_at start_ts end_ts duration output_path
    local -a requires=()

    if ! meta="$(_read_module_metadata "$module")"; then
      emit WARN "runner" "skip unreadable module metadata: $module"
      continue
    fi

    IFS=$'\t' read -r id name timeout requires_raw <<< "$meta"
    : "${id:=unknown_module}"
    : "${name:=Unknown}"
    : "${timeout:=1800}"

    output_path="$RUN_DIR/$id"

    if [[ -n "${requires_raw:-}" ]]; then
      read -r -a requires <<< "$requires_raw"
    fi

    emit INFO "$id" "start: $name"

    if ! _requirements_are_met "$id" "${requires[@]}"; then
      started_at="$(date -Is)"
      finished_at="$started_at"
      _append_module_result "$id" "$name" "$module" "skipped" "127" "$started_at" "$finished_at" "0" "$output_path" "missing dependency"
      continue
    fi

    started_at="$(date -Is)"
    start_ts="$(date +%s)"

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

    finished_at="$(date -Is)"
    end_ts="$(date +%s)"
    duration=$(( end_ts - start_ts ))

    if [[ $rc -eq 0 ]]; then
      status="success"
      reason=""
      emit INFO "$id" "success"
    else
      status="failed"
      reason="module returned rc=$rc"
      emit ERROR "$id" "failed rc=$rc"
    fi

    _append_module_result "$id" "$name" "$module" "$status" "$rc" "$started_at" "$finished_at" "$duration" "$output_path" "$reason"
  done
}

write_manifest_json() {
  local path="$1"; shift || true
  local selected="$1"; shift || true
  local now tmp_path results_file

  now="$(date -Is)"
  tmp_path="${path}.tmp"
  results_file="$(_module_results_file)"

  if ! command -v jq >/dev/null 2>&1; then
    emit ERROR "runner" "jq is required to write manifest.json"
    return 1
  fi

  jq -n \
    --arg run_id "$RUN_ID" \
    --arg created_at "$now" \
    --arg profile "$PROFILE" \
    --arg targets "$TARGETS" \
    --arg selected_modules "$selected" \
    --arg no_udp "${OPTS_NO_UDP:-0}" \
    --arg no_zeek "${OPTS_NO_ZEEK:-0}" \
    --arg no_suricata "${OPTS_NO_SURICATA:-0}" \
    --arg allow_public "${ALLOW_PUBLIC:-0}" \
    --slurpfile modules "$results_file" \
    '{
      run_id: $run_id,
      created_at: $created_at,
      profile: $profile,
      targets: ($targets | split(" ") | map(select(length > 0))),
      options: {
        no_udp: ($no_udp == "1"),
        no_zeek: ($no_zeek == "1"),
        no_suricata: ($no_suricata == "1"),
        allow_public: ($allow_public == "1")
      },
      selected_modules: ($selected_modules | split(" ") | map(select(length > 0))),
      modules: $modules
    }' > "$tmp_path"

  mv "$tmp_path" "$path"
}
