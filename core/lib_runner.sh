#!/usr/bin/env bash
# core/lib_runner.sh
# @version 0.3.0
set -Eeuo pipefail

MANIFEST_SCHEMA_VERSION="1.2.0"

# shellcheck source=lib_version.sh
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib_version.sh"
# shellcheck source=lib_findings.sh
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib_findings.sh"
# shellcheck source=lib_modules.sh
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib_modules.sh"

discover_modules_sorted() {
  modules_selectable_paths
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
    : "${MOD_SKIP_OPTION:=-}"
    : "${MOD_SELECTABLE:=1}"
    : "${MOD_MATURITY:=experimental}"
    : "${MOD_LIMITATIONS:=}"

    if ! [[ "$MOD_TIMEOUT" =~ ^[0-9]+$ ]] || (( MOD_TIMEOUT < 1 || MOD_TIMEOUT > 86400 )); then
      MOD_TIMEOUT=1800
    fi

    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t" \
      "$MOD_ID" "$MOD_NAME" "$MOD_TIMEOUT" "$MOD_SKIP_OPTION" \
      "$MOD_SELECTABLE" "$MOD_MATURITY" "$MOD_LIMITATIONS"

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
  local module_index=0

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

    local meta id name timeout skip_option selectable maturity limitations
    local requires_raw rc status reason
    local started_at finished_at start_ts end_ts duration output_path
    local outcome_file outcome_status outcome_reason
    local -a requires=()

    ((module_index += 1))

    if ! meta="$(_read_module_metadata "$module")"; then
      emit WARN "runner" "skip unreadable module metadata: $module"
      continue
    fi

    IFS=$'\t' read -r id name timeout skip_option selectable maturity limitations requires_raw <<< "$meta"
    : "${id:=unknown_module}"
    : "${name:=Unknown}"
    : "${timeout:=1800}"
    : "${skip_option:=-}"
    : "${selectable:=1}"
    : "${maturity:=experimental}"

    output_path="$RUN_DIR/$id"
    outcome_file="${TMP_DIR:-tmp}/module_outcome.${RUN_ID:-unknown}.${module_index}"
    rm -f -- "$outcome_file"

    if [[ -n "${requires_raw:-}" ]]; then
      read -r -a requires <<< "$requires_raw"
    fi

    emit INFO "$id" "start: $name"

    if [[ "$selectable" != "1" ]]; then
      started_at="$(date -Is)"
      finished_at="$started_at"
      reason="module not selectable (maturity: $maturity)"
      [[ -n "$limitations" ]] && reason="$reason: $limitations"
      emit WARN "$id" "skipped: $reason"
      _append_module_result "$id" "$name" "$module" "skipped" "0" "$started_at" "$finished_at" "0" "$output_path" "$reason"
      continue
    fi

    if [[ "$skip_option" != "-" ]]; then
      if ! [[ "$skip_option" =~ ^[A-Z][A-Z0-9_]*$ ]]; then
        emit WARN "$id" "invalid skip option metadata: $skip_option"
      elif [[ "${!skip_option:-0}" == "1" ]]; then
        started_at="$(date -Is)"
        finished_at="$started_at"
        reason="disabled by option $skip_option"
        emit INFO "$id" "skipped: $reason"
        _append_module_result "$id" "$name" "$module" "skipped" "0" "$started_at" "$finished_at" "0" "$output_path" "$reason"
        continue
      fi
    fi

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
      MODULE_OUTCOME_FILE="$2"
      export MODULE_OUTCOME_FILE

      module_mark_partial() {
        local reason="${*:-optional step failed}"
        reason="${reason//$'\''\n'\''/ }"
        reason="${reason//$'\''\t'\''/ }"
        if [[ ! -s "$MODULE_OUTCOME_FILE" ]]; then
          printf "partial\t%s\n" "$reason" > "$MODULE_OUTCOME_FILE"
        fi
      }

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
    ' _ "$module" "$outcome_file"
    rc=$?
    set -e

    finished_at="$(date -Is)"
    end_ts="$(date +%s)"
    duration=$(( end_ts - start_ts ))

    outcome_status=""
    outcome_reason=""
    if [[ -s "$outcome_file" ]]; then
      IFS=$'\t' read -r outcome_status outcome_reason < "$outcome_file" || true
    fi
    rm -f -- "$outcome_file"

    if [[ $rc -eq 0 && "$outcome_status" == "partial" ]]; then
      status="partial"
      reason="${outcome_reason:-optional step failed}"
      emit WARN "$id" "partial: $reason"
    elif [[ $rc -eq 0 && -z "$outcome_status" ]]; then
      status="success"
      reason=""
      emit INFO "$id" "success"
    else
      status="failed"
      if [[ $rc -eq 124 ]]; then
        reason="module timed out after ${timeout}s"
      elif [[ $rc -eq 0 ]]; then
        reason="invalid module outcome: $outcome_status"
        rc=2
      else
        reason="module returned rc=$rc"
      fi
      emit ERROR "$id" "failed rc=$rc"
    fi

    _append_module_result "$id" "$name" "$module" "$status" "$rc" "$started_at" "$finished_at" "$duration" "$output_path" "$reason"
  done
}

