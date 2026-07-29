#!/usr/bin/env bash
# Ensure every published application version derives from the root VERSION file.
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

expected_version="$(tr -d '\r\n' < VERSION)"
version_json="$(bash bin/version_json.sh)"
openapi_version="$(jq -r '.info.version' api/openapi.json)"

[[ "$expected_version" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$ ]]
[[ "$(jq -r '.version' <<< "$version_json")" == "$expected_version" ]]
[[ "$openapi_version" == "$expected_version" ]]
bash bin/sync_version.sh --check >/dev/null

python3 - "$expected_version" <<'PY'
import importlib.util
import pathlib
import sys

repo_dir = pathlib.Path.cwd()
spec = importlib.util.spec_from_file_location(
    "audit_suite_version",
    repo_dir / "api" / "version.py",
)
if spec is None or spec.loader is None:
    raise RuntimeError("Unable to load api/version.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

assert module.APP_VERSION == sys.argv[1]
assert module.COMMIT_PATTERN.fullmatch(module.APP_COMMIT)
PY

if grep -En 'AuditSuiteReadOnlyAPI/[0-9]|^VERSION="[0-9]' \
  audit.sh bin/version_json.sh api/server.py; then
  echo "Hard-coded application version found outside VERSION." >&2
  exit 1
fi

printf '[OK] version consistency tests passed\n'
