#!/usr/bin/env bash
set -Eeuo pipefail
PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")"/.. && pwd)"
GITIGNORE="$PROJECT_ROOT/.gitignore"
block='# === audit-suite standard ignore ===
/logs/
/tmp/
*.log
*.jsonl
*.pcap
*.pcapng
*.cache
*.tmp
*.swp
# === /audit-suite standard ignore ==='
touch "$GITIGNORE"
grep -q '=== audit-suite standard ignore ===' "$GITIGNORE" || { printf "%s\n" "$block" >>"$GITIGNORE"; echo "Ajout du bloc standard dans .gitignore"; }
