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
Usage: bin/report_html.sh <manifest.json> [output.html]

Génère un rapport HTML local depuis un manifest AUDIT-SUITE.

Exemples:
  bash bin/report_html.sh output/AUDIT_1/manifest.json
  bash bin/report_html.sh output/AUDIT_1/manifest.json output/AUDIT_1/report.html
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if (( $# < 1 || $# > 2 )); then
  usage >&2
  exit 2
fi

manifest_path="$1"
output_path="${2:-}"

report_html_generate "$manifest_path" "$output_path"
