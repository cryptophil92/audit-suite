#!/usr/bin/env bash
# core/lib_report_pack.sh
# @version 0.2.5
set -Eeuo pipefail

_report_pack_requirements() {
  local missing=0
  local dep

  for dep in jq tar gzip; do
    if ! command -v "$dep" >/dev/null 2>&1; then
      echo "$dep is required to build report packs" >&2
      missing=1
    fi
  done

  (( missing == 0 ))
}

_report_pack_validate_manifest() {
  local manifest_path="$1"

  if [[ ! -f "$manifest_path" ]]; then
    echo "Manifest introuvable: $manifest_path" >&2
    return 1
  fi

  jq -e 'type == "object" and (.run_id | type == "string")' "$manifest_path" >/dev/null
}

_report_pack_safe_run_id() {
  local run_id="$1"

  if [[ ! "$run_id" =~ ^[A-Za-z0-9_.:-]+$ ]]; then
    echo "Run ID invalide pour pack: $run_id" >&2
    return 1
  fi

  printf '%s\n' "$run_id"
}

_report_pack_copy_if_exists() {
  local src="$1"
  local dst="$2"

  if [[ -f "$src" ]]; then
    mkdir -p "$(dirname -- "$dst")"
    cp "$src" "$dst"
  fi
}

_report_pack_copy_dir_if_exists() {
  local src="$1"
  local dst="$2"

  if [[ -d "$src" ]]; then
    mkdir -p "$(dirname -- "$dst")"
    cp -a "$src" "$dst"
  fi
}

report_pack_default_output_path() {
  local manifest_path="$1"
  local run_id

  run_id="$(jq -r '.run_id' "$manifest_path")"
  run_id="$(_report_pack_safe_run_id "$run_id")"
  printf '%s\n' "$(dirname -- "$manifest_path")/${run_id}_report_pack.tar.gz"
}

report_pack_build() {
  local manifest_path="$1"
  local output_path="${2:-}"
  local run_id output_dir logs_dir report_html pack_root pack_dir tmp_parent file_list

  _report_pack_requirements
  _report_pack_validate_manifest "$manifest_path"

  run_id="$(jq -r '.run_id' "$manifest_path")"
  run_id="$(_report_pack_safe_run_id "$run_id")"

  output_dir="$(jq -r '.paths.output // empty' "$manifest_path")"
  logs_dir="$(jq -r '.paths.logs // empty' "$manifest_path")"
  report_html="$(dirname -- "$manifest_path")/report.html"

  if [[ -z "$output_path" ]]; then
    output_path="$(report_pack_default_output_path "$manifest_path")"
  fi

  mkdir -p "$(dirname -- "$output_path")"

  tmp_parent="$(mktemp -d)"
  trap 'rm -rf "$tmp_parent"' RETURN

  pack_root="AUDIT_SUITE_REPORT_PACK_${run_id}"
  pack_dir="$tmp_parent/$pack_root"
  mkdir -p "$pack_dir"

  _report_pack_copy_if_exists "$manifest_path" "$pack_dir/manifest.json"
  _report_pack_copy_if_exists "$report_html" "$pack_dir/report.html"

  if [[ -n "$logs_dir" ]]; then
    _report_pack_copy_dir_if_exists "$logs_dir" "$pack_dir/logs"
  fi

  if [[ -n "$output_dir" && -d "$output_dir" ]]; then
    mkdir -p "$pack_dir/results"
    while IFS= read -r item; do
      case "$(basename -- "$item")" in
        manifest.json|report.html|*_report_pack.tar.gz)
          continue
          ;;
        tmp|temp)
          continue
          ;;
      esac

      cp -a "$item" "$pack_dir/results/"
    done < <(find "$output_dir" -mindepth 1 -maxdepth 1 -print | sort)
  fi

  cat > "$pack_dir/README.txt" <<EOF
AUDIT-SUITE report pack
Run: $run_id
Generated: $(date -Is)

Contents:
- manifest.json: structured run manifest
- report.html: local HTML report when available
- logs/: copied logs when available
- results/: copied module outputs when available
EOF

  file_list="$pack_dir/PACK_CONTENTS.txt"
  (cd "$pack_dir" && find . -mindepth 1 -print | sort) > "$file_list"

  tar -C "$tmp_parent" -czf "$output_path" "$pack_root"
  printf '%s\n' "$output_path"
}