write_manifest_json() {
  local path="$1"; shift || true
  local selected="$1"; shift || true
  local now tmp_path results_file application_version application_commit
  local findings_path findings_tmp_path

  now="$(date -Is)"
  application_version="$(audit_suite_version)"
  application_commit="$(audit_suite_commit)"
  tmp_path="${path}.tmp"
  findings_tmp_path="${tmp_path}.findings"
  results_file="$(_module_results_file)"
  findings_path="${AUDIT_FINDINGS_FILE:-${RUN_DIR}/findings.json}"
  mkdir -p "$(dirname -- "$results_file")"
  touch "$results_file"

  if ! command -v jq >/dev/null 2>&1; then
    emit ERROR "runner" "jq is required to write manifest.json"
    return 1
  fi

  if ! findings_prepare_array_file "$findings_path" "$findings_tmp_path"; then
    emit ERROR "runner" "invalid findings input: $findings_path"
    return 1
  fi

  if ! jq -n \
    --arg schema_version "$MANIFEST_SCHEMA_VERSION" \
    --arg findings_schema_version "$FINDINGS_SCHEMA_VERSION" \
    --arg version "$application_version" \
    --arg commit "$application_commit" \
    --arg run_id "$RUN_ID" \
    --arg created_at "$now" \
    --arg profile "$PROFILE" \
    --arg targets "$TARGETS" \
    --arg selected_modules "$selected" \
    --arg no_udp "${OPTS_NO_UDP:-0}" \
    --arg no_zeek "${OPTS_NO_ZEEK:-0}" \
    --arg no_suricata "${OPTS_NO_SURICATA:-0}" \
    --arg allow_public "${ALLOW_PUBLIC:-0}" \
    --arg output_path "$RUN_DIR" \
    --arg log_path "$LOG_DIR" \
    --arg manifest_path "$path" \
    --slurpfile findings_document "$findings_tmp_path" \
    --slurpfile modules "$results_file" \
    '($findings_document[0] // []) as $findings
    | {
      schema_version: $schema_version,
      kind: "audit-suite.manifest",
      findings_schema_version: $findings_schema_version,
      version: $version,
      commit: $commit,
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
      paths: {
        output: $output_path,
        logs: $log_path,
        manifest: $manifest_path
      },
      selected_modules: ($selected_modules | split(" ") | map(select(length > 0))),
      summary: {
        module_count: ($modules | length),
        success_count: ([$modules[]? | select(.status == "success")] | length),
        partial_count: ([$modules[]? | select(.status == "partial")] | length),
        failed_count: ([$modules[]? | select(.status == "failed")] | length),
        skipped_count: ([$modules[]? | select(.status == "skipped")] | length),
        total_duration_seconds: ([$modules[]?.duration_seconds] | add // 0),
        status: (
          if ([$modules[]? | select(.status == "failed")] | length) > 0 then "failed"
          elif ([$modules[]? | select(.status == "partial")] | length) > 0 then "partial"
          elif ([$modules[]? | select(.status == "success")] | length) > 0 then "success"
          else "empty"
          end
        ),
        findings: {
          total_count: ($findings | length),
          scored_count: ([$findings[]? | select(.scoring.status == "scored")] | length),
          unscored_count: ([$findings[]? | select(.scoring.status == "unscored")] | length),
          by_severity: {
            informational: ([$findings[]? | select(.severity == "informational")] | length),
            low: ([$findings[]? | select(.severity == "low")] | length),
            medium: ([$findings[]? | select(.severity == "medium")] | length),
            high: ([$findings[]? | select(.severity == "high")] | length),
            critical: ([$findings[]? | select(.severity == "critical")] | length),
            unknown: ([$findings[]? | select(.severity == "unknown")] | length)
          },
          by_confidence: {
            low: ([$findings[]? | select(.confidence == "low")] | length),
            medium: ([$findings[]? | select(.confidence == "medium")] | length),
            high: ([$findings[]? | select(.confidence == "high")] | length)
          }
        }
      },
      modules: $modules,
      findings: $findings
    }' > "$tmp_path"; then
    rm -f -- "$findings_tmp_path" "$tmp_path"
    emit ERROR "runner" "cannot generate manifest JSON"
    return 1
  fi

  rm -f -- "$findings_tmp_path"

  if ! findings_validate_manifest_file "$tmp_path"; then
    rm -f -- "$tmp_path"
    emit ERROR "runner" "generated manifest failed validation"
    return 1
  fi

  mv "$tmp_path" "$path"
}
