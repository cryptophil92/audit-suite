#!/usr/bin/env bash
# bin/finalize_reports.sh
# @version 0.2.6
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

# shellcheck source=../core/lib_report_html.sh
source "core/lib_report_html.sh"
# shellcheck source=../core/lib_report_pack.sh
source "core/lib_report_pack.sh"

usage() {
  cat <<'EOF'
Usage: bin/finalize_reports.sh <manifest.json>

Génère les sorties finales locales d'un run :
- report.html
- *_report_pack.tar.gz

La commande lit uniquement les fichiers locaux déjà générés.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if (( $# != 1 )); then
  usage >&2
  exit 2
fi

manifest_path="$1"
html_path=""
pack_path=""

html_path="$(report_html_generate "$manifest_path")"
pack_path="$(report_pack_build "$manifest_path")"

printf 'HTML_REPORT=%s\n' "$html_path"
printf 'REPORT_PACK=%s\n' "$pack_path"
