#!/usr/bin/env bash
# Refuse new or modified tracked runtime artifacts without exposing file names.
set -Eeuo pipefail

usage() {
  printf 'Usage: %s <base-commit> [head-commit]\n' "${0##*/}" >&2
}

if (( $# < 1 || $# > 2 )); then
  usage
  exit 64
fi

base_commit="$1"
head_commit="${2:-HEAD}"

if ! git rev-parse --verify --quiet "${base_commit}^{commit}" >/dev/null; then
  printf 'Runtime artifact guard: invalid base commit.\n' >&2
  exit 65
fi

if ! git rev-parse --verify --quiet "${head_commit}^{commit}" >/dev/null; then
  printf 'Runtime artifact guard: invalid head commit.\n' >&2
  exit 65
fi

violation_count=0
declare -A affected_categories=()

while IFS= read -r -d '' status; do
  candidate_path=""

  case "$status" in
    R*|C*)
      IFS= read -r -d '' _source_path
      IFS= read -r -d '' candidate_path
      ;;
    *)
      IFS= read -r -d '' candidate_path
      ;;
  esac

  case "$candidate_path" in
    output/*|logs/*|tmp/*|history/*)
      category="${candidate_path%%/*}"
      affected_categories["$category"]=1
      ((violation_count += 1))
      ;;
  esac
done < <(git diff --name-status -z --diff-filter=ACMR "$base_commit" "$head_commit" --)

if (( violation_count == 0 )); then
  printf 'Runtime artifact guard: no new or modified tracked runtime artifacts.\n'
  exit 0
fi

printf 'Runtime artifact guard: refused %d new or modified tracked runtime artifact(s).\n' "$violation_count" >&2
printf 'Affected ignored categories:' >&2
for category in output logs tmp history; do
  if [[ -n "${affected_categories[$category]:-}" ]]; then
    printf ' %s/' "$category" >&2
  fi
done
printf '\n' >&2
printf 'File names are intentionally omitted. Remove the artifacts from the proposed change and rotate any exposed secret through a private process.\n' >&2
exit 2
