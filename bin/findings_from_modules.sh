#!/usr/bin/env bash
# bin/findings_from_modules.sh
# Build a validated findings[] file from local module outputs only.
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

# shellcheck source=../core/lib_findings_adapters.sh
source "core/lib_findings_adapters.sh"

usage() {
  cat <<'EOF'
Usage: bin/findings_from_modules.sh [options] <run-dir> <scope-target>

Options:
  --output <path>        Destination (default: <run-dir>/findings.json).
  --base <path>          Existing findings[] input to merge without modifying it.
  --collected-at <date>  Evidence timestamp (default: current local timestamp).
  -h, --help             Show this help.

The command reads local module outputs only. It never launches a scan.
EOF
}

output_path=""
base_path=""
collected_at=""

while (( $# > 0 )); do
  case "$1" in
    --output)
      [[ $# -ge 2 ]] || { usage >&2; exit 2; }
      output_path="$2"
      shift 2
      ;;
    --base)
      [[ $# -ge 2 ]] || { usage >&2; exit 2; }
      base_path="$2"
      shift 2
      ;;
    --collected-at)
      [[ $# -ge 2 ]] || { usage >&2; exit 2; }
      collected_at="$2"
      shift 2
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
      printf 'Unknown option: %s\n' "$1" >&2
      usage >&2
      exit 2
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

run_dir="$1"
scope_target="$2"
[[ -n "$output_path" ]] || output_path="$run_dir/findings.json"
[[ -n "$collected_at" ]] || collected_at="$(date -Is)"

findings_adapt_run \
  "$run_dir" \
  "$scope_target" \
  "$output_path" \
  "$collected_at" \
  "$base_path"

printf 'FINDINGS_PATH=%s\n' "$output_path"
printf 'FINDING_COUNT=%s\n' "$(jq 'length' "$output_path")"
