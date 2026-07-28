#!/usr/bin/env bash
# tests/test_logging.sh
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
LOGGING_LIB="$REPO_DIR/core/lib_logging.sh"

tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

without_tmux="$tmp_root/without-tmux"
mkdir -p "$without_tmux/tmp"

if ! timeout 2 env -u TMUX bash -c '
  set -Eeuo pipefail
  workdir="$1"
  logging_lib="$2"
  cd "$workdir"
  source "$logging_lib"
  init_logging TEST_RUN
  [[ -z "${LOG_BUS:-}" ]]
  emit INFO test "message without a FIFO reader"
' _ "$without_tmux" "$LOGGING_LIB"; then
  printf '[FAIL] logging blocked or failed without tmux\n' >&2
  exit 1
fi

if [[ -e "$without_tmux/tmp/eventbus.TEST_RUN" ]]; then
  printf '[FAIL] logging created an event-bus resource without a consumer\n' >&2
  exit 1
fi

log_file="$without_tmux/logs/TEST_RUN/combined.log"
if [[ ! -f "$log_file" ]]; then
  printf '[FAIL] combined log was not created\n' >&2
  exit 1
fi
if ! grep -Fq '[INFO] [test] message without a FIFO reader' "$log_file"; then
  printf '[FAIL] emitted message is missing from the combined log\n' >&2
  exit 1
fi

with_tmux="$tmp_root/with-tmux"
mkdir -p "$with_tmux/tmp"
mkfifo "$with_tmux/tmp/eventbus.TEST_RUN"

if ! timeout 2 env TMUX="fixture-session" bash -c '
  set -Eeuo pipefail
  workdir="$1"
  logging_lib="$2"
  cd "$workdir"
  source "$logging_lib"
  init_logging TEST_RUN
  [[ -z "${LOG_BUS:-}" ]]
  emit INFO test "message with tmux context and no FIFO reader"
' _ "$with_tmux" "$LOGGING_LIB"; then
  printf '[FAIL] logging blocked or failed with tmux context and an unread FIFO\n' >&2
  exit 1
fi

if [[ ! -p "$with_tmux/tmp/eventbus.TEST_RUN" ]]; then
  printf '[FAIL] fixture FIFO was unexpectedly replaced or removed\n' >&2
  exit 1
fi
if ! grep -Fq '[INFO] [test] message with tmux context and no FIFO reader' "$with_tmux/logs/TEST_RUN/combined.log"; then
  printf '[FAIL] tmux-context message is missing from the combined log\n' >&2
  exit 1
fi

printf '[OK] logging non-blocking tests passed\n'
