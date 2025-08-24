#!/usr/bin/env bash
set -Eeuo pipefail
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
"$HERE/init_arbo.sh"
"$HERE/apply_gitignore.sh"
"$HERE/write_install_deps.sh"
"$HERE/wire_audit.sh" "${1:-}"
if [[ "${DO_COMMIT:-0}" == "1" ]]; then
  ROOT="$(cd -- "$HERE/.." && pwd)"
  cd "$ROOT"
  git add .gitignore audit.sh scripts/install_deps.sh core/lib_logging.sh tools 2>/dev/null || true
  git diff --cached --quiet || { git commit -m "chore: sync structure + deps + logging preamble"; echo "Commit créé."; }
fi
echo "Mise à jour projet terminée."
