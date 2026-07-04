#!/usr/bin/env bash
# bin/compare_runs.sh
# @version 0.2.3
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

# shellcheck source=../core/lib_compare.sh
source "core/lib_compare.sh"

usage() {
  cat <<'EOF'
Usage: bin/compare_runs.sh [--json] <before_manifest.json> <after_manifest.json>

Compare deux manifests AUDIT-SUITE.

Options:
  --json     Sortie JSON complète.
  -h, --help Affiche cette aide.

Exemples:
  bash bin/compare_runs.sh output/AUDIT_1/manifest.json output/AUDIT_2/manifest.json
  bash bin/compare_runs.sh --json output/AUDIT_1/manifest.json output/AUDIT_2/manifest.json
EOF
}

format="text"

while (( $# > 0 )); do
  case "$1" in
    --json)
      format="json"
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
    *)
      break
      ;;
  esac
done

if (( $# != 2 )); then
  usage >&2
  exit 2
fi

before_manifest="$1"
after_manifest="$2"

case "$format" in
  json)
    compare_runs_json "$before_manifest" "$after_manifest"
    ;;
  text)
    compare_runs_text "$before_manifest" "$after_manifest"
    ;;
  *)
    echo "Format inconnu: $format" >&2
    exit 2
    ;;
esac
