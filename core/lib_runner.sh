#!/usr/bin/env bash
set -Eeuo pipefail
discover_modules_sorted(){ ls -1 modules/*.sh 2>/dev/null | sort -V; }
run_modules(){
  for m in $(discover_modules_sorted); do
    # shellcheck source=/dev/null
    source "$m"
    emit INFO "${MOD_ID:-unknown}" "start"
    ( timeout "${MOD_TIMEOUT:-1800}" bash -c 'mod_pre && mod_run && mod_post' ) \
      && emit INFO "${MOD_ID:-unknown}" "success" \
      || emit ERROR "${MOD_ID:-unknown}" "failed($?)"
  done
}
write_manifest_json(){
  local f="output/$RUN_ID/manifest.json"
  {
    echo "{"
    echo "  \"run_id\":\"$RUN_ID\","
    echo "  \"targets\":\"$TARGETS\","
    echo "  \"profile\":\"$PROFILE\""
    echo "}"
  } > "$f"
}
