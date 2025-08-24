#!/usr/bin/env bash
# ui/ui_tmux_logger.sh
# @version 0.1.0
set -Eeuo pipefail

[[ -z "${RUN_ID:-}" ]] && { echo "RUN_ID manquant"; exit 0; }
[[ -z "${LOG_FILE:-}" ]] && LOG_FILE="logs/$RUN_ID/combined.log"

if ! command -v tmux >/dev/null 2>&1; then
  exit 0
fi

SESSION="audit-$RUN_ID"
if ! tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux new-session -d -s "$SESSION" "tail -F '$LOG_FILE'"
  tmux split-window -v -t "$SESSION" "bash"
fi
