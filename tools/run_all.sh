#!/usr/bin/env bash
set -Eeuo pipefail
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
"$HERE/project_update_all.sh" "$@"
"$HERE/verify_tree.sh"
"$HERE/selftest_logging.sh"
"$HERE/shellcheck_all.sh"
echo "Pipeline outils terminé."
