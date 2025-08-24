#!/usr/bin/env bash
set -Eeuo pipefail

f="modules/90_report_pack.sh"
ts="$(date -u +%Y%m%dT%H%M%SZ)"

# sauvegarde
cp -a "$f" "${f}.bak-${ts}"

# insérer "source core/lib_logging.sh" après le shebang
awk '
  NR==1 {print; next}
  NR==2 && $0 !~ /core\/lib_logging.sh/ {
    print "source \"core/lib_logging.sh\""
  }
  {print}
' "$f" > "${f}.new"

mv "${f}.new" "$f"
chmod +x "$f"

echo "[OK] Patch report_pack appliqué ($ts)."
