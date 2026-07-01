#!/usr/bin/env bash
# tests/test_args.sh
# Tests pour core/lib_args.sh
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

# shellcheck source=../core/lib_args.sh
source "core/lib_args.sh"

parse_audit_args \
  --profile fast \
  --targets 192.168.1.0/24 \
  --categories 10_network_discovery.sh,20_portscan_nmap.sh \
  --no-zeek \
  --no-suricata

[[ "$AUDIT_ARG_PROFILE" == "fast" ]]
[[ "$AUDIT_ARG_TARGETS" == "192.168.1.0/24" ]]
[[ "$AUDIT_ARG_CATEGORIES" == "10_network_discovery.sh,20_portscan_nmap.sh" ]]
[[ "$AUDIT_ARG_OPTS" == "no-zeek,no-suricata" ]]
[[ "$AUDIT_ARG_ALLOW_PUBLIC" == "0" ]]
[[ "$AUDIT_ARG_HELP" == "0" ]]

parse_audit_args \
  --profile=stealth \
  --targets=10.0.0.0/24 \
  --categories=70_http_enum.sh \
  --no-udp \
  --allow-public

[[ "$AUDIT_ARG_PROFILE" == "stealth" ]]
[[ "$AUDIT_ARG_TARGETS" == "10.0.0.0/24" ]]
[[ "$AUDIT_ARG_CATEGORIES" == "70_http_enum.sh" ]]
[[ "$AUDIT_ARG_OPTS" == "no-udp" ]]
[[ "$AUDIT_ARG_ALLOW_PUBLIC" == "1" ]]

parse_audit_args --help
[[ "$AUDIT_ARG_HELP" == "1" ]]

[[ "$(normalize_csv_to_commas 'a b,c
 d')" == "a,b,c,d" ]]

if parse_audit_args --profile invalid >/dev/null 2>&1; then
  echo 'invalid profile accepted' >&2
  exit 1
fi

if parse_audit_args --targets >/dev/null 2>&1; then
  echo 'missing targets value accepted' >&2
  exit 1
fi

if parse_audit_args --unknown >/dev/null 2>&1; then
  echo 'unknown option accepted' >&2
  exit 1
fi

printf '[OK] args tests passed\n'
