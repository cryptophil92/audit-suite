#!/usr/bin/env bash
# bin/manifest_json.sh
# @version 0.2.35
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

# shellcheck source=../core/lib_findings.sh
source "core/lib_findings.sh"

usage_manifest_json() {
  cat <<'EOF'
Usage: bash bin/manifest_json.sh <command> <manifest.json>

Commands:
  validate   Validate a manifest and its findings contract.
  normalize  Read schema 1.0.0, 1.1.0 or 1.2.0 and expose findings[] safely.
  help       Show this help.

Normalization does not rewrite the source file.
EOF
}

manifest_validation_json() {
  local manifest_path="$1"

  findings_validate_manifest_file "$manifest_path"

  jq -n \
    --arg kind "audit-suite.manifest-validation" \
    --arg schema_version "1.0.0" \
    --arg manifest_path "$manifest_path" \
    --arg manifest_schema_version "$(jq -r '.schema_version' "$manifest_path")" \
    --arg findings_schema_version "$FINDINGS_SCHEMA_VERSION" \
    --argjson finding_count "$(jq '(.findings // []) | length' "$manifest_path")" '
      {
        kind: $kind,
        schema_version: $schema_version,
        valid: true,
        manifest_path: $manifest_path,
        manifest_schema_version: $manifest_schema_version,
        findings_schema_version: $findings_schema_version,
        finding_count: $finding_count
      }
    '
}

cmd="${1:-help}"

case "$cmd" in
  validate)
    [[ $# -eq 2 ]] || {
      usage_manifest_json >&2
      exit 2
    }
    manifest_validation_json "$2"
    ;;
  normalize)
    [[ $# -eq 2 ]] || {
      usage_manifest_json >&2
      exit 2
    }
    findings_normalize_manifest_file "$2"
    ;;
  help|-h|--help)
    usage_manifest_json
    ;;
  *)
    echo "Unknown command: $cmd" >&2
    usage_manifest_json >&2
    exit 2
    ;;
esac
