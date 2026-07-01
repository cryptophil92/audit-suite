#!/usr/bin/env bash
# core/lib_run_paths.sh
# @version 0.2.12
set -Eeuo pipefail

run_output_path() {
  local run_id="$1"
  printf 'output/%s\n' "$run_id"
}

run_log_path() {
  local run_id="$1"
  printf 'logs/%s\n' "$run_id"
}

validate_run_paths_available() {
  local run_id="$1"
  local output_path log_path
  local conflict=0

  output_path="$(run_output_path "$run_id")"
  log_path="$(run_log_path "$run_id")"

  if [[ -e "$output_path" ]]; then
    echo "Chemin déjà existant: $output_path" >&2
    conflict=1
  fi

  if [[ -e "$log_path" ]]; then
    echo "Chemin déjà existant: $log_path" >&2
    conflict=1
  fi

  if (( conflict != 0 )); then
    echo "Identifiant déjà utilisé: $run_id" >&2
    echo "Choisir un autre --run-id." >&2
    return 1
  fi
}
