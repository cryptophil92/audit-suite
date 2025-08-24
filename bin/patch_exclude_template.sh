#!/usr/bin/env bash
set -Eeuo pipefail

ts="$(date -u +%Y%m%dT%H%M%SZ)"

backup() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  cp -a "$f" "${f}.bak-${ts}"
}

patch_runner() {
  local f="core/lib_runner.sh"
  backup "$f"
  # remplace discover_modules_sorted pour ignorer _TEMPLATE
  awk '
    BEGIN{replaced=0}
    /^discover_modules_sorted\(\)\s*{/{
      print "discover_modules_sorted() {"
      print "  ls -1 modules/*.sh 2>/dev/null | grep -v '"'"'_TEMPLATE'"'"' | sort -V"
      print "}"
      # sauter les lignes du bloc original jusqu à la prochaine '}'
      inblk=1; replaced=1; next
    }
    inblk && /^\}/ { inblk=0; next }
    !inblk { print }
    END{
      if(!replaced){ exit 1 }
    }
  ' "$f" > "${f}.new" && mv "${f}.new" "$f"
  chmod +x "$f"
}

patch_menu() {
  local f="core/lib_menu.sh"
  backup "$f"
  # filtre la liste pour ne pas proposer _TEMPLATE dans l’UI
  # remplace la ligne qui construit "list=..."
  awk '
    {
      if ($0 ~ /list=.*modules\/\*\.sh/) {
        gsub(/printf "%s\\n" modules\/\*\.sh 2>\/dev\/null \|/, "printf \"%s\\n\" modules/*.sh 2>/dev/null | grep -v _TEMPLATE |", $0)
      }
      print
    }
  ' "$f" > "${f}.new" && mv "${f}.new" "$f"
  chmod +x "$f"
}

main() {
  patch_runner
  patch_menu
  echo "[OK] Patch exclude _TEMPLATE appliqué (${ts})."
  if command -v git >/dev/null 2>&1 && [ -d .git ]; then
    git add core/lib_runner.sh core/lib_menu.sh || true
    git commit -m "patch: exclude _TEMPLATE from runner & UI (${ts})" || true
  fi
}
main
