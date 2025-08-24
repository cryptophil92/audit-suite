#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
source core/lib_logging.sh
source core/lib_detect.sh
source core/lib_menu.sh
source core/lib_runner.sh
source etc/defaults.env

./bin/check_deps.sh || true
detect_env

# UI
PROFILE="$(ui_pick_profile || echo "${PROFILE:-fast}")"
TARGETS_INPUT="$(ui_enter_targets || true)"; TARGETS="${TARGETS_INPUT:-${DEF_CIDR:-}}"
CATS="$(ui_pick_categories || echo discovery,portscan,report)"
OPTS="$(ui_confirm_opts || echo "OPTS_NO_UDP=0,OPTS_NO_ZEEK=1,OPTS_NO_SURICATA=1")"

# RUN
RUN_ID="$(date +%Y%m%d_%H%M%S)"
RUN_DIR="output/$RUN_ID"; mkdir -p "$RUN_DIR"
init_logging "$RUN_ID"
./ui/ui_tmux_logger.sh "$RUN_ID" || true

# Export env standard
export RUN_ID RUN_DIR PROFILE TARGETS
for kv in ${OPTS//,/ }; do export "$kv"; done

emit INFO "launcher" "targets=$TARGETS profile=$PROFILE opts=$OPTS"
run_modules
write_manifest_json
emit INFO "launcher" "done"
echo "Résultats: $RUN_DIR / Logs: logs/$RUN_ID"
