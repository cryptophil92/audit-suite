#!/usr/bin/env bash
# modules/90_report_pack.sh
# @version 0.3.0
# shellcheck disable=SC2034,SC2153,SC2154
set -Eeuo pipefail
MOD_ID="90_report_pack"
MOD_NAME="Ancien pack rapport — obsolète"
MOD_PRIO=90
MOD_REQUIRES=()
MOD_TIMEOUT=600
MOD_TAGS=("report")
MOD_MATURITY="deprecated"
MOD_CAPABILITIES=()
MOD_INTRUSIVENESS="none"
MOD_PRIVILEGES=("standard_user")
MOD_SELECTABLE=0
MOD_LIMITATIONS="Conservé pour compatibilité de chemin. Le pack canonique est créé après le manifest par bin/finalize_reports.sh."

mod_pre(){ return 0; }
mod_run(){
  local out="$RUN_DIR/$MOD_ID"

  mkdir -p "$out"
  cat > "$out/MIGRATION.txt" <<'EOF'
Ce module ne crée plus d’archive.
Le pipeline canonique s’exécute après la génération du manifest :
  bash bin/finalize_reports.sh <manifest.json>
EOF
  module_mark_partial "deprecated module: canonical report pack is generated after the manifest by bin/finalize_reports.sh"
  emit WARN "$MOD_ID" "Module obsolète : aucune archive créée avant le manifest."
}
mod_post(){ return 0; }
