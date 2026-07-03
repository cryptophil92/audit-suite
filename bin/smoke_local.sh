#!/usr/bin/env bash
# bin/smoke_local.sh
# @version 0.2.28
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

SMOKE_TARGET="${SMOKE_TARGET:-192.168.1.0/24}"
SMOKE_RUN_ID="${SMOKE_RUN_ID:-SMOKE_LOCAL}"

if [[ -z "${SMOKE_HISTORY_DIR:-}" ]]; then
  SMOKE_HISTORY_DIR="$(mktemp -d)"
  _SMOKE_TMP_HISTORY_CREATED=1
fi

cleanup() {
  rm -f /tmp/audit-suite-smoke.out
  if [[ -n "${_SMOKE_TMP_HISTORY_CREATED:-}" && -d "$SMOKE_HISTORY_DIR" ]]; then
    rm -rf "$SMOKE_HISTORY_DIR"
  fi
}

trap cleanup EXIT
export SMOKE_TARGET SMOKE_RUN_ID
export AUDIT_HISTORY_DIR="$SMOKE_HISTORY_DIR/history"

usage_smoke_local() {
  cat <<'EOF'
Usage: bash bin/smoke_local.sh

Environment:
  SMOKE_TARGET       CIDR cible privée utilisée pour dry-run et plan JSON.
  SMOKE_RUN_ID       Run ID utilisé pour dry-run et plan JSON.
  SMOKE_HISTORY_DIR  Dossier temporaire d'historique pour le smoke test.
EOF
}

require_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    echo "jq requis pour le smoke test." >&2
    return 1
  fi
}

smoke_step() {
  local name="$1"
  shift

  printf '[SMOKE] %s... ' "$name"
  "$@" >/tmp/audit-suite-smoke.out
  printf 'OK\n'
}

case "${1:-}" in
  -h|--help)
    usage_smoke_local
    exit 0
    ;;
  "")
    ;;
  *)
    echo "Option inconnue: $1" >&2
    usage_smoke_local >&2
    exit 2
    ;;
esac

require_jq

smoke_step "version_json" bash -c 'bash bin/version_json.sh | jq -e ".kind == \"audit-suite.version\"" >/dev/null'
smoke_step "modules_json" bash -c 'bash bin/modules_json.sh | jq -e ".kind == \"audit-suite.modules\"" >/dev/null'
smoke_step "status_json" bash -c 'bash bin/status_json.sh | jq -e ".kind == \"audit-suite.status\"" >/dev/null'
smoke_step "history_json" bash -c 'bash bin/history_json.sh list | jq -e ".kind == \"audit-suite.history\"" >/dev/null'
smoke_step "plan_json" bash -c 'bash bin/plan_json.sh --profile fast --targets "$SMOKE_TARGET" --categories all --run-id "$SMOKE_RUN_ID" --no-zeek --no-suricata | jq -e ".kind == \"audit-suite.plan\"" >/dev/null'
smoke_step "api_snapshot" bash -c 'bash bin/api_snapshot_json.sh | jq -e ".kind == \"audit-suite.api_snapshot\"" >/dev/null'
smoke_step "audit_dry_run" bash -c 'bash audit.sh --dry-run --profile fast --targets "$SMOKE_TARGET" --categories all --run-id "$SMOKE_RUN_ID" --no-zeek --no-suricata | grep -q "AUDIT-SUITE dry run"'

printf '[OK] local smoke test passed\n'
