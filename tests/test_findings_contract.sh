#!/usr/bin/env bash
# tests/test_findings_contract.sh
# Validates findings schema 1.0.0 and manifest compatibility.
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

# shellcheck source=../core/lib_logging.sh
source "core/lib_logging.sh"
# shellcheck source=../core/lib_findings.sh
source "core/lib_findings.sh"
# shellcheck source=../core/lib_runner.sh
source "core/lib_runner.sh"
# shellcheck source=../core/lib_history.sh
source "core/lib_history.sh"

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

fixture_dir="tests/fixtures/findings"
legacy_100="$fixture_dir/manifest-1.0.0.json"
legacy_110="$fixture_dir/manifest-1.1.0.json"
current_120="$fixture_dir/manifest-1.2.0.json"

jq -e '.' "schemas/findings-1.0.0.schema.json" >/dev/null
jq -e -n '[]' | jq -e -f "schemas/findings-1.0.0.validator.jq" >/dev/null

for legacy_manifest in "$legacy_100" "$legacy_110"; do
  findings_validate_manifest_file "$legacy_manifest"
  normalized="$(bash bin/manifest_json.sh normalize "$legacy_manifest")"

  printf '%s\n' "$normalized" | jq -e \
    --arg source_version "$(jq -r '.schema_version' "$legacy_manifest")" '
      .schema_version == $source_version
      and .findings_schema_version == "1.0.0"
      and .findings == []
      and .summary.findings.total_count == 0
      and .summary.findings.scored_count == 0
      and .summary.findings.unscored_count == 0
    ' >/dev/null
done

validation_json="$(bash bin/manifest_json.sh validate "$current_120")"
printf '%s\n' "$validation_json" | jq -e '
  .kind == "audit-suite.manifest-validation"
  and .valid == true
  and .manifest_schema_version == "1.2.0"
  and .findings_schema_version == "1.0.0"
  and .finding_count == 2
' >/dev/null

jq '.findings' "$current_120" > "$TMP_ROOT/findings.json"
findings_validate_array_file "$TMP_ROOT/findings.json"
jq -e '
  .[0].scoring.status == "scored"
  and .[0].scoring.method == "cvss-v3.1"
  and .[1].scoring.status == "unscored"
  and .[1].title == "Bannière de service synthétique <à examiner>"
' "$TMP_ROOT/findings.json" >/dev/null

expect_invalid_manifest() {
  local name="$1"
  local filter="$2"
  local invalid_path="$TMP_ROOT/${name}.json"

  jq "$filter" "$current_120" > "$invalid_path"

  if findings_validate_manifest_file "$invalid_path" >/dev/null 2>&1; then
    printf '[FAIL] invalid findings case accepted: %s\n' "$name" >&2
    exit 1
  fi
}

expect_invalid_manifest "duplicate-id" \
  '.findings[1].id = .findings[0].id'
expect_invalid_manifest "missing-score-method" \
  '.findings[0].scoring |= del(.method)'
expect_invalid_manifest "unknown-score-method" \
  '.findings[0].scoring.method = "decorative-score"'
expect_invalid_manifest "invalid-cvss-vector" \
  '.findings[0].scoring.vector = "CVSS:3.0/AV:N"'
expect_invalid_manifest "incomplete-cvss-vector" \
  '.findings[0].scoring.vector = "CVSS:3.1/AV:N"'
expect_invalid_manifest "unsafe-evidence-path" \
  '.findings[0].evidence[0].path = "../../private/result.json"'
expect_invalid_manifest "embedded-raw-html" \
  '.findings[0].evidence[0].raw_html = "<script>alert(1)</script>"'
expect_invalid_manifest "incorrect-summary" \
  '.summary.findings.total_count = 99'
expect_invalid_manifest "missing-verification" \
  '.findings[1].remediation |= del(.verification)'
expect_invalid_manifest "missing-evidence" \
  '.findings[1].evidence = []'
expect_invalid_manifest "missing-impact" \
  '.findings[1] |= del(.impact)'
expect_invalid_manifest "unsupported-manifest-schema" \
  '.schema_version = "1.3.0"'

RUN_ID="AUDIT_SYNTHETIC_RUNNER_FINDINGS"
TARGETS="192.0.2.0/24"
PROFILE="fast"
RUN_DIR="$TMP_ROOT/output/$RUN_ID"
LOG_DIR="$TMP_ROOT/logs/$RUN_ID"
TMP_DIR="$TMP_ROOT/tmp"
LOG_FILE="$LOG_DIR/combined.log"
LOG_BUS=""
OPTS_NO_UDP=0
OPTS_NO_ZEEK=1
OPTS_NO_SURICATA=1
ALLOW_PUBLIC=0
export RUN_ID TARGETS PROFILE RUN_DIR LOG_DIR TMP_DIR LOG_FILE LOG_BUS
export OPTS_NO_UDP OPTS_NO_ZEEK OPTS_NO_SURICATA ALLOW_PUBLIC

mkdir -p "$RUN_DIR" "$LOG_DIR" "$TMP_DIR"
cp "$TMP_ROOT/findings.json" "$RUN_DIR/findings.json"

generated_manifest="$RUN_DIR/manifest.json"
write_manifest_json "$generated_manifest" ""

jq -e '
  .schema_version == "1.2.0"
  and .findings_schema_version == "1.0.0"
  and (.findings | length) == 2
  and .summary.findings.total_count == 2
  and .summary.findings.scored_count == 1
  and .summary.findings.unscored_count == 1
  and .summary.findings.by_severity.medium == 1
  and .summary.findings.by_confidence.high == 1
' "$generated_manifest" >/dev/null

RUN_ID="AUDIT_SYNTHETIC_RUNNER_EMPTY"
RUN_DIR="$TMP_ROOT/output/$RUN_ID"
LOG_DIR="$TMP_ROOT/logs/$RUN_ID"
LOG_FILE="$LOG_DIR/combined.log"
export RUN_ID RUN_DIR LOG_DIR LOG_FILE
mkdir -p "$RUN_DIR" "$LOG_DIR"

empty_manifest="$RUN_DIR/manifest.json"
write_manifest_json "$empty_manifest" ""
jq -e '
  .schema_version == "1.2.0"
  and .findings == []
  and .summary.findings.total_count == 0
' "$empty_manifest" >/dev/null

RUN_ID="AUDIT_SYNTHETIC_RUNNER_INVALID"
RUN_DIR="$TMP_ROOT/output/$RUN_ID"
LOG_DIR="$TMP_ROOT/logs/$RUN_ID"
LOG_FILE="$LOG_DIR/combined.log"
export RUN_ID RUN_DIR LOG_DIR LOG_FILE
mkdir -p "$RUN_DIR" "$LOG_DIR"
printf '{"not":"an array"}\n' > "$RUN_DIR/findings.json"

if write_manifest_json "$RUN_DIR/manifest.json" "" >/dev/null 2>&1; then
  printf '[FAIL] runner accepted an invalid findings input\n' >&2
  exit 1
fi
[[ ! -e "$RUN_DIR/manifest.json" ]]

AUDIT_HISTORY_DIR="$TMP_ROOT/history"
export AUDIT_HISTORY_DIR
history_record_run "$current_120"

jq -e '
  .findings_schema_version == "1.0.0"
  and (.findings | length) == 2
  and .summary.findings.total_count == 2
' "$(history_latest_path)" >/dev/null

tail -n 1 "$(history_index_path)" | jq -e '
  .finding_count == 2
  and .scored_finding_count == 1
  and .unscored_finding_count == 1
  and .findings_by_severity.medium == 1
' >/dev/null

printf '[OK] findings contract tests passed\n'
