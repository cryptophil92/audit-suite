#!/usr/bin/env bash
# core/lib_update.sh
# @version 0.1.0
set -Eeuo pipefail

verify_integrity() {
  # Parcourt modules et compare sha256 s'ils sont listés dans etc/manifest.json
  [[ -f etc/manifest.json ]] || { echo "[]" > etc/manifest.json; }
  local ok=1
  while IFS= read -r path; do
    [[ -f "$path" ]] || continue
    local sum; sum="$(sha256sum "$path" | awk '{print $1}')"
    local recorded
    recorded="$(jq -r --arg p "$path" '.[] | select(.path==$p) | .sha256' etc/manifest.json 2>/dev/null || echo "")"
    if [[ -n "$recorded" && "$recorded" != "null" && "$recorded" != "$sum" ]]; then
      echo "Mismatch: $path (have=$sum, expected=$recorded)"
      ok=0
    fi
  done < <(ls -1 modules/*.sh 2>/dev/null)
  return $ok
}

list_modules_versions() {
  while IFS= read -r m; do
    local ver; ver="$(grep -m1 -E '^# *@version' "$m" | awk '{print $3}')" || true
    echo "$(basename "$m") ${ver:-0.0.0}"
  done < <(ls -1 modules/*.sh 2>/dev/null)
}
