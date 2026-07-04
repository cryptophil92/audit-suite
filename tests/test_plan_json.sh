#!/usr/bin/env bash
# tests/test_plan_json.sh
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

run_id="PLAN_JSON_TEST"
rm -rf "output/$run_id" "logs/$run_id"

before_output_count="$(find output -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"

plan_json="$(bash bin/plan_json.sh \
  --profile fast \
  --targets 192.168.1.0/24 \
  --categories all \
  --run-id "$run_id" \
  --no-zeek \
  --no-suricata)"

printf '%s\n' "$plan_json" | jq -e '.kind == "audit-suite.plan"' >/dev/null
printf '%s\n' "$plan_json" | jq -e '.schema_version == "1.0.0"' >/dev/null
printf '%s\n' "$plan_json" | jq -e '.run_id == "PLAN_JSON_TEST"' >/dev/null
printf '%s\n' "$plan_json" | jq -e '.profile == "fast"' >/dev/null
printf '%s\n' "$plan_json" | jq -e '.targets == ["192.168.1.0/24"]' >/dev/null
printf '%s\n' "$plan_json" | jq -e '.categories == "all"' >/dev/null
printf '%s\n' "$plan_json" | jq -e '.selected_modules | index("10_network_discovery.sh")' >/dev/null
printf '%s\n' "$plan_json" | jq -e '.selected_modules | index("20_portscan_nmap.sh")' >/dev/null
printf '%s\n' "$plan_json" | jq -e '.options.no_zeek == true' >/dev/null
printf '%s\n' "$plan_json" | jq -e '.options.no_suricata == true' >/dev/null
printf '%s\n' "$plan_json" | jq -e '.paths.output == "output/PLAN_JSON_TEST"' >/dev/null
printf '%s\n' "$plan_json" | jq -e '.paths.logs == "logs/PLAN_JSON_TEST"' >/dev/null

after_output_count="$(find output -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"
[[ "$before_output_count" == "$after_output_count" ]]

printf '[OK] JSON plan tests passed\n'
