#!/usr/bin/env bash
# tests/test_dry_run.sh
# Tests pour audit.sh --dry-run et --list-modules
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

before_output_count="$(find output -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"

list_output="$(bash audit.sh --list-modules)"
printf '%s\n' "$list_output" | grep -q '10_network_discovery.sh'

plan_output="$(bash audit.sh \
  --dry-run \
  --profile fast \
  --targets 192.168.1.0/24 \
  --categories 10_network_discovery.sh \
  --no-zeek \
  --no-suricata)"

printf '%s\n' "$plan_output" | grep -q 'AUDIT-SUITE dry run'
printf '%s\n' "$plan_output" | grep -q 'Profile: fast'
printf '%s\n' "$plan_output" | grep -q 'Targets: 192.168.1.0/24'
printf '%s\n' "$plan_output" | grep -q 'Categories: 10_network_discovery.sh'
printf '%s\n' "$plan_output" | grep -q 'Selected modules: 10_network_discovery.sh'
printf '%s\n' "$plan_output" | grep -q 'no_zeek: 1'
printf '%s\n' "$plan_output" | grep -q 'no_suricata: 1'

after_output_count="$(find output -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"
[[ "$before_output_count" == "$after_output_count" ]]

printf '[OK] dry-run tests passed\n'
