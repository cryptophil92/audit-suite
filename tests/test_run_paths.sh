#!/usr/bin/env bash
# tests/test_run_paths.sh
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

# shellcheck source=../core/lib_run_paths.sh
source "core/lib_run_paths.sh"

run_id="RUN_PATH_TEST"
out_file="/tmp/run-path-test.out"
err_file="/tmp/run-path-test.err"

rm -rf "output/$run_id" "logs/$run_id" "$out_file" "$err_file"

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
rm -rf "logs/$run_id" "$out_file" "$err_file"

printf '[OK] run path tests passed\n'
