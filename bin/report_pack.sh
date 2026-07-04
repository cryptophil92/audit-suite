#!/usr/bin/env bash
# bin/report_pack.sh
# @version 0.2.5
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

# shellcheck source=../core/lib_report_pack.sh
source "core/lib_report_pack.sh"

usage() {
  cat <<'EOF'
Usage: bin/report_pack.sh <manifest.json> [archive.tar.gz]

Crée un pack local contenant le manifest, le rapport HTML si disponible,
les logs si disponibles et les résultats modules.

Exemples:
  bash bin/report_pack.sh output/RUN_1/manifest.json
  bash bin/report_pack.sh output/RUN_1/manifest.json output/RUN_1/RUN_1_report_pack.tar.gz
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

report_pack_build "$manifest_path" "$output_path"
