#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
TEST_RUNNER="$REPO_DIR/bin/test_all.sh"

tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

success_root="$tmp_root/success tests"
failure_root="$tmp_root/failure tests"
mkdir -p "$success_root" "$failure_root"

export DISCOVERY_LOG="$tmp_root/discovery.log"
smoke_script="$tmp_root/smoke.sh"

cat >"$success_root/test_10_shell.sh" <<'TEST'
#!/usr/bin/env bash
printf 'shell\n' >>"$DISCOVERY_LOG"
TEST

cat >"$success_root/test_20_python.py" <<'TEST'
import os

with open(os.environ["DISCOVERY_LOG"], "a", encoding="utf-8") as handle:
    handle.write("python\n")
TEST

cat >"$smoke_script" <<'TEST'
#!/usr/bin/env bash
printf 'smoke\n' >>"$DISCOVERY_LOG"
TEST

AUDIT_SUITE_TEST_ROOT="$success_root" \
AUDIT_SUITE_SMOKE_SCRIPT="$smoke_script" \
  bash "$TEST_RUNNER" >"$tmp_root/success.out"

cat >"$tmp_root/expected-success.log" <<'EXPECTED'
shell
python
smoke
EXPECTED
tr -d '\r' <"$DISCOVERY_LOG" >"$tmp_root/discovery-normalized.log"
cmp "$tmp_root/expected-success.log" "$tmp_root/discovery-normalized.log"
grep -Fq '[SUMMARY] 3/3 checks passed; 0 failed' "$tmp_root/success.out"

: >"$DISCOVERY_LOG"
cat >"$failure_root/test_10_before.sh" <<'TEST'
#!/usr/bin/env bash
printf 'before\n' >>"$DISCOVERY_LOG"
TEST

cat >"$failure_root/test_20_failure.py" <<'TEST'
import os

with open(os.environ["DISCOVERY_LOG"], "a", encoding="utf-8") as handle:
    handle.write("failure\n")
raise SystemExit(7)
TEST

cat >"$failure_root/test_30_after.sh" <<'TEST'
#!/usr/bin/env bash
printf 'after\n' >>"$DISCOVERY_LOG"
TEST

if AUDIT_SUITE_TEST_ROOT="$failure_root" \
  AUDIT_SUITE_SMOKE_SCRIPT="$smoke_script" \
  bash "$TEST_RUNNER" >"$tmp_root/failure.out" 2>"$tmp_root/failure.err"; then
  printf '[FAIL] test runner accepted a failing discovered test\n' >&2
  exit 1
fi

cat >"$tmp_root/expected-failure.log" <<'EXPECTED'
before
failure
after
smoke
EXPECTED
tr -d '\r' <"$DISCOVERY_LOG" >"$tmp_root/discovery-normalized.log"
cmp "$tmp_root/expected-failure.log" "$tmp_root/discovery-normalized.log"
grep -Fq '[FAIL]' "$tmp_root/failure.err"
grep -Fq '[SUMMARY] 3/4 checks passed; 1 failed' "$tmp_root/failure.out"

printf '[OK] automatic test discovery tests passed\n'
