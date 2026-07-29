#!/usr/bin/env bash
# bin/modules_json.sh
# @version 0.4.0
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

# shellcheck source=../core/lib_args.sh
source "core/lib_args.sh"
# shellcheck source=../core/lib_modules.sh
source "core/lib_modules.sh"

usage_modules_json() {
  cat <<'EOF'
Usage: bash bin/modules_json.sh

Options:
  -h, --help
EOF
}

require_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    echo "jq requis pour produire le catalogue JSON." >&2
    return 1
  fi
}

module_id_from_name() {
  local name="$1"
  printf '%s\n' "${name%.sh}"
}

module_order_from_name() {
  local name="$1"
  local id

  id="$(module_id_from_name "$name")"
  if [[ "$id" =~ ^([0-9]+)_ ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}"
  else
    printf '999\n'
  fi
}

module_requirements_metadata() {
  local module="$1"

  bash -c '
    set -Eeuo pipefail
    module="$1"
    # shellcheck source=/dev/null
    source "core/lib_logging.sh"
    # shellcheck source=/dev/null
    source "$module" >/dev/null

    : "${MOD_RAW_SOCKET_FOR_UDP:=0}"
    : "${MOD_RAW_SOCKET_FALLBACK:=}"
    : "${MOD_NAME:=Unknown}"
    : "${MOD_MATURITY:=experimental}"
    : "${MOD_INTRUSIVENESS:=unknown}"
    : "${MOD_SELECTABLE:=1}"
    : "${MOD_LIMITATIONS:=}"

    requires=""
    if declare -p MOD_REQUIRES >/dev/null 2>&1; then
      if declare -p MOD_REQUIRES 2>/dev/null | grep -q "declare -[aA]"; then
        requires="${MOD_REQUIRES[*]}"
      else
        requires="$MOD_REQUIRES"
      fi
    fi

    raw_profiles=""
    if declare -p MOD_RAW_SOCKET_PROFILES >/dev/null 2>&1; then
      if declare -p MOD_RAW_SOCKET_PROFILES 2>/dev/null | grep -q "declare -[aA]"; then
        raw_profiles="${MOD_RAW_SOCKET_PROFILES[*]}"
      else
        raw_profiles="$MOD_RAW_SOCKET_PROFILES"
      fi
    fi

    capabilities=""
    if declare -p MOD_CAPABILITIES >/dev/null 2>&1; then
      if declare -p MOD_CAPABILITIES 2>/dev/null | grep -q "declare -[aA]"; then
        capabilities="${MOD_CAPABILITIES[*]}"
      else
        capabilities="$MOD_CAPABILITIES"
      fi
    fi

    privileges=""
    if declare -p MOD_PRIVILEGES >/dev/null 2>&1; then
      if declare -p MOD_PRIVILEGES 2>/dev/null | grep -q "declare -[aA]"; then
        privileges="${MOD_PRIVILEGES[*]}"
      else
        privileges="$MOD_PRIVILEGES"
      fi
    fi

    printf "%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s\n" \
      "$requires" "$raw_profiles" "$MOD_RAW_SOCKET_FOR_UDP" "$MOD_RAW_SOCKET_FALLBACK" \
      "$MOD_NAME" "$MOD_MATURITY" "$capabilities" "$MOD_INTRUSIVENESS" \
      "$privileges" "$MOD_SELECTABLE" "$MOD_LIMITATIONS"
  ' _ "$module"
}

emit_modules_json() {
  local tmp_json
  local module name id order executable metadata
  local requires raw_profiles raw_for_udp fallback display_name maturity
  local capabilities intrusiveness privileges selectable limitations

  tmp_json="$(mktemp)"
  printf '[]\n' > "$tmp_json"

  while IFS= read -r module; do
    [[ -z "$module" ]] && continue
    name="$(module_name_from_token "$module")"
    id="$(module_id_from_name "$name")"
    order="$(module_order_from_name "$name")"
    executable=false
    [[ -x "$module" ]] && executable=true
    metadata="$(module_requirements_metadata "$module")"
    IFS='|' read -r requires raw_profiles raw_for_udp fallback display_name maturity \
      capabilities intrusiveness privileges selectable limitations <<< "$metadata"

    case "$maturity" in
      experimental|partial|placeholder|deprecated) ;;
      *) maturity="unknown" ;;
    esac
    case "$intrusiveness" in
      none|low|moderate|high) ;;
      *) intrusiveness="unknown" ;;
    esac
    [[ "$selectable" == "1" ]] || selectable=0

    tmp_next="$(mktemp)"
    jq \
      --arg id "$id" \
      --arg name "$name" \
      --arg path "$module" \
      --argjson order "$order" \
      --argjson executable "$executable" \
      --arg requires "$requires" \
      --arg raw_profiles "$raw_profiles" \
      --arg raw_for_udp "$raw_for_udp" \
      --arg fallback "$fallback" \
      --arg display_name "$display_name" \
      --arg maturity "$maturity" \
      --arg capabilities "$capabilities" \
      --arg intrusiveness "$intrusiveness" \
      --arg privileges "$privileges" \
      --arg selectable "$selectable" \
      --arg limitations "$limitations" \
      '. + [{
        id: $id,
        name: $name,
        display_name: $display_name,
        path: $path,
        order: $order,
        executable: $executable,
        maturity: $maturity,
        selectable: ($selectable == "1"),
        capabilities: ($capabilities | split(" ") | map(select(length > 0))),
        intrusiveness: $intrusiveness,
        privileges: ($privileges | split(" ") | map(select(length > 0))),
        limitations: (if $limitations == "" then null else $limitations end),
        requirements: {
          commands: ($requires | split(" ") | map(select(length > 0))),
          raw_socket_profiles: ($raw_profiles | split(" ") | map(select(length > 0))),
          raw_socket_for_udp: ($raw_for_udp == "1"),
          degraded_fallback: (if $fallback == "" then null else $fallback end)
        }
      }]' \
      "$tmp_json" > "$tmp_next"
    mv "$tmp_next" "$tmp_json"
  done < <(modules_discover_sorted)

  jq -n \
    --arg kind "audit-suite.modules" \
    --arg schema_version "1.2.0" \
    --slurpfile modules "$tmp_json" \
    '($modules[0]) as $items
    | {
      kind: $kind,
      schema_version: $schema_version,
      count: ($items | length),
      selectable_count: ([$items[] | select(.selectable)] | length),
      maturity_counts: {
        experimental: ([$items[] | select(.maturity == "experimental")] | length),
        partial: ([$items[] | select(.maturity == "partial")] | length),
        placeholder: ([$items[] | select(.maturity == "placeholder")] | length),
        deprecated: ([$items[] | select(.maturity == "deprecated")] | length),
        unknown: ([$items[] | select(.maturity == "unknown")] | length)
      },
      report_pipeline: {
        canonical_command: "bash bin/finalize_reports.sh <manifest.json>",
        timing: "after_manifest",
        legacy_module: "90_report_pack.sh",
        compatibility: "preserved_but_not_selectable_and_creates_no_archive"
      },
      modules: $items
    }'

  rm -f "$tmp_json"
}

case "${1:-}" in
  -h|--help)
    usage_modules_json
    exit 0
    ;;
  "")
    ;;
  *)
    echo "Option inconnue: $1" >&2
    usage_modules_json >&2
    exit 2
    ;;
esac

require_jq
emit_modules_json
