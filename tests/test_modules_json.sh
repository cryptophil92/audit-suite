#!/usr/bin/env bash
# tests/test_modules_json.sh
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

catalog_json="$(bash bin/modules_json.sh)"

printf '%s\n' "$catalog_json" | jq -e '.kind == "audit-suite.modules"' >/dev/null
printf '%s\n' "$catalog_json" | jq -e '.schema_version == "1.0.0"' >/dev/null
printf '%s\n' "$catalog_json" | jq -e '.count > 0' >/dev/null
printf '%s\n' "$catalog_json" | jq -e '.modules | type == "array"' >/dev/null
printf '%s\n' "$catalog_json" | jq -e '.count == (.modules | length)' >/dev/null
printf '%s\n' "$catalog_json" | jq -e 'all(.modules[]; (.id | type == "string"))' >/dev/null
printf '%s\n' "$catalog_json" | jq -e 'all(.modules[]; (.name | type == "string" and endswith(".sh")))' >/dev/null
printf '%s\n' "$catalog_json" | jq -e 'all(.modules[]; (.path | type == "string" and startswith("modules/")))' >/dev/null
printf '%s\n' "$catalog_json" | jq -e 'all(.modules[]; (.order | type == "number"))' >/dev/null
printf '%s\n' "$catalog_json" | jq -e 'all(.modules[]; (.executable | type == "boolean"))' >/dev/null
printf '%s\n' "$catalog_json" | jq -e 'all(.modules[]; (.name | test("_TEMPLATE") | not))' >/dev/null

if bash bin/modules_json.sh --unknown >/tmp/modules-json.out 2>/tmp/modules-json.err; then
  echo 'unknown option accepted' >&2
  exit 1
fi

grep -q 'Option inconnue' /tmp/modules-json.err
rm -f /tmp/modules-json.out /tmp/modules-json.err

printf '[OK] modules JSON tests passed\n'
