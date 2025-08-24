#!/usr/bin/env bash
set -Eeuo pipefail
shopt -s globstar nullglob
mapfile -t files < <(printf '%s\n' **/*.sh | grep -vE '^\.git/|^node_modules/|^\.?venv/')
(( ${#files[@]} )) || { echo "Aucun script .sh trouvé."; exit 0; }
command -v shellcheck >/dev/null 2>&1 || { echo "shellcheck absent. Lance scripts/install_deps.sh"; exit 2; }
shellcheck -x "${files[@]}"
echo "ShellCheck OK"
