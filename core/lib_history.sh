#!/usr/bin/env bash
# core/lib_history.sh
# @version 0.2.3
set -Eeuo pipefail

history_dir() {
  printf '%s\n' "${AUDIT_HISTORY_DIR:-history}"
}

history_index_path() {
  printf '%s\n' "$(history_dir)/runs.jsonl"
}

history_latest_path() {
  printf '%s\n' "$(history_dir)/latest.json"
}

history_init() {
  local dir
  dir="$(history_dir)"
  mkdir -p "$dir"
  touch "$(history_index_path)"
}

history_record_run() {
  local manifest_path="$1"
  local index_path latest_path tmp_path

  if ! command -v jq >/dev/null 2>&1; then
    emit ERROR "history" "jq is required to record run history"
    return 1
  fi

  if [[ ! -f "$manifest_path" ]]; then
    emit ERROR "history" "manifest not found: $manifest_path"
    return 1
  fi

  history_init
  index_path="$(history_index_path)"
  latest_path="$(history_latest_path)"
  tmp_path="${latest_path}.tmp"

  jq -c --arg manifest_path "$manifest_path" '{
    schema_version: (.schema_version // "0.1.0"),
    run_id,
    created_at,
    profile,
    targets,
    options,
    selected_modules,
    module_count: (.summary.module_count // (.modules | length)),
    success_count: (.summary.success_count // ([.modules[]? | select(.status == "success")] | length)),
    failed_count: (.summary.failed_count // ([.modules[]? | select(.status == "failed")] | length)),
    skipped_count: (.summary.skipped_count // ([.modules[]? | select(.status == "skipped")] | length)),
    total_duration_seconds: (.summary.total_duration_seconds // ([.modules[]?.duration_seconds] | add // 0)),
    status: (.summary.status // "unknown"),
    output_path: (.paths.output // ("output/" + .run_id)),
    manifest_path: $manifest_path
  }' "$manifest_path" >> "$index_path"

  jq --arg manifest_path "$manifest_path" '{
    schema_version: (.schema_version // "0.1.0"),
    run_id,
    created_at,
    profile,
    targets,
    options,
    selected_modules,
    summary,
    modules,
    output_path: (.paths.output // ("output/" + .run_id)),
    manifest_path: $manifest_path
  }' "$manifest_path" > "$tmp_path"

  mv "$tmp_path" "$latest_path"
  emit INFO "history" "Run history updated: $index_path"
}

history_list_runs() {
  local index_path
  index_path="$(history_index_path)"

  [[ -f "$index_path" ]] || return 0
  jq -r '[.created_at, .run_id, .profile, (.targets | join(",")), (.status // "unknown"), (.success_count|tostring), (.failed_count|tostring), (.skipped_count|tostring)] | @tsv' "$index_path"
}
