#!/usr/bin/env bash
set -Eeuo pipefail
RUN_ID="${1:-}"; [[ -z "$RUN_ID" ]] && exit 0
if command -v tmux >/dev/null 2>&1; then
  sess="audit-$RUN_ID"
  tmux has-session -t "$sess" 2>/dev/null || tmux new-session -d -s "$sess" "tail -F logs/$RUN_ID/combined.log"
fi
