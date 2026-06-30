#!/usr/bin/env bash
# core/lib_update.sh
# @version 0.2.0
set -Eeuo pipefail

_list_module_files() {
  [[ -d modules ]] || return 0
  find modules -maxdepth 1 -type f -name '*.sh' ! -name '*_TEMPLATE*' -print | sort -V
}

verify_integrity() {
  # Parcourt modules et compare sha256 s'ils sont listés dans etc/manifest.json.
  local ok=0
  local path sum recorded

  mkdir -p etc
  [[ -f etc/manifest.json ]] || printf '[]\n' > etc/manifest.json

  while IFS= read -r path; do
    [[ -f "$path" ]] || continue

    sum="$(sha256sum "$path" | awk '{print $1}')"
    recorded="$(jq -r --arg p "$path" '.[] | select(.path==$p) | .sha256' etc/manifest.json 2>/dev/null || true)"

    if [[ -n "$recorded" && "$recorded" != "null" && "$recorded" != "$sum" ]]; then
      echo "Mismatch: $path (have=$sum, expected=$recorded)"
      ok=1
    fi
  done < <(_list_module_files)

  return "$ok"
}

list_modules_versions() {
  local module ver

  while IFS= read -r module; do
    ver="$(grep -m1 -E '^# *@version' "$module" | awk '{print $3}' || true)"
    echo "$(basename "$module") ${ver:-0.0.0}"
  done < <(_list_module_files)
}
