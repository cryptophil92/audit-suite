#!/usr/bin/env bash
set -Eeuo pipefail
PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")"/.. && pwd)"
# shellcheck source=/dev/null
source "$PROJECT_ROOT/core/lib_logging.sh"
RID="SELFTEST_$(date -u +%Y%m%dT%H%M%SZ)"
init_logging "$RID"
emit INFO selftest "hello world"
with_log demo bash -c 'echo out; echo err 1>&2'
! with_log demo-fail bash -c 'echo will-fail; echo err 1>&2; exit 3' || true
echo "Log dir: $PROJECT_ROOT/logs/$RID"
tail -n3 "$PROJECT_ROOT/logs/$RID/combined.log" || true
tail -n1 "$PROJECT_ROOT/logs/$RID/events.jsonl" || true
