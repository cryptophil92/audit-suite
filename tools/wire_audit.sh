#!/usr/bin/env bash
set -Eeuo pipefail
PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")"/.. && pwd)"

FORCE=0
if [[ "${1:-}" == "--force" ]]; then FORCE=1; shift; fi

TARGET="${1:-$PROJECT_ROOT/audit.sh}"
[[ -f "$TARGET" ]] || { echo "FATAL: fichier introuvable: $TARGET" >&2; exit 1; }

if (( FORCE == 0 )); then
  if grep -q -- '# --- logging preamble ---' "$TARGET"; then
    echo "audit.sh déjà câblé (utilise --force pour réécrire)."
    exit 0
  fi
fi

read -r -d '' PREAMBLE <<'PRE'
# --- logging preamble ---
__resolve_root() {
  local here; here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  local cand
  for cand in "$here" "$here/.." "$(git -C "$here" rev-parse --show-toplevel 2>/dev/null || true)"; do
    [[ -n "$cand" && -f "$cand/core/lib_logging.sh" ]] && { cd -- "$cand" && pwd; return 0; }
  done
  printf '%s\n' "$here"
}
readonly PROJECT_ROOT="$(__resolve_root)"
if [[ ! -f "$PROJECT_ROOT/core/lib_logging.sh" ]]; then
  echo "FATAL: core/lib_logging.sh introuvable depuis \$PROJECT_ROOT=$PROJECT_ROOT" >&2
  exit 1
fi
# shellcheck source=/dev/null
source "$PROJECT_ROOT/core/lib_logging.sh"
RUN_ID="${RUN_ID:-AUDIT_$(date -u +%Y%m%dT%H%M%SZ)}"
init_logging "$RUN_ID"
emit INFO audit "START args: $*"
trap 'rc=$?; lvl=INFO; ((rc!=0)) && lvl=ERROR; emit "$lvl" audit "EXIT rc=$rc"; exit $rc' EXIT
# --- /logging preamble ---
PRE

tmp="$(mktemp)"
# Supprime un ancien préambule s'il existe et réinsère le nouveau en tête (après shebang si présent)
awk -v pre="$PREAMBLE\n" '
BEGIN{inserted=0; skipping=0}
NR==1 && $0 ~ /^#!/ { print; print pre; inserted=1; next }
$0 ~ /^# --- logging preamble ---/ { skipping=1; next }
$0 ~ /^# --- \/logging preamble ---/ { skipping=0; next }
skipping==1 { next }
NR==1 && inserted==0 { print pre; inserted=1 }
{ print }
' "$TARGET" >"$tmp"

install -m 0755 "$tmp" "$TARGET"
rm -f "$tmp"
echo "Préambule logging (re)injecté dans: $TARGET"
