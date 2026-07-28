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

history_lock_path() {
  printf '%s\n' "$(history_dir)/.write.lock"
}

history_init() {
  local dir
  dir="$(history_dir)"
  mkdir -p "$dir"
  touch "$(history_index_path)"
}

history_acquire_lock() {
  local lock_path="$1"
  local attempts="${AUDIT_HISTORY_LOCK_ATTEMPTS:-200}"
  local attempt=0

  while ! mkdir "$lock_path" 2>/dev/null; do
    attempt=$((attempt + 1))
    if (( attempt >= attempts )); then
      return 1
    fi
    sleep 0.05
  done
}

history_read_index_json() {
  local index_path
  index_path="$(history_index_path)"

  if [[ ! -f "$index_path" ]]; then
    jq -n '{runs: [], invalid_line_count: 0, ignored_line_count: 0}'
    return 0
  fi

  jq -Rn '
    reduce inputs as $line (
      {runs: [], invalid_line_count: 0, ignored_line_count: 0};
      if ($line | length) == 0 then
        .ignored_line_count += 1
      else
        (try ($line | fromjson) catch null) as $entry
        | if ($entry | type) == "object" then
            .runs += [$entry]
          else
            .invalid_line_count += 1
          end
      end
    )
  ' "$index_path"
}

history_record_run() {
  (
  local manifest_path="$1"
  local dir index_path latest_path lock_path record_tmp latest_tmp
  local lock_acquired=0

  record_tmp=""
  latest_tmp=""

  # Called indirectly by the EXIT trap below.
  # shellcheck disable=SC2317
  cleanup_history_record() {
    [[ -n "$record_tmp" ]] && rm -f "$record_tmp"
    [[ -n "$latest_tmp" ]] && rm -f "$latest_tmp"
    if (( lock_acquired == 1 )); then
      rmdir "$lock_path" 2>/dev/null || true
    fi
  }
  trap cleanup_history_record EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM

  if ! command -v jq >/dev/null 2>&1; then
    emit ERROR "history" "jq is required to record run history"
    return 1
  fi

  if [[ ! -f "$manifest_path" ]]; then
    emit ERROR "history" "manifest not found: $manifest_path"
    return 1
  fi

  dir="$(history_dir)"
  mkdir -p "$dir"
  index_path="$(history_index_path)"
  latest_path="$(history_latest_path)"
  lock_path="$(history_lock_path)"
  record_tmp="$(mktemp "$dir/.record.XXXXXX")"
  latest_tmp="$(mktemp "$dir/.latest.XXXXXX")"

  if ! jq -ce --arg manifest_path "$manifest_path" '{
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
  }' "$manifest_path" > "$record_tmp"; then
    emit ERROR "history" "manifest is not valid JSON: $manifest_path"
    return 1
  fi

  if ! jq -e --arg manifest_path "$manifest_path" '{
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
  }' "$manifest_path" > "$latest_tmp"; then
    emit ERROR "history" "cannot prepare latest run: $manifest_path"
    return 1
  fi

  if ! history_acquire_lock "$lock_path"; then
    emit ERROR "history" "timed out waiting for history write lock"
    return 1
  fi
  lock_acquired=1

  touch "$index_path"
  cat "$record_tmp" >> "$index_path"
  mv -f "$latest_tmp" "$latest_path"
  latest_tmp=""

  rmdir "$lock_path"
  lock_acquired=0
  emit INFO "history" "Run history updated: $index_path"
  )
}

history_list_runs() {
  history_read_index_json \
    | jq -r '.runs[] | [.created_at, .run_id, .profile, (.targets | join(",")), (.status // "unknown"), (.success_count|tostring), (.failed_count|tostring), (.skipped_count|tostring)] | @tsv'
}
