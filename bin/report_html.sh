#!/usr/bin/env bash
# bin/report_html.sh
# @version 0.2.4
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

# shellcheck source=../core/lib_report_html.sh
source "core/lib_report_html.sh"

usage() {
  cat <<'EOF'
Usage: bin/report_html.sh [--private|--shareable|--technical] <manifest.json> [output.html]

Génère un rapport HTML local depuis un manifest AUDIT-SUITE.

Modes:
  --private     Rapport premium complet. Mode par défaut.
  --shareable   Copie premium avec identifiants directs et chemins masqués.
  --technical   Ancien relevé technique centré sur les modules.

Exemples:
  bash bin/report_html.sh output/AUDIT_1/manifest.json
  bash bin/report_html.sh --shareable output/AUDIT_1/manifest.json
  bash bin/report_html.sh --technical output/AUDIT_1/manifest.json
  bash bin/report_html.sh output/AUDIT_1/manifest.json output/AUDIT_1/report.html
EOF
}

mode="private"
technical=0

while (( $# > 0 )); do
  case "$1" in
    --private)
      mode="private"
      shift
      ;;
    --shareable)
      mode="shareable"
      shift
      ;;
    --technical)
      technical=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "Option inconnue: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      break
      ;;
  esac
done

if (( $# < 1 || $# > 2 )); then
  usage >&2
  exit 2
fi

manifest_path="$1"
output_path="${2:-}"

if (( technical == 1 )); then
  if [[ "$mode" == "shareable" ]]; then
    echo "--technical et --shareable ne peuvent pas être combinés." >&2
    exit 2
  fi
  report_html_generate_technical "$manifest_path" "$output_path"
else
  report_html_generate "$manifest_path" "$output_path" "$mode"
fi
