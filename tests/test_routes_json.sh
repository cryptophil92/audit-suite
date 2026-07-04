#!/usr/bin/env bash
# tests/test_routes_json.sh
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

routes_json="$(bash bin/routes_json.sh)"

printf '%s\n' "$routes_json" | jq -e '.kind == "audit-suite.routes"' >/dev/null
printf '%s\n' "$routes_json" | jq -e '.schema_version == "1.0.0"' >/dev/null
printf '%s\n' "$routes_json" | jq -e '.routes | length >= 10' >/dev/null
printf '%s\n' "$routes_json" | jq -e '.routes[] | select(.path == "/api/routes")' >/dev/null
printf '%s\n' "$routes_json" | jq -e '.routes[] | select(.path == "/api/plan" and (.requires_query[] == "targets"))' >/dev/null

if bash bin/routes_json.sh --unknown >/tmp/routes-json.out 2>/tmp/routes-json.err; then
  echo 'unknown option accepted' >&2
  exit 1
fi

grep -q 'Option inconnue' /tmp/routes-json.err
rm -f /tmp/routes-json.out /tmp/routes-json.err

printf '[OK] routes JSON tests passed\n'
