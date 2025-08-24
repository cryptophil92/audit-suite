#!/usr/bin/env bash
set -Eeuo pipefail
PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")"/.. && pwd)"
ok=1
check_file() { [[ -f "$1" ]] || { echo "MANQUE: $1"; ok=0; }; }
check_dir()  { [[ -d "$1" ]] || { echo "MANQUE: $1/"; ok=0; }; }
check_dir  "$PROJECT_ROOT/core"
check_dir  "$PROJECT_ROOT/scripts"
check_dir  "$PROJECT_ROOT/logs"
check_dir  "$PROJECT_ROOT/tmp"
check_file "$PROJECT_ROOT/core/lib_logging.sh"
check_file "$PROJECT_ROOT/audit.sh"
check_file "$PROJECT_ROOT/scripts/install_deps.sh"
check_file "$PROJECT_ROOT/.gitignore"
(( ok )) && echo "Structure OK." || { echo "Structure incomplète."; exit 1; }
