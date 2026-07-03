#!/usr/bin/env bash
# tests/test_version_json.sh
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

version_json="$(bash bin/version_json.sh)"

printf '%s\n' "$version_json" | jq -e '.kind == "audit-suite.version"' >/dev/null
printf '%s\n' "$version_json" | jq -e '.schema_version == "1.0.0"' >/dev/null
printf '%s\n' "$version_json" | jq -e '.version == "0.2.27"' >/dev/null

if bash bin/version_json.sh --unknown >/tmp/version-json.out 2>/tmp/version-json.err; then
  echo 'unknown option accepted' >&2
  exit 1
fi

grep -q 'Option inconnue' /tmp/version-json.err
rm -f /tmp/version-json.out /tmp/version-json.err

printf '[OK] version JSON tests passed\n'
