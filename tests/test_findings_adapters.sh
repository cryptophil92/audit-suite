#!/usr/bin/env bash
# Validate deterministic module adapters using synthetic fixtures only.
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

# shellcheck source=../core/lib_findings_adapters.sh
source "core/lib_findings_adapters.sh"

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

fixture_dir="tests/fixtures/findings/adapters"
collected_at="2026-07-30T12:05:00Z"
scope_target="192.0.2.0/24"

prepare_run() {
  local name="$1"
  local fixture="$2"
  local run_dir="$TMP_ROOT/$name"

  mkdir -p "$run_dir/20_portscan_nmap"
  cp "$fixture_dir/$fixture" "$run_dir/20_portscan_nmap/fast.gnmap"
  printf '%s\n' "$run_dir"
}

positive_run="$(prepare_run positive nmap-portscan-positive.gnmap)"
bash bin/findings_from_modules.sh \
  --collected-at "$collected_at" \
  "$positive_run" \
  "$scope_target" >/dev/null

positive_findings="$positive_run/findings.json"
findings_validate_array_file "$positive_findings"
jq -e '
  length == 3
  and all(.[];
    .type == "observation"
    and .validation_status == "observed"
    and .severity == "informational"
    and .scoring.status == "unscored"
    and .confidence == "high"
    and .source.module == "20_portscan_nmap"
    and .source.tool == "nmap"
    and .source.tool_version == "7.95"
    and .evidence[0].path == "20_portscan_nmap/fast.gnmap"
    and .evidence[0].captured_at == "2026-07-30T12:05:00Z"
    and .scope.target == "192.0.2.0/24"
  )
  and any(.[];
    .asset.address == "192.0.2.10"
    and .asset.hostname == "web-01.example.invalid"
    and .service.port == 443
    and (.observation | contains("VULNERABLE synthetic label"))
    and .type == "observation"
  )
  and any(.[]; .service.transport == "udp" and .service.port == 53)
  and ([.[].id] | unique | length) == length
' "$positive_findings" >/dev/null

negative_run="$(prepare_run negative nmap-portscan-negative.gnmap)"
bash bin/findings_from_modules.sh \
  --collected-at "$collected_at" \
  "$negative_run" \
  "$scope_target" >/dev/null
jq -e '. == []' "$negative_run/findings.json" >/dev/null

partial_run="$(prepare_run partial nmap-portscan-partial.gnmap)"
partial_output="$(
  bash bin/findings_from_modules.sh \
    --collected-at "$collected_at" \
    "$partial_run" \
    "$scope_target" 2>&1
)"
printf '%s\n' "$partial_output" | grep -Fq 'ignored malformed open-port entry'
jq -e '
  length == 1
  and .[0].service.port == 8080
  and .[0].type == "observation"
' "$partial_run/findings.json" >/dev/null

base_findings="$TMP_ROOT/base-findings.json"
jq '[.findings[1]]' tests/fixtures/findings/manifest-1.2.0.json > "$base_findings"

merged_run="$(prepare_run merged nmap-portscan-positive.gnmap)"
bash bin/findings_from_modules.sh \
  --base "$base_findings" \
  --collected-at "$collected_at" \
  "$merged_run" \
  "$scope_target" >/dev/null

merged_findings="$merged_run/findings.json"
findings_validate_array_file "$merged_findings"
jq -e '
  length == 4
  and ([.[].source.module] | unique | sort) == [
    "20_portscan_nmap",
    "40_service_enum"
  ]
  and ([.[].id] | unique | length) == length
' "$merged_findings" >/dev/null

# A second deterministic pass merges identical identifiers and evidence.
bash bin/findings_from_modules.sh \
  --collected-at "$collected_at" \
  "$merged_run" \
  "$scope_target" >/dev/null
jq -e 'length == 4 and ([.[].id] | unique | length) == length' \
  "$merged_findings" >/dev/null

# A conflicting duplicate is rejected and cannot replace the valid output.
conflicting_findings="$TMP_ROOT/conflicting-findings.json"
jq '[.[0] | .title = "Conflicting synthetic title"]' \
  "$merged_findings" > "$conflicting_findings"
cp "$merged_findings" "$TMP_ROOT/merged-before-conflict.json"
if bash bin/findings_from_modules.sh \
  --base "$conflicting_findings" \
  --collected-at "$collected_at" \
  "$merged_run" \
  "$scope_target" >/dev/null 2>&1; then
  printf '[FAIL] conflicting duplicate finding id was accepted\n' >&2
  exit 1
fi
cmp -s "$TMP_ROOT/merged-before-conflict.json" "$merged_findings"

# A reused evidence id with different content is also rejected atomically.
conflicting_evidence="$TMP_ROOT/conflicting-evidence.json"
jq '[
  .[0]
  | .evidence[0].path = "20_portscan_nmap/conflicting.gnmap"
]' "$merged_findings" > "$conflicting_evidence"
if bash bin/findings_from_modules.sh \
  --base "$conflicting_evidence" \
  --collected-at "$collected_at" \
  "$merged_run" \
  "$scope_target" >/dev/null 2>&1; then
  printf '[FAIL] conflicting duplicate evidence id was accepted\n' >&2
  exit 1
fi
cmp -s "$TMP_ROOT/merged-before-conflict.json" "$merged_findings"

# A non-array or otherwise nonconforming base is rejected atomically.
invalid_base="$TMP_ROOT/invalid-base.json"
printf '{"not":"findings[]"}\n' > "$invalid_base"
invalid_run="$(prepare_run invalid-base nmap-portscan-negative.gnmap)"
printf '[]\n' > "$invalid_run/findings.json"
cp "$invalid_run/findings.json" "$TMP_ROOT/invalid-output-before.json"
if bash bin/findings_from_modules.sh \
  --base "$invalid_base" \
  --collected-at "$collected_at" \
  "$invalid_run" \
  "$scope_target" >/dev/null 2>&1; then
  printf '[FAIL] invalid findings[] base was accepted\n' >&2
  exit 1
fi
cmp -s "$TMP_ROOT/invalid-output-before.json" "$invalid_run/findings.json"

# Evidence references cannot escape the run directory.
if findings_adapt_nmap_portscan_file \
  "$fixture_dir/nmap-portscan-positive.gnmap" \
  "../private/result.gnmap" \
  "$scope_target" \
  "$collected_at" \
  "$TMP_ROOT/unsafe.json" >/dev/null 2>&1; then
  printf '[FAIL] unsafe evidence path was accepted\n' >&2
  exit 1
fi
[[ ! -e "$TMP_ROOT/unsafe.json" ]]

printf '[OK] findings adapter tests passed\n'
