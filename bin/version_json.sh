#!/usr/bin/env bash
# bin/version_json.sh
# @version 0.2.27
set -Eeuo pipefail

VERSION="0.2.27"

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
  jq -n \
    --arg kind "audit-suite.version" \
    --arg schema_version "1.0.0" \
    --arg version "$VERSION" \
    '{kind: $kind, schema_version: $schema_version, version: $version}'
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
