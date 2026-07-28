#!/usr/bin/env bash
# Synchronize generated version consumers with the root VERSION file.
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
OPENAPI_FILE="$REPO_DIR/api/openapi.json"

# shellcheck source=../core/lib_version.sh
source "$REPO_DIR/core/lib_version.sh"

usage_sync_version() {
  cat <<'EOF'
Usage: bash bin/sync_version.sh [--check]

Without arguments, updates generated version consumers.
With --check, exits non-zero when a generated value differs from VERSION.
EOF
}

require_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    echo "jq is required to synchronize the OpenAPI version." >&2
    return 1
  fi
}

check_version_consistency() {
  local expected_version current_version

  expected_version="$(audit_suite_version)"
  current_version="$(jq -er '.info.version' "$OPENAPI_FILE")"

  if [[ "$current_version" != "$expected_version" ]]; then
    echo "OpenAPI version $current_version differs from VERSION $expected_version." >&2
    return 1
  fi

  printf 'OpenAPI version is synchronized: %s\n' "$expected_version"
}

sync_version_consumers() {
  local expected_version tmp_file

  expected_version="$(audit_suite_version)"
  tmp_file="$(mktemp)"

  if ! jq --arg version "$expected_version" \
    '.info.version = $version' "$OPENAPI_FILE" > "$tmp_file"; then
    rm -f "$tmp_file"
    return 1
  fi

  mv "$tmp_file" "$OPENAPI_FILE"

  printf 'OpenAPI version synchronized: %s\n' "$expected_version"
}

case "${1:-}" in
  "")
    require_jq
    sync_version_consumers
    ;;
  --check)
    require_jq
    check_version_consistency
    ;;
  -h|--help)
    usage_sync_version
    ;;
  *)
    echo "Unknown option: $1" >&2
    usage_sync_version >&2
    exit 2
    ;;
esac
