#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

# shellcheck source=../core/lib_preflight.sh
source "core/lib_preflight.sh"
# shellcheck source=../core/lib_detect.sh
source "core/lib_detect.sh"

empty_path="$(mktemp -d)"
trap 'rm -rf "$empty_path"' EXIT

original_path="$PATH"
PATH="$empty_path"
detect_env
PATH="$original_path"
[[ -z "$DEF_IFACE" ]]
[[ -z "$DEF_CIDR" ]]

PROFILE="full"
OPTS_NO_UDP=0
OPTS_NO_ZEEK=0
OPTS_NO_SURICATA=0
export PROFILE OPTS_NO_UDP OPTS_NO_ZEEK OPTS_NO_SURICATA

degraded_output="$(
  AUDIT_PREFLIGHT_FORCE_MISSING_COMMANDS="ip python3 whatweb" \
  AUDIT_PREFLIGHT_FORCE_AVAILABLE_COMMANDS="jq timeout nmap" \
  AUDIT_PREFLIGHT_FORCE_RAW_SOCKET=0 \
  preflight_run "20_portscan_nmap.sh 70_http_enum.sh"
)"

printf '%s\n' "$degraded_output" | grep -Fq \
  '[DÉGRADÉ] Environnement réseau : commande ip absente. Installez iproute2'
printf '%s\n' "$degraded_output" | grep -Fq \
  '[INFO] API locale : Python 3 absent. Installez Python 3.10+'
printf '%s\n' "$degraded_output" | grep -Fq \
  '[DÉGRADÉ] Portscan Nmap : sockets brutes indisponibles.'
printf '%s\n' "$degraded_output" | grep -Fq \
  'scan TCP connect (-sT), sans détection OS, et UDP ignoré'
printf '%s\n' "$degraded_output" | grep -Fq \
  '[IGNORÉ] HTTP enum : commande(s) manquante(s) : whatweb.'
printf '%s\n' "$degraded_output" | grep -Fq \
  '[PRÊT] Le lancement peut continuer avec les limites annoncées ci-dessus.'

if blocker_output="$(
  AUDIT_PREFLIGHT_FORCE_MISSING_COMMANDS="timeout" \
  AUDIT_PREFLIGHT_FORCE_AVAILABLE_COMMANDS="jq" \
  AUDIT_PREFLIGHT_FORCE_RAW_SOCKET=1 \
  preflight_run ""
)"; then
  printf '[FAIL] missing core command did not block preflight\n' >&2
  exit 1
fi

printf '%s\n' "$blocker_output" | grep -Fq \
  '[BLOQUANT] Socle moteur : timeout manque.'
printf '%s\n' "$blocker_output" | grep -Fq \
  '[ARRÊT] Corrigez les éléments bloquants ci-dessus'

status_json="$(
  AUDIT_PREFLIGHT_FORCE_MISSING_COMMANDS="ip python3" \
  AUDIT_PREFLIGHT_FORCE_RAW_SOCKET=0 \
  bash bin/status_json.sh
)"

printf '%s\n' "$status_json" | jq -e \
  '.capabilities.environment_detection.iproute2_available == false' >/dev/null
printf '%s\n' "$status_json" | jq -e \
  '.capabilities.api.python3_available == false' >/dev/null
printf '%s\n' "$status_json" | jq -e \
  '.capabilities.api.minimum_version_met == false' >/dev/null
printf '%s\n' "$status_json" | jq -e \
  '.capabilities.privileges.raw_socket_available == false' >/dev/null
printf '%s\n' "$status_json" | jq -e \
  '(.capabilities | tostring | test("interface|cidr|username|uid|path"; "i") | not)' >/dev/null

printf '[OK] guided preflight tests passed\n'
