#!/usr/bin/env bash
# tests/test_runtime_artifact_guard.sh
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
GUARD="$REPO_DIR/bin/check_no_new_runtime_artifacts.sh"

tmp_repo="$(mktemp -d)"
trap 'rm -rf "$tmp_repo"' EXIT

git -C "$tmp_repo" init -q
git -C "$tmp_repo" config user.name "Audit Suite CI"
git -C "$tmp_repo" config user.email "ci@example.invalid"

mkdir -p "$tmp_repo/history"
printf 'baseline\n' >"$tmp_repo/history/legacy.json"
printf '# fixture\n' >"$tmp_repo/README.md"
git -C "$tmp_repo" add README.md history/legacy.json
git -C "$tmp_repo" commit -qm "baseline with legacy artifact"
baseline="$(git -C "$tmp_repo" rev-parse HEAD)"

mkdir -p "$tmp_repo/docs"
printf 'allowed\n' >"$tmp_repo/docs/change.md"
git -C "$tmp_repo" add docs/change.md
git -C "$tmp_repo" commit -qm "allowed documentation change"
allowed="$(git -C "$tmp_repo" rev-parse HEAD)"

(
  cd "$tmp_repo"
  bash "$GUARD" "$baseline" "$allowed" >/dev/null
)

mkdir -p "$tmp_repo/output"
printf 'changed\n' >>"$tmp_repo/history/legacy.json"
printf 'sensitive fixture\n' >"$tmp_repo/output/sensitive-result.json"
git -C "$tmp_repo" add history/legacy.json output/sensitive-result.json
git -C "$tmp_repo" commit -qm "forbidden runtime artifacts"
forbidden="$(git -C "$tmp_repo" rev-parse HEAD)"

set +e
guard_output="$(
  cd "$tmp_repo"
  bash "$GUARD" "$allowed" "$forbidden" 2>&1
)"
guard_rc=$?
set -e

if [[ "$guard_rc" != "2" ]]; then
  printf '[FAIL] expected guard exit 2, got %s\n' "$guard_rc" >&2
  exit 1
fi
if [[ "$guard_output" != *"output/"* || "$guard_output" != *"history/"* ]]; then
  printf '[FAIL] expected affected categories in guard output\n' >&2
  exit 1
fi
if [[ "$guard_output" == *"sensitive-result.json"* || "$guard_output" == *"legacy.json"* ]]; then
  printf '[FAIL] guard output disclosed a runtime artifact file name\n' >&2
  exit 1
fi

git -C "$tmp_repo" rm -q history/legacy.json output/sensitive-result.json
git -C "$tmp_repo" commit -qm "remove legacy runtime artifacts"
cleanup="$(git -C "$tmp_repo" rev-parse HEAD)"
(
  cd "$tmp_repo"
  bash "$GUARD" "$forbidden" "$cleanup" >/dev/null
)

printf 'candidate\n' >"$tmp_repo/docs/candidate.txt"
git -C "$tmp_repo" add docs/candidate.txt
git -C "$tmp_repo" commit -qm "add allowed candidate"
before_rename="$(git -C "$tmp_repo" rev-parse HEAD)"
mkdir -p "$tmp_repo/tmp"
git -C "$tmp_repo" mv docs/candidate.txt tmp/renamed-result.txt
git -C "$tmp_repo" commit -qm "rename candidate into runtime directory"
after_rename="$(git -C "$tmp_repo" rev-parse HEAD)"

set +e
(
  cd "$tmp_repo"
  bash "$GUARD" "$before_rename" "$after_rename" >/dev/null 2>&1
)
rename_rc=$?
set -e
if [[ "$rename_rc" != "2" ]]; then
  printf '[FAIL] expected rename guard exit 2, got %s\n' "$rename_rc" >&2
  exit 1
fi

printf '[OK] runtime artifact guard tests passed\n'
