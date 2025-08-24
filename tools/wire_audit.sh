#!/usr/bin/env bash
set -Eeuo pipefail
PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")"/.. && pwd)"
TARGET="${1:-$PROJECT_ROOT/audit.sh}"
[[ -f "$TARGET" ]] || { echo "FATAL: fichier introuvable: $TARGET" >&2; exit 1; }
grep -q '--- logging preamble ---' "$TARGET" && { echo "audit.sh déjà câblé avec lib_logging.sh"; exit 0; }
read -r -d '' PREAMBLE <<'PRE'
# --- logging preamble ---
PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$PROJECT_ROOT/core/lib_logging.sh" ]]; then
  # shellcheck source=/dev/null
  source "$PROJECT_ROOT/core/lib_logging.sh"
else
  echo "FATAL: core/lib_logging.sh not found relative to $PROJECT_ROOT" >&2
  exit 1
fi
RUN_ID="${RUN_ID:-AUDIT_$(date -u +%Y%m%dT%H%M%SZ)}"
init_logging "$RUN_ID"
emit INFO audit "START args: $*"
trap 'rc=$?; lvl=INFO; ((rc!=0)) && lvl=ERROR; emit "$lvl" audit "EXIT rc=$rc"; exit $rc' EXIT
# --- /logging preamble ---
PRE
tmp="$(mktemp)"
awk -v pre="$PREAMBLE\n" '
NR==1 && $0 ~ /^#!/ { print; print pre; next }
NR==1 && $0 !~ /^#!/ { print pre }
{ print }
' "$TARGET" >"$tmp"
install -m 0755 "$tmp" "$TARGET"
rm -f "$tmp"
echo "Préambule logging inséré dans: $TARGET"
