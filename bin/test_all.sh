#!/usr/bin/env bash
# Discover and run the complete deterministic test suite without a real scan.
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
TEST_ROOT="${AUDIT_SUITE_TEST_ROOT:-$REPO_DIR/tests}"
SMOKE_SCRIPT="${AUDIT_SUITE_SMOKE_SCRIPT:-$REPO_DIR/bin/smoke_local.sh}"
RUN_SMOKE="${AUDIT_SUITE_RUN_SMOKE:-1}"
PYTHON_COMMAND="${AUDIT_SUITE_PYTHON:-}"

if [[ ! -d "$TEST_ROOT" ]]; then
  printf '[FAIL] test directory not found: %s\n' "$TEST_ROOT" >&2
  exit 1
fi
if [[ "$RUN_SMOKE" != "0" && "$RUN_SMOKE" != "1" ]]; then
  printf '[FAIL] AUDIT_SUITE_RUN_SMOKE must be 0 or 1\n' >&2
  exit 1
fi
if [[ -z "$PYTHON_COMMAND" ]]; then
  if command -v python3 >/dev/null 2>&1; then
    PYTHON_COMMAND="python3"
  elif command -v python >/dev/null 2>&1; then
    PYTHON_COMMAND="python"
  fi
fi

mapfile -d '' -t test_files < <(
  find "$TEST_ROOT" -maxdepth 1 -type f \
    \( -name 'test_*.sh' -o -name 'test_*.py' \) \
    -print0 \
    | LC_ALL=C sort -z
)

if (( ${#test_files[@]} == 0 )); then
  printf '[FAIL] no test_*.sh or test_*.py file found in %s\n' "$TEST_ROOT" >&2
  exit 1
fi

total=0
passed=0
failed=0

run_check() {
  local label="$1"
  shift
  local rc

  ((total += 1))
  printf '\n[TEST] %s\n' "$label"

  set +e
  "$@"
  rc=$?
  set -e

  if (( rc == 0 )); then
    ((passed += 1))
    printf '[PASS] %s\n' "$label"
  else
    ((failed += 1))
    printf '[FAIL] %s (rc=%s)\n' "$label" "$rc" >&2
  fi
}

for test_file in "${test_files[@]}"; do
  label="${test_file#"$REPO_DIR"/}"
  case "$test_file" in
    *.sh)
      run_check "$label" bash "$test_file"
      ;;
    *.py)
      if [[ -n "$PYTHON_COMMAND" ]] && command -v "$PYTHON_COMMAND" >/dev/null 2>&1; then
        run_check "$label" "$PYTHON_COMMAND" "$test_file"
      else
        run_check "$label" bash -c 'printf "[FAIL] Python 3 is required\n" >&2; exit 127'
      fi
      ;;
  esac
done

if [[ "$RUN_SMOKE" == "1" ]]; then
  if [[ -f "$SMOKE_SCRIPT" ]]; then
    run_check "${SMOKE_SCRIPT#"$REPO_DIR"/}" bash "$SMOKE_SCRIPT"
  else
    run_check "$SMOKE_SCRIPT" bash -c 'printf "[FAIL] smoke script not found\n" >&2; exit 1'
  fi
fi

printf '\n[SUMMARY] %s/%s checks passed; %s failed\n' "$passed" "$total" "$failed"
(( failed == 0 ))
