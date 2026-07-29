#!/usr/bin/env bash
# bin/version_json.sh
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=../core/lib_version.sh
source "$REPO_DIR/core/lib_version.sh"

usage_version_json() {
  cat <<'EOF'
Usage: bash bin/version_json.sh

Options:
  -h, --help
EOF
}

require_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    echo "jq requis pour produire la version JSON." >&2
    return 1
  fi
}

emit_version_json() {
  local version commit

  version="$(audit_suite_version)"
  commit="$(audit_suite_commit)"

  jq -n \
    --arg kind "audit-suite.version" \
    --arg schema_version "1.0.0" \
    --arg version "$version" \
    --arg commit "$commit" \
    '{
      kind: $kind,
      schema_version: $schema_version,
      version: $version,
      commit: $commit
    }'
}

case "${1:-}" in
  -h|--help)
    usage_version_json
    exit 0
    ;;
  "")
    ;;
  *)
    echo "Option inconnue: $1" >&2
    usage_version_json >&2
    exit 2
    ;;
esac

require_jq
emit_version_json
