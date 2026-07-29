#!/usr/bin/env bash
# Tests du catalogue de maturité et de la migration du pack rapport.
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

catalog="$(bash bin/modules_json.sh)"

printf '%s\n' "$catalog" | jq -e '
  .kind == "audit-suite.modules"
  and .schema_version == "1.2.0"
  and .count == 10
  and .selectable_count == 6
  and .maturity_counts == {
    experimental: 5,
    partial: 1,
    placeholder: 3,
    deprecated: 1,
    unknown: 0
  }
' >/dev/null

printf '%s\n' "$catalog" | jq -e '
  all(.modules[];
    (.display_name | type == "string" and length > 0)
    and (.maturity | IN("experimental", "partial", "placeholder", "deprecated", "unknown"))
    and (.selectable | type == "boolean")
    and (.capabilities | type == "array")
    and (.intrusiveness | IN("none", "low", "moderate", "high", "unknown"))
    and (.privileges | type == "array")
    and (.requirements.commands | type == "array")
    and (.requirements.raw_socket_profiles | type == "array")
    and (.requirements.raw_socket_for_udp | type == "boolean")
  )
' >/dev/null

printf '%s\n' "$catalog" | jq -e '
  all(.modules[] | select(.maturity == "placeholder");
    (.selectable == false)
    and (.capabilities | length == 0)
    and (.limitations | type == "string" and length > 0)
  )
' >/dev/null

printf '%s\n' "$catalog" | jq -e '
  .modules[]
  | select(.id == "60_smb_enum")
  | .maturity == "partial"
    and .selectable == true
    and .capabilities == ["smb_port_detection"]
    and (.limitations | contains("uniquement les ports SMB 139/445"))
' >/dev/null

printf '%s\n' "$catalog" | jq -e '
  .modules[]
  | select(.id == "90_report_pack")
  | .maturity == "deprecated"
    and .selectable == false
    and (.capabilities | length == 0)
' >/dev/null

printf '%s\n' "$catalog" | jq -e '
  .report_pipeline.canonical_command == "bash bin/finalize_reports.sh <manifest.json>"
  and .report_pipeline.timing == "after_manifest"
  and .report_pipeline.legacy_module == "90_report_pack.sh"
' >/dev/null

tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

RUN_ID="CATALOG_PACK_TEST"
RUN_DIR="$tmp_root/output/$RUN_ID"
PROFILE="fast"
TARGETS="192.168.1.0/24"
mkdir -p "$RUN_DIR"
export RUN_ID RUN_DIR PROFILE TARGETS

partial_reason=""
module_mark_partial() {
  partial_reason="$*"
}
emit() {
  return 0
}

# shellcheck source=../modules/90_report_pack.sh
source "modules/90_report_pack.sh"
mod_run

[[ "$partial_reason" == *"canonical report pack"* ]]
[[ -f "$RUN_DIR/90_report_pack/MIGRATION.txt" ]]
if find "$tmp_root" -type f -name '*.tar.gz' -print -quit | grep -q .; then
  echo 'legacy report module still creates an archive' >&2
  exit 1
fi

printf '[OK] module catalog and report migration tests passed\n'
