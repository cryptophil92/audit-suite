#!/usr/bin/env bash
# core/lib_version.sh - Canonical application version and source revision
set -Eeuo pipefail

_AUDIT_SUITE_VERSION_LIB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
_AUDIT_SUITE_REPO_DIR="$(cd -- "$_AUDIT_SUITE_VERSION_LIB_DIR/.." && pwd)"

audit_suite_version() {
  local version_file="$_AUDIT_SUITE_REPO_DIR/VERSION"
  local version

  if [[ ! -f "$version_file" ]]; then
    echo "Version file not found: $version_file" >&2
    return 1
  fi

  IFS= read -r version < "$version_file" || true
  version="${version%$'\r'}"

  if ! [[ "$version" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$ ]]; then
    echo "Invalid semantic version in $version_file: $version" >&2
    return 1
  fi

  printf '%s\n' "$version"
}

audit_suite_commit() {
  local commit="${AUDIT_SUITE_COMMIT:-}"

  if [[ -n "$commit" ]]; then
    if ! [[ "$commit" =~ ^([0-9A-Fa-f]{7,40}|unknown)$ ]]; then
      echo "Invalid AUDIT_SUITE_COMMIT: $commit" >&2
      return 1
    fi
    printf '%s\n' "$commit"
    return 0
  fi

  if command -v git >/dev/null 2>&1 \
    && commit="$(git -C "$_AUDIT_SUITE_REPO_DIR" rev-parse --verify HEAD 2>/dev/null)"; then
    printf '%s\n' "$commit"
  else
    printf 'unknown\n'
  fi
}
