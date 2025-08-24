#!/usr/bin/env bash
set -Eeuo pipefail
PRJ="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")"/.. && pwd)"
TARGET="$PRJ/audit.sh"
[[ -f "$TARGET" ]] || { echo "FATAL: audit.sh introuvable"; exit 1; }

cp -a -- "$TARGET" "$TARGET.bak.$(date -u +%Y%m%dT%H%M%SZ)"

# A) Supprime tout mkdir -p suspect visant core/scripts/logs/reports/tmp (souvent à l'origine des //)
awk '
  BEGIN{RS="\n"; OFS="";}
  {
    line=$0
    if (line ~ /^[[:space:]]*mkdir[[:space:]]+-p[[:space:]].*(\/core|\/scripts|\/logs|\/reports|\/tmp)/) {
      # drop the line
      next
    }
    print line ORS
  }' "$TARGET" > "$TARGET.tmp1"

# B) Injecte ensure_tree() et son appel juste après le préambule logging
awk '
  BEGIN{ins=0}
  {
    print
    if ($0 ~ /^# --- \/logging preamble ---/) {
      if (ins==0) {
        print "ensure_tree() {"
        print "  # sécurise les dossiers du projet (base sur PROJECT_ROOT résolu par le préambule)"
        print "  [[ -n \"" ENVIRON["PROJECT_ROOT"] "\" ]] >/dev/null 2>&1 || true"
        print "  mkdir -p \"$PROJECT_ROOT/core\" \"$PROJECT_ROOT/scripts\" \"$PROJECT_ROOT/logs\" \"$PROJECT_ROOT/tmp\" \"$PROJECT_ROOT/reports\""
        print "}"
        print "ensure_tree"
        ins=1
      }
    }
  }' "$TARGET.tmp1" > "$TARGET.tmp2"

install -m 0755 "$TARGET.tmp2" "$TARGET"
rm -f "$TARGET.tmp1" "$TARGET.tmp2"

echo "Patch appliqué sur audit.sh (backup créé)."
