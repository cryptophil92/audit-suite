#!/usr/bin/env bash
# bin/routes_json.sh
# @version 0.2.29
set -Eeuo pipefail

usage_routes_json() {
  cat <<'EOF'
Usage: bash bin/routes_json.sh

Options:
  -h, --help
EOF
}

require_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    echo "jq requis pour produire les routes JSON." >&2
    return 1
  fi
}

emit_routes_json() {
  jq -n \
    --arg kind "audit-suite.routes" \
    --arg schema_version "1.0.0" \
    '{
      kind: $kind,
      schema_version: $schema_version,
      routes: [
        {method: "GET", path: "/", type: "html"},
        {method: "GET", path: "/index.html", type: "html"},
        {method: "GET", path: "/api/health", type: "json"},
        {method: "GET", path: "/api/status", type: "json"},
        {method: "GET", path: "/api/modules", type: "json"},
        {method: "GET", path: "/api/history", type: "json"},
        {method: "GET", path: "/api/latest", type: "json"},
        {method: "GET", path: "/api/snapshot", type: "json"},
        {method: "GET", path: "/api/plan", type: "json", requires_query: ["targets"]},
        {method: "GET", path: "/api/openapi.json", type: "json"},
        {method: "GET", path: "/api/routes", type: "json"}
      ]
    }'
}

case "${1:-}" in
  -h|--help)
    usage_routes_json
    exit 0
    ;;
  "")
    ;;
  *)
    echo "Option inconnue: $1" >&2
    usage_routes_json >&2
    exit 2
    ;;
esac

require_jq
emit_routes_json
