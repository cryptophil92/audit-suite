#!/usr/bin/env bash
# core/lib_modules.sh
# @version 0.3.0
set -Eeuo pipefail

modules_discover_sorted() {
  [[ -d modules ]] || return 0
  find modules -maxdepth 1 -type f -name '*.sh' ! -name '*_TEMPLATE*' -print | sort -V
}

module_name_from_token() {
  local token="$1"
  token="${token#modules/}"
  printf '%s\n' "$token"
}

module_path_from_name() {
  local name="$1"
  name="$(module_name_from_token "$name")"
  printf 'modules/%s\n' "$name"
}

module_exists() {
  local name="$1"
  local path

  path="$(module_path_from_name "$name")"
  [[ -f "$path" && "$path" == modules/*.sh && "$path" != *'_TEMPLATE'* ]]
}

module_selection_metadata() {
  local name="$1"
  local path

  path="$(module_path_from_name "$name")"
  module_exists "$name" || return 1

  bash -c '
    set -Eeuo pipefail
    module="$1"

    # shellcheck source=/dev/null
    source "core/lib_logging.sh"
    # shellcheck source=/dev/null
    source "$module" >/dev/null

    : "${MOD_SELECTABLE:=1}"
    : "${MOD_MATURITY:=experimental}"
    : "${MOD_LIMITATIONS:=}"

    case "$MOD_SELECTABLE" in
      0|1) ;;
      *) MOD_SELECTABLE=0 ;;
    esac

    printf "%s|%s|%s\n" "$MOD_SELECTABLE" "$MOD_MATURITY" "$MOD_LIMITATIONS"
  ' _ "$path"
}

module_is_selectable() {
  local name="$1"
  local metadata selectable maturity limitations

  metadata="$(module_selection_metadata "$name")" || return 1
  IFS='|' read -r selectable maturity limitations <<< "$metadata"
  [[ "$selectable" == "1" ]]
}

modules_selectable_paths() {
  local module

  while IFS= read -r module; do
    [[ -n "$module" ]] || continue
    if module_is_selectable "$module"; then
      printf '%s\n' "$module"
    fi
  done < <(modules_discover_sorted)
}

modules_all_names() {
  local module
  local names=()

  while IFS= read -r module; do
    [[ -z "$module" ]] && continue
    names+=("$(module_name_from_token "$module")")
  done < <(modules_selectable_paths)

  printf '%s\n' "${names[*]}"
}

selection_is_all_modules() {
  local selected_csv="$1"
  selected_csv="$(normalize_csv_to_commas "$selected_csv")"
  [[ "$selected_csv" == "all" ]]
}

validate_selected_modules() {
  local selected_csv="$1"
  local token name metadata selectable maturity limitations missing=0

  selected_csv="$(normalize_csv_to_commas "$selected_csv")"

  if [[ -z "$selected_csv" ]]; then
    echo "Aucun module sélectionné." >&2
    return 1
  fi

  if selection_is_all_modules "$selected_csv"; then
    if [[ -z "$(modules_all_names)" ]]; then
      echo "Aucun module disponible." >&2
      return 1
    fi
    return 0
  fi

  IFS=',' read -r -a _selected_modules <<< "$selected_csv"
  for token in "${_selected_modules[@]}"; do
    [[ -z "$token" ]] && continue
    name="$(module_name_from_token "$token")"
    if ! module_exists "$name"; then
      echo "Module inconnu ou indisponible: $name" >&2
      missing=1
    elif ! module_is_selectable "$name"; then
      metadata="$(module_selection_metadata "$name" || true)"
      IFS='|' read -r selectable maturity limitations <<< "$metadata"
      printf 'Module non sélectionnable: %s (maturité: %s). %s\n' \
        "$name" "${maturity:-inconnue}" "${limitations:-Consultez le catalogue des modules.}" >&2
      missing=1
    fi
  done

  (( missing == 0 ))
}

selected_modules_to_runner_args() {
  local selected_csv="$1"
  local token name
  local modules=()

  selected_csv="$(normalize_csv_to_commas "$selected_csv")"

  if selection_is_all_modules "$selected_csv"; then
    modules_all_names
    return 0
  fi

  IFS=',' read -r -a _selected_modules <<< "$selected_csv"

  for token in "${_selected_modules[@]}"; do
    [[ -z "$token" ]] && continue
    name="$(module_name_from_token "$token")"
    modules+=("$name")
  done

  printf '%s\n' "${modules[*]}"
}
