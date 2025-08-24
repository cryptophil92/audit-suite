#!/usr/bin/env bash
# bin/update_modules.sh
# @version 0.1.0
set -Eeuo pipefail

manifest="etc/manifest.json"
[[ -f "$manifest" ]] || echo "[]" > "$manifest"

echo "Collez les blocs entre BEGIN MODULE <path> / END MODULE, puis Ctrl-D."

buffer=""
path=""
while IFS= read -r line; do
  if [[ "$line" =~ ^BEGIN\ MODULE\ (.+)$ ]]; then
    path="${BASH_REMATCH[1]}"
    buffer=""
  elif [[ "$line" =~ ^END\ MODULE ]]; then
    if [[ -z "$path" ]]; then
      echo "Bloc sans chemin, ignoré."
      continue
    fi
    mkdir -p "$(dirname "$path")"
    printf "%s" "$buffer" > "$path"
    sum="$(sha256sum "$path" | awk '{print $1}')"
    ver="$(grep -m1 -E '^# *@version' "$path" | awk '{print $3}')"
    # MAJ manifest
    tmp="$(mktemp)"; jq --arg p "$path" 'map(select(.path!=$p))' "$manifest" > "$tmp" || echo "[]" > "$tmp"
    mv "$tmp" "$manifest"
    jq --arg p "$path" --arg s "$sum" --arg v "${ver:-0.0.0}" '. + [{path:$p,sha256:$s,version:$v,updated_at:now|todateiso8601}]' "$manifest" > "$tmp" && mv "$tmp" "$manifest"
    echo "[OK] Écrit: $path (sha256=$sum, version=${ver:-0.0.0})"
    path=""; buffer=""
  else
    buffer+="${line}\n"
  fi
done

echo "Terminé."
