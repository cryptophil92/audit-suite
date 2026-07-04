#!/usr/bin/env bash
# bin/history.sh
# @version 0.2.1
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

# shellcheck source=../core/lib_history.sh
source "core/lib_history.sh"

usage() {
  cat <<'EOF'
Usage: bin/history.sh [command]

Commands:
  list      Liste les runs enregistrés.
  latest    Affiche le dernier run au format JSON.
  path      Affiche le chemin du fichier d'index.
  help      Affiche cette aide.

Par défaut : list
EOF
}

cmd="${1:-list}"

case "$cmd" in
  list)
    if [[ ! -f "$(history_index_path)" ]]; then
      echo "Aucun historique trouvé."
      exit 0
    fi

    printf 'created_at\trun_id\tprofile\ttargets\tsuccess\tfailed\tskipped\n'
    history_list_runs
    ;;
  latest)
    if [[ ! -f "$(history_latest_path)" ]]; then
      echo "Aucun run latest trouvé." >&2
      exit 1
    fi
    jq '.' "$(history_latest_path)"
    ;;
  path)
    history_index_path
    ;;
  help|-h|--help)
    usage
    ;;
  *)
    echo "Commande inconnue: $cmd" >&2
    usage >&2
    exit 2
    ;;
esac
