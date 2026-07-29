#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
RUNNER_LIB="$REPO_DIR/core/lib_runner.sh"

tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

mkdir -p "$tmp_root/core" "$tmp_root/modules" "$tmp_root/output/TEST_FAILURES" \
  "$tmp_root/logs/TEST_FAILURES" "$tmp_root/tmp"
cp "$REPO_DIR/core/lib_logging.sh" "$tmp_root/core/lib_logging.sh"

permission_probe="$tmp_root/permission-probe.sh"
cat >"$permission_probe" <<'PROBE'
#!/usr/bin/env bash
printf 'permission denied fixture\n' >&2
exit 126
PROBE
chmod +x "$permission_probe"

cat >"$tmp_root/modules/90_permission_probe.sh" <<'MODULE'
#!/usr/bin/env bash
MOD_ID="permission_probe"
MOD_NAME="Permission probe"
MOD_TIMEOUT=5
MOD_SKIP_OPTION="-"
MOD_REQUIRES=()

mod_pre() { :; }
mod_run() { "$PERMISSION_PROBE"; }
mod_post() { :; }
MODULE

cat >"$tmp_root/modules/91_signal_probe.sh" <<'MODULE'
#!/usr/bin/env bash
MOD_ID="signal_probe"
MOD_NAME="Signal probe"
MOD_TIMEOUT=5
MOD_SKIP_OPTION="-"
MOD_REQUIRES=()

mod_pre() { :; }
mod_run() { kill -TERM "$BASHPID"; }
mod_post() { :; }
MODULE

capture_file="$tmp_root/results.tsv"
(
  cd "$tmp_root"
  # shellcheck source=../core/lib_runner.sh
  source "$RUNNER_LIB"

  # Invoked indirectly by run_modules through Bash dynamic function lookup.
  # shellcheck disable=SC2329
  emit() { :; }
  # shellcheck disable=SC2329
  _append_module_result() {
    printf '%s\t%s\t%s\t%s\n' "$1" "$4" "$5" "${10:-}" >>"$capture_file"
  }

  RUN_ID="TEST_FAILURES"
  RUN_DIR="$tmp_root/output/$RUN_ID"
  LOG_DIR="$tmp_root/logs/$RUN_ID"
  LOG_FILE="$LOG_DIR/combined.log"
  LOG_BUS=""
  TMP_DIR="$tmp_root/tmp"
  TARGETS="192.168.1.0/24"
  PROFILE="fast"
  PERMISSION_PROBE="$permission_probe"
  export RUN_ID RUN_DIR LOG_DIR LOG_FILE LOG_BUS TMP_DIR TARGETS PROFILE
  export PERMISSION_PROBE

  run_modules "90_permission_probe.sh 91_signal_probe.sh" \
    >"$tmp_root/runner.out" 2>"$tmp_root/runner.err"
)

grep -Fq $'permission_probe\tfailed\t126\tmodule returned rc=126' "$capture_file"
grep -Fq $'signal_probe\tfailed\t143\tmodule returned rc=143' "$capture_file"

if compgen -G "$tmp_root/tmp/module_outcome.*" >/dev/null; then
  printf '[FAIL] module outcome marker was not cleaned after failure\n' >&2
  exit 1
fi

printf '[OK] runner permission and signal tests passed\n'
