#!/usr/bin/env bash
# tests/test_modules.sh
# Tests pour core/lib_modules.sh
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

# shellcheck source=../core/lib_args.sh
source "core/lib_args.sh"
# shellcheck source=../core/lib_modules.sh
source "core/lib_modules.sh"

[[ "$(module_name_from_token 'modules/10_network_discovery.sh')" == '10_network_discovery.sh' ]]
[[ "$(module_path_from_name '10_network_discovery.sh')" == 'modules/10_network_discovery.sh' ]]

module_exists '10_network_discovery.sh'
module_exists 'modules/10_network_discovery.sh'

validate_selected_modules '10_network_discovery.sh,20_portscan_nmap.sh'
validate_selected_modules 'modules/10_network_discovery.sh modules/20_portscan_nmap.sh'

[[ "$(selected_modules_to_runner_args '10_network_discovery.sh,20_portscan_nmap.sh')" == '10_network_discovery.sh 20_portscan_nmap.sh' ]]

if validate_selected_modules 'does_not_exist.sh' >/dev/null 2>&1; then
  echo 'invalid module accepted' >&2
  exit 1
fi

if validate_selected_modules '' >/dev/null 2>&1; then
  echo 'empty module selection accepted' >&2
  exit 1
fi

printf '[OK] module validation tests passed\n'
