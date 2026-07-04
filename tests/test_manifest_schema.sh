#!/usr/bin/env bash
# tests/test_manifest_schema.sh
# Tests du schéma manifest généré par core/lib_runner.sh
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

# shellcheck source=../core/lib_logging.sh
source "core/lib_logging.sh"
# shellcheck source=../core/lib_runner.sh
source "core/lib_runner.sh"

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

RUN_ID="AUDIT_TEST_SCHEMA"
TARGETS="192.168.1.0/24 10.10.10.5"
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
export RUN_ID TARGETS PROFILE RUN_DIR LOG_DIR TMP_DIR LOG_FILE LOG_BUS OPTS_NO_UDP OPTS_NO_ZEEK OPTS_NO_SURICATA ALLOW_PUBLIC

mkdir -p "$RUN_DIR" "$LOG_DIR" "$TMP_DIR"

_append_module_result \
  "10_network_discovery" \
  "Découverte réseau" \
  "modules/10_network_discovery.sh" \
  "success" \
  "0" \
  "2026-07-01T00:00:01+00:00" \
  "2026-07-01T00:00:02+00:00" \
  "1" \
  "$RUN_DIR/10_network_discovery" \
  ""

_append_module_result \
  "70_http_enum" \
  "HTTP enum" \
  "modules/70_http_enum.sh" \
  "skipped" \
  "127" \
  "2026-07-01T00:00:03+00:00" \
  "2026-07-01T00:00:03+00:00" \
  "0" \
  "$RUN_DIR/70_http_enum" \
  "missing dependency"

manifest_path="$RUN_DIR/manifest.json"
write_manifest_json "$manifest_path" "modules/10_network_discovery.sh modules/70_http_enum.sh"

jq -e '.schema_version == "1.0.0"' "$manifest_path" >/dev/null
jq -e '.kind == "audit-suite.manifest"' "$manifest_path" >/dev/null
jq -e '.summary.module_count == 2' "$manifest_path" >/dev/null
jq -e '.summary.success_count == 1' "$manifest_path" >/dev/null
jq -e '.summary.failed_count == 0' "$manifest_path" >/dev/null
jq -e '.summary.skipped_count == 1' "$manifest_path" >/dev/null
jq -e '.summary.total_duration_seconds == 1' "$manifest_path" >/dev/null
jq -e '.summary.status == "success"' "$manifest_path" >/dev/null
jq -e '.paths.output == env.RUN_DIR' "$manifest_path" >/dev/null
jq -e '.paths.logs == env.LOG_DIR' "$manifest_path" >/dev/null
jq -e '.modules[1].status == "skipped"' "$manifest_path" >/dev/null

printf '[OK] manifest schema tests passed\n'
