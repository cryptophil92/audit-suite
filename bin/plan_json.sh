#!/usr/bin/env bash
# bin/plan_json.sh
# @version 0.2.13
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

# shellcheck source=../core/lib_args.sh
source "core/lib_args.sh"
# shellcheck source=../core/lib_validate.sh
source "core/lib_validate.sh"
# shellcheck source=../core/lib_modules.sh
source "core/lib_modules.sh"
# shellcheck source=../core/lib_run_paths.sh
source "core/lib_run_paths.sh"

usage_plan_json() {
  cat <<'EOF'
Usage: bash bin/plan_json.sh --targets <cidr[,cidr...]> [options]

Options:
  --profile <fast|full|stealth>
  --targets <cidr[,cidr...]>
  --categories <module[,module...]|all>
  --run-id <id>
  --no-udp
  --no-zeek
  --no-suricata
  --allow-public
  -h, --help
EOF
}

require_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    echo "jq requis pour produire le plan JSON." >&2
    return 1
  fi
}

resolve_plan_run_id() {
  if [[ -n "${AUDIT_ARG_RUN_ID:-}" ]]; then
    printf '%s\n' "$AUDIT_ARG_RUN_ID"
  else
    printf 'AUDIT_%s\n' "$(date -u +%Y%m%dT%H%M%SZ)"
  fi
}

emit_plan_json() {
  local run_id="$1"
  local profile="$2"
  local targets="$3"
  local categories="$4"
  local selected="$5"
  local opts="$6"
  local allow_public="$7"
  local no_udp="$8"
  local no_zeek="$9"
  local no_suricata="${10}"

  jq -n \
    --arg kind "audit-suite.plan" \
    --arg schema_version "1.0.0" \
    --arg run_id "$run_id" \
    --arg profile "$profile" \
    --arg targets "$targets" \
    --arg categories "$categories" \
    --arg selected_modules "$selected" \
    --arg opts "$opts" \
    --argjson allow_public "$allow_public" \
    --argjson no_udp "$no_udp" \
    --argjson no_zeek "$no_zeek" \
    --argjson no_suricata "$no_suricata" \
    --arg output_path "$(run_output_path "$run_id")" \
    --arg log_path "$(run_log_path "$run_id")" \
    '{
      kind: $kind,
      schema_version: $schema_version,
      run_id: $run_id,
      profile: $profile,
      targets: ($targets | split(",") | map(select(length > 0))),
      categories: $categories,
      selected_modules: ($selected_modules | split(" ") | map(select(length > 0))),
      options: {
        raw: $opts,
        allow_public: $allow_public,
        no_udp: $no_udp,
        no_zeek: $no_zeek,
        no_suricata: $no_suricata
      },
      paths: {
        output: $output_path,
        logs: $log_path
      }
    }'
}

if ! parse_audit_args "$@"; then
  usage_plan_json >&2
  exit 2
fi

if [[ "$AUDIT_ARG_HELP" == "1" ]]; then
  usage_plan_json
  exit 0
fi

require_jq

PROFILE="$AUDIT_ARG_PROFILE"
[[ -z "${PROFILE:-}" ]] && PROFILE="fast"

TARGETS="$AUDIT_ARG_TARGETS"
[[ -z "${TARGETS:-}" ]] && {
  echo "Aucune cible fournie." >&2
  exit 1
}

ALLOW_PUBLIC="$AUDIT_ARG_ALLOW_PUBLIC"
if ! TARGETS="$(validate_targets "$TARGETS" "$ALLOW_PUBLIC")"; then
  echo "Validation des cibles échouée." >&2
  exit 1
fi

CATEGORIES="$AUDIT_ARG_CATEGORIES"
[[ -z "${CATEGORIES:-}" ]] && CATEGORIES="all"
CATEGORIES="$(normalize_csv_to_commas "$CATEGORIES")"

if ! validate_selected_modules "$CATEGORIES"; then
  echo "Sélection de modules invalide." >&2
  exit 1
fi

OPTS="$(normalize_csv_to_commas "$AUDIT_ARG_OPTS")"
OPTS_NO_UDP=0; OPTS_NO_ZEEK=0; OPTS_NO_SURICATA=0
[[ "$OPTS" == *"no-udp"* ]] && OPTS_NO_UDP=1
[[ "$OPTS" == *"no-zeek"* ]] && OPTS_NO_ZEEK=1
[[ "$OPTS" == *"no-suricata"* ]] && OPTS_NO_SURICATA=1

RUN_ID="$(resolve_plan_run_id)"
SELECTED="$(selected_modules_to_runner_args "$CATEGORIES")"

emit_plan_json "$RUN_ID" "$PROFILE" "$TARGETS" "$CATEGORIES" "$SELECTED" "$OPTS" "$ALLOW_PUBLIC" "$OPTS_NO_UDP" "$OPTS_NO_ZEEK" "$OPTS_NO_SURICATA"
