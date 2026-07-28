#!/usr/bin/env bash
# tests/test_run_paths.sh
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

# shellcheck source=../core/lib_run_paths.sh
source "core/lib_run_paths.sh"

run_id="RUN_PATH_TEST_$$"
out_file="/tmp/run-path-test.out"
err_file="/tmp/run-path-test.err"

cleanup() {
  rm -rf "output/$run_id" "logs/$run_id"
  rm -f "$out_file" "$err_file" "$out_file.1" "$out_file.2" "$err_file.1" "$err_file.2"
}
trap cleanup EXIT
cleanup

[[ "$(run_output_path "$run_id")" == "output/$run_id" ]]
[[ "$(run_log_path "$run_id")" == "logs/$run_id" ]]

validate_run_paths_available "$run_id"

mkdir -p "output/$run_id"
if validate_run_paths_available "$run_id" >"$out_file" 2>"$err_file"; then
  echo 'existing output path accepted' >&2
  exit 1
fi
grep -q "Chemin déjà existant: output/$run_id" "$err_file"
rm -rf "output/$run_id"

mkdir -p "logs/$run_id"
if validate_run_paths_available "$run_id" >"$out_file" 2>"$err_file"; then
  echo 'existing log path accepted' >&2
  exit 1
fi
grep -q "Chemin déjà existant: logs/$run_id" "$err_file"
rm -rf "logs/$run_id"

reserve_run_paths "$run_id" >"$out_file.1" 2>"$err_file.1" &
pid_one=$!
reserve_run_paths "$run_id" >"$out_file.2" 2>"$err_file.2" &
pid_two=$!

success_count=0
if wait "$pid_one"; then
  success_count=$((success_count + 1))
fi
if wait "$pid_two"; then
  success_count=$((success_count + 1))
fi

[[ "$success_count" == "1" ]]
[[ -d "output/$run_id" ]]
[[ -d "logs/$run_id" ]]
grep -q "Identifiant déjà utilisé: $run_id" "$err_file.1" "$err_file.2"

printf '[OK] run path tests passed\n'
