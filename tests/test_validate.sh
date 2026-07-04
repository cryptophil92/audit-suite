#!/usr/bin/env bash
# tests/test_validate.sh
# Tests simples pour core/lib_validate.sh
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

# shellcheck source=../core/lib_validate.sh
source "core/lib_validate.sh"

pass_count=0
fail_count=0

pass() {
  printf '[OK] %s\n' "$1"
  pass_count=$((pass_count + 1))
}

fail() {
  printf '[FAIL] %s\n' "$1" >&2
  fail_count=$((fail_count + 1))
}

expect_ok() {
  local name="$1"
  local targets="$2"
  local allow_public="${3:-0}"

  if validate_targets "$targets" "$allow_public" >/dev/null 2>&1; then
    pass "$name"
  else
    fail "$name"
  fi
}

expect_fail() {
  local name="$1"
  local targets="$2"
  local allow_public="${3:-0}"

  if validate_targets "$targets" "$allow_public" >/dev/null 2>&1; then
    fail "$name"
  else
    pass "$name"
  fi
}

expect_ok "private IPv4" "192.168.1.10"
expect_ok "private CIDR" "192.168.1.0/24"
expect_ok "multiple private targets" "192.168.1.0/24,10.10.10.5"
expect_ok "cgnat target" "100.64.0.1"
expect_ok "link local target" "169.254.10.20"
expect_ok "public allowed explicitly" "8.8.8.8" "1"

expect_fail "public IPv4 blocked" "8.8.8.8"
expect_fail "public CIDR blocked" "8.8.8.0/24"
expect_fail "hostname blocked" "example.com"
expect_fail "url blocked" "https://example.com"
expect_fail "invalid octet" "192.168.1.999"
expect_fail "leading zero blocked" "192.168.001.1"
expect_fail "invalid prefix" "192.168.1.0/33"
expect_fail "mixed valid and invalid fails" "192.168.1.0/24,example.com"

printf '\nTests réussis: %d\nTests échoués: %d\n' "$pass_count" "$fail_count"

if (( fail_count > 0 )); then
  exit 1
fi
