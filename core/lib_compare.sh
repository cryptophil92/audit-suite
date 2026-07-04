#!/usr/bin/env bash
# core/lib_compare.sh
# @version 0.2.3
set -Eeuo pipefail

COMPARE_SCHEMA_VERSION="1.0.0"

_compare_require_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    echo "jq is required to compare manifests" >&2
    return 1
  fi
}

_compare_validate_manifest() {
  local manifest_path="$1"

  if [[ ! -f "$manifest_path" ]]; then
    echo "Manifest introuvable: $manifest_path" >&2
    return 1
  fi

  jq -e 'type == "object" and (.run_id | type == "string") and ((.modules // []) | type == "array")' "$manifest_path" >/dev/null
}

compare_runs_json() {
  local before_manifest="$1"
  local after_manifest="$2"
  local created_at

  _compare_require_jq
  _compare_validate_manifest "$before_manifest"
  _compare_validate_manifest "$after_manifest"

  created_at="$(date -Is)"

  jq -n \
    --arg schema_version "$COMPARE_SCHEMA_VERSION" \
    --arg created_at "$created_at" \
    --arg before_manifest "$before_manifest" \
    --arg after_manifest "$after_manifest" \
    --slurpfile before "$before_manifest" \
    --slurpfile after "$after_manifest" \
    '
    def normalize_module($m): {
      id: $m.id,
      name: ($m.name // ""),
      path: ($m.path // ""),
      status: ($m.status // "unknown"),
      rc: ($m.rc // null),
      duration_seconds: ($m.duration_seconds // 0),
      reason: ($m.reason // ""),
      output_path: ($m.output_path // "")
    };

    def modules_by_id($mods):
      reduce (($mods // [])[] | select(.id != null)) as $m ({}; .[$m.id] = normalize_module($m));

    def manifest_summary($m): {
      run_id: $m.run_id,
      created_at: ($m.created_at // ""),
      profile: ($m.profile // ""),
      targets: ($m.targets // []),
      status: ($m.summary.status // "unknown"),
      module_count: ($m.summary.module_count // (($m.modules // []) | length)),
      success_count: ($m.summary.success_count // ([($m.modules // [])[] | select(.status == "success")] | length)),
      failed_count: ($m.summary.failed_count // ([($m.modules // [])[] | select(.status == "failed")] | length)),
      skipped_count: ($m.summary.skipped_count // ([($m.modules // [])[] | select(.status == "skipped")] | length)),
      total_duration_seconds: ($m.summary.total_duration_seconds // ([($m.modules // [])[].duration_seconds] | add // 0))
    };

    ($before[0]) as $b |
    ($after[0]) as $a |
    (modules_by_id($b.modules)) as $before_modules |
    (modules_by_id($a.modules)) as $after_modules |
    (($before_modules | keys_unsorted) + ($after_modules | keys_unsorted) | unique | sort) as $module_ids |
    [
      $module_ids[] as $id |
      ($before_modules[$id] // null) as $before_module |
      ($after_modules[$id] // null) as $after_module |
      {
        id: $id,
        name: (($after_module.name // $before_module.name) // ""),
        change: (
          if $before_module == null then "added"
          elif $after_module == null then "removed"
          elif $before_module.status != $after_module.status then "status_changed"
          elif $before_module.rc != $after_module.rc then "rc_changed"
          else "unchanged"
          end
        ),
        before: $before_module,
        after: $after_module
      }
    ] as $changes |
    {
      kind: "audit-suite.compare",
      schema_version: $schema_version,
      created_at: $created_at,
      before: (manifest_summary($b) + {manifest_path: $before_manifest}),
      after: (manifest_summary($a) + {manifest_path: $after_manifest}),
      summary: {
        total_modules_compared: ($changes | length),
        added_count: ([$changes[] | select(.change == "added")] | length),
        removed_count: ([$changes[] | select(.change == "removed")] | length),
        status_changed_count: ([$changes[] | select(.change == "status_changed")] | length),
        rc_changed_count: ([$changes[] | select(.change == "rc_changed")] | length),
        unchanged_count: ([$changes[] | select(.change == "unchanged")] | length),
        regression_count: ([
          $changes[] |
          select(
            (.before.status == "success" and (.after.status == "failed" or .after.status == "skipped")) or
            (.before.status == "skipped" and .after.status == "failed")
          )
        ] | length),
        improvement_count: ([
          $changes[] |
          select(
            ((.before.status == "failed" or .before.status == "skipped") and .after.status == "success") or
            (.before.status == "failed" and .after.status == "skipped")
          )
        ] | length)
      },
      modules: $changes
    }'
}

compare_runs_text() {
  local before_manifest="$1"
  local after_manifest="$2"

  compare_runs_json "$before_manifest" "$after_manifest" | jq -r '
    "Compare: \(.before.run_id) -> \(.after.run_id)",
    "Status: before=\(.before.status) after=\(.after.status)",
    "Modules: added=\(.summary.added_count) removed=\(.summary.removed_count) status_changed=\(.summary.status_changed_count) rc_changed=\(.summary.rc_changed_count) unchanged=\(.summary.unchanged_count)",
    "Regressions: \(.summary.regression_count)",
    "Improvements: \(.summary.improvement_count)",
    "",
    "change\tmodule\tbefore\tafter\treason",
    (
      .modules[]
      | select(.change != "unchanged")
      | [
          .change,
          .id,
          (.before.status // "-"),
          (.after.status // "-"),
          (.after.reason // .before.reason // "")
        ]
      | @tsv
    )
  '
}
