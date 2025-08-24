#!/usr/bin/env bash
set -Eeuo pipefail
PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")"/.. && pwd)"
mkdir -p "$PROJECT_ROOT/core" "$PROJECT_ROOT/scripts" "$PROJECT_ROOT/logs" "$PROJECT_ROOT/tmp" "$PROJECT_ROOT/reports"
chmod 700 "$PROJECT_ROOT/logs" "$PROJECT_ROOT/tmp" 2>/dev/null || true
[[ -f "$PROJECT_ROOT/core/lib_logging.sh" ]] && chmod +x "$PROJECT_ROOT/core/lib_logging.sh" || true
printf 'Arborescence audit-suite OK → %s\n' "$PROJECT_ROOT"
