#!/usr/bin/env bash
# core/lib_findings.sh
# @version 0.2.35
set -Eeuo pipefail

FINDINGS_SCHEMA_VERSION="1.0.0"
FINDINGS_MANIFEST_SCHEMA_VERSION="1.2.0"

_findings_repo_dir() {
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd
}

_findings_validator_path() {
  printf '%s\n' "$(_findings_repo_dir)/schemas/findings-${FINDINGS_SCHEMA_VERSION}.validator.jq"
}

_findings_require_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    echo "jq is required to validate findings" >&2
    return 1
  fi
}

findings_validate_array_file() {
  local findings_path="$1"
  local validator_path

  _findings_require_jq

  if [[ ! -f "$findings_path" ]]; then
    echo "Findings file not found: $findings_path" >&2
    return 1
  fi

  validator_path="$(_findings_validator_path)"
  if [[ ! -f "$validator_path" ]]; then
    echo "Findings validator not found: $validator_path" >&2
    return 1
  fi

  if ! jq -e -f "$validator_path" "$findings_path" >/dev/null; then
    echo "Invalid findings contract ${FINDINGS_SCHEMA_VERSION}: $findings_path" >&2
    return 1
  fi
}

findings_read_array_or_empty() {
  local findings_path="$1"

  _findings_require_jq

  if [[ ! -e "$findings_path" ]]; then
    printf '[]\n'
    return 0
  fi

  findings_validate_array_file "$findings_path"
  jq -c '.' "$findings_path"
}

findings_prepare_array_file() {
  local findings_path="$1"
  local prepared_path="$2"

  _findings_require_jq

  if [[ ! -e "$findings_path" ]]; then
    printf '[]\n' > "$prepared_path"
    return 0
  fi

  findings_validate_array_file "$findings_path"
  jq -c '.' "$findings_path" > "$prepared_path"
}

findings_validate_manifest_file() {
  local manifest_path="$1"
  local validator_path

  _findings_require_jq

  if [[ ! -f "$manifest_path" ]]; then
    echo "Manifest not found: $manifest_path" >&2
    return 1
  fi

  validator_path="$(_findings_validator_path)"

  if ! jq -e \
    --arg findings_schema_version "$FINDINGS_SCHEMA_VERSION" \
    --arg current_manifest_schema "$FINDINGS_MANIFEST_SCHEMA_VERSION" '
      type == "object"
      and .kind == "audit-suite.manifest"
      and (.run_id | type == "string" and length > 0)
      and (.schema_version | IN("1.0.0", "1.1.0", $current_manifest_schema))
      and ((.modules // []) | type == "array")
      and (
        if .schema_version == $current_manifest_schema then
          .findings_schema_version == $findings_schema_version
          and (.findings | type == "array")
          and (.summary.findings | type == "object")
          and (.summary.findings.total_count == (.findings | length))
          and (
            .summary.findings.scored_count
            == ([.findings[]? | select(.scoring.status == "scored")] | length)
          )
          and (
            .summary.findings.unscored_count
            == ([.findings[]? | select(.scoring.status == "unscored")] | length)
          )
          and (
            .summary.findings.by_severity
            == {
              informational: ([.findings[]? | select(.severity == "informational")] | length),
              low: ([.findings[]? | select(.severity == "low")] | length),
              medium: ([.findings[]? | select(.severity == "medium")] | length),
              high: ([.findings[]? | select(.severity == "high")] | length),
              critical: ([.findings[]? | select(.severity == "critical")] | length),
              unknown: ([.findings[]? | select(.severity == "unknown")] | length)
            }
          )
          and (
            .summary.findings.by_confidence
            == {
              low: ([.findings[]? | select(.confidence == "low")] | length),
              medium: ([.findings[]? | select(.confidence == "medium")] | length),
              high: ([.findings[]? | select(.confidence == "high")] | length)
            }
          )
        else
          (has("findings_schema_version") | not)
          and (has("findings") | not)
        end
      )
    ' "$manifest_path" >/dev/null; then
    echo "Invalid or unsupported Audit Suite manifest: $manifest_path" >&2
    return 1
  fi

  if [[ "$(jq -r '.schema_version' "$manifest_path")" == "$FINDINGS_MANIFEST_SCHEMA_VERSION" ]]; then
    if ! jq -c '.findings' "$manifest_path" | jq -e -f "$validator_path" >/dev/null; then
      echo "Manifest contains invalid findings: $manifest_path" >&2
      return 1
    fi
  fi
}

findings_normalize_manifest_file() {
  local manifest_path="$1"

  findings_validate_manifest_file "$manifest_path"

  jq \
    --arg findings_schema_version "$FINDINGS_SCHEMA_VERSION" \
    --arg current_manifest_schema "$FINDINGS_MANIFEST_SCHEMA_VERSION" '
      if .schema_version == $current_manifest_schema then
        .
      else
        .findings_schema_version = $findings_schema_version
        | .findings = []
        | .summary = ((.summary // {}) + {
            findings: {
              total_count: 0,
              scored_count: 0,
              unscored_count: 0,
              by_severity: {
                informational: 0,
                low: 0,
                medium: 0,
                high: 0,
                critical: 0,
                unknown: 0
              },
              by_confidence: {
                low: 0,
                medium: 0,
                high: 0
              }
            }
          })
      end
    ' "$manifest_path"
}
