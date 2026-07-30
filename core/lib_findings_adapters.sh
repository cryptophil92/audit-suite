#!/usr/bin/env bash
# core/lib_findings_adapters.sh
# Deterministic, local-only adapters from module outputs to findings[] 1.0.0.
set -Eeuo pipefail

# shellcheck source=lib_findings.sh
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib_findings.sh"

FINDINGS_NMAP_PORTSCAN_MODULE="20_portscan_nmap"

_findings_adapter_require_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    printf 'jq is required to adapt module findings\n' >&2
    return 1
  fi
}

_findings_adapter_trim() {
  local value="$1"

  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

_findings_adapter_safe_relative_path() {
  local path="$1"

  [[ "$path" =~ ^[A-Za-z0-9][A-Za-z0-9._/-]*$ ]] \
    && [[ "$path" != /* ]] \
    && [[ ! "$path" =~ (^|/)\.\.(/|$) ]] \
    && [[ ! "$path" =~ ^[A-Za-z]: ]]
}

_findings_adapter_slug() {
  local value="$1"

  value="${value//[^A-Za-z0-9._:-]/_}"
  value="${value:0:64}"
  [[ -n "$value" ]] || value="unknown"
  printf '%s' "$value"
}

_findings_adapter_nmap_version() {
  local input_path="$1"
  local version

  version="$(awk '/^# Nmap / { print $3; exit }' "$input_path")"
  version=${version%$'\r'}
  printf '%s' "$version"
}

_findings_adapter_remove_temp_files() {
  local path

  for path in "$@"; do
    [[ -n "$path" ]] && rm -f -- "$path"
  done
}

findings_merge_array_files() {
  local output_path="$1"
  shift || true

  local input_path output_dir temporary_output
  local -a input_paths=("$@")

  _findings_adapter_require_jq
  output_dir="$(dirname -- "$output_path")"
  mkdir -p "$output_dir"
  temporary_output="$(mktemp "${output_path}.tmp.XXXXXX")"

  if (( ${#input_paths[@]} == 0 )); then
    printf '[]\n' > "$temporary_output"
  else
    for input_path in "${input_paths[@]}"; do
      if ! findings_validate_array_file "$input_path"; then
        _findings_adapter_remove_temp_files "$temporary_output"
        return 1
      fi
    done

    if ! jq -s '
      add
      | sort_by(.id)
      | group_by(.id)
      | map(
          . as $group
          | $group[0] as $first
          | if ($group | length) == 1 then
              $first
            elif (
              $group
              | all(.[]; (del(.evidence) == ($first | del(.evidence))))
            ) then
              $first
              | .evidence = (
                  $group
                  | map(.evidence[])
                  | sort_by(.id)
                  | group_by(.id)
                  | map(
                      . as $evidence_group
                      | $evidence_group[0] as $evidence
                      | if all($evidence_group[]; . == $evidence) then
                          $evidence
                        else
                          error("conflicting duplicate evidence id: \($evidence.id)")
                        end
                    )
                )
            else
              error("conflicting duplicate finding id: \($first.id)")
            end
        )
      | sort_by(.id)
    ' "${input_paths[@]}" > "$temporary_output"; then
      _findings_adapter_remove_temp_files "$temporary_output"
      return 1
    fi
  fi

  if ! findings_validate_array_file "$temporary_output"; then
    _findings_adapter_remove_temp_files "$temporary_output"
    return 1
  fi

  mv -f -- "$temporary_output" "$output_path"
}

findings_adapt_nmap_portscan_file() {
  local input_path="$1"
  local evidence_path="$2"
  local scope_target="$3"
  local collected_at="$4"
  local output_path="$5"

  local output_dir temporary_jsonl temporary_output
  local nmap_version line host_descriptor address hostname ports_blob
  local entry port state protocol service version
  local port_number transport service_name asset_slug file_slug
  local finding_id evidence_id
  local -a entries=()

  _findings_adapter_require_jq

  if [[ ! -f "$input_path" || -L "$input_path" ]]; then
    printf 'Nmap adapter input must be a regular non-symlink file: %s\n' "$input_path" >&2
    return 1
  fi
  if ! _findings_adapter_safe_relative_path "$evidence_path"; then
    printf 'Unsafe Nmap evidence path: %s\n' "$evidence_path" >&2
    return 1
  fi
  if [[ -z "$scope_target" || -z "$collected_at" ]]; then
    printf 'Nmap adapter requires a scope target and collection timestamp\n' >&2
    return 1
  fi

  output_dir="$(dirname -- "$output_path")"
  mkdir -p "$output_dir"
  temporary_jsonl="$(mktemp "${output_path}.jsonl.XXXXXX")"
  temporary_output="$(mktemp "${output_path}.tmp.XXXXXX")"
  nmap_version="$(_findings_adapter_nmap_version "$input_path")"
  file_slug="$(basename -- "$evidence_path")"
  file_slug="${file_slug%.gnmap}"
  file_slug="$(_findings_adapter_slug "$file_slug")"

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" == "Host: "* ]] || continue
    [[ "$line" == *$'\tPorts: '* ]] || continue

    host_descriptor="${line#Host: }"
    host_descriptor=${host_descriptor%%$'\t'*}
    address="${host_descriptor%% *}"
    hostname=""
    if [[ "$host_descriptor" =~ \(([^()]*)\) ]]; then
      hostname="${BASH_REMATCH[1]}"
    fi

    if [[ -z "$address" ]]; then
      printf 'Nmap adapter ignored a host line without an address in %s\n' "$evidence_path" >&2
      continue
    fi

    ports_blob=${line#*$'\tPorts: '}
    ports_blob=${ports_blob%%$'\t'*}
    IFS=',' read -r -a entries <<< "$ports_blob"

    for entry in "${entries[@]}"; do
      entry="$(_findings_adapter_trim "$entry")"
      [[ -n "$entry" ]] || continue

      port=""
      state=""
      protocol=""
      service=""
      version=""
      IFS='/' read -r port state protocol _ service _ version _ <<< "$entry"
      port="$(_findings_adapter_trim "$port")"
      state="$(_findings_adapter_trim "$state")"
      protocol="$(_findings_adapter_trim "$protocol")"
      service="$(_findings_adapter_trim "$service")"
      version="$(_findings_adapter_trim "$version")"

      [[ "$state" == "open" ]] || continue

      if ! [[ "$port" =~ ^[0-9]+$ ]]; then
        printf 'Nmap adapter ignored malformed open-port entry in %s: %s\n' \
          "$evidence_path" "$entry" >&2
        continue
      fi
      port_number=$((10#$port))
      if (( port_number < 1 || port_number > 65535 )); then
        printf 'Nmap adapter ignored out-of-range open port in %s: %s\n' \
          "$evidence_path" "$port" >&2
        continue
      fi

      case "$protocol" in
        tcp|udp|sctp) transport="$protocol" ;;
        *) transport="other" ;;
      esac

      service_name="${service:-unknown}"
      asset_slug="$(_findings_adapter_slug "$address")"
      finding_id="finding.${FINDINGS_NMAP_PORTSCAN_MODULE}.open.${asset_slug}.${transport}.${port_number}"
      evidence_id="evidence.${FINDINGS_NMAP_PORTSCAN_MODULE}.${file_slug}.${asset_slug}.${transport}.${port_number}"

      # Apostrophes typographiques intentionnelles dans le texte JSON français.
      # shellcheck disable=SC1112
      if ! jq -nc \
        --arg id "$finding_id" \
        --arg title "Port ${transport}/${port_number} ouvert observé" \
        --arg address "$address" \
        --arg hostname "$hostname" \
        --arg scope_target "$scope_target" \
        --arg transport "$transport" \
        --argjson port "$port_number" \
        --arg service "$service_name" \
        --arg version "$version" \
        --arg evidence_id "$evidence_id" \
        --arg evidence_path "$evidence_path" \
        --arg collected_at "$collected_at" \
        --arg module "$FINDINGS_NMAP_PORTSCAN_MODULE" \
        --arg tool_version "$nmap_version" '
          {
            id: $id,
            type: "observation",
            title: $title,
            category: "service_inventory",
            asset: (
              {
                id: ("asset." + $address),
                address: $address
              }
              + if ($hostname | length) > 0 then {hostname: $hostname} else {} end
            ),
            scope: {
              target: $scope_target,
              relation: "derived"
            },
            service: {
              transport: $transport,
              port: $port,
              name: $service
            },
            severity: "informational",
            scoring: {
              status: "unscored",
              rationale: "Une observation de port ouvert ne justifie aucun score de risque."
            },
            confidence: "high",
            validation_status: "observed",
            observation: (
              "Nmap a enregistré ce port à l’état open"
              + (if $service == "unknown" then "" else " pour le service « " + $service + " »" end)
              + (if ($version | length) == 0 then "" else ", avec l’identification « " + $version + " »" end)
              + "."
            ),
            impact: "Cette donnée enrichit l’inventaire technique ; aucun impact de sécurité n’est établi par l’ouverture du port seule.",
            evidence: [
              {
                id: $evidence_id,
                kind: "file_reference",
                source: $module,
                path: $evidence_path,
                captured_at: $collected_at
              }
            ],
            source: (
              {
                module: $module,
                tool: "nmap",
                collected_at: $collected_at,
                provenance: "Adaptation déterministe d’un état open présent dans la sortie Nmap grepable ; aucune vulnérabilité n’est déduite."
              }
              + if ($tool_version | length) > 0 then {tool_version: $tool_version} else {} end
            ),
            remediation: {
              priority: "none",
              effort: "unknown",
              action: "Examiner le service dans son contexte avant de décider d’une action.",
              rationale: "Un port ouvert n’est pas, à lui seul, une vulnérabilité.",
              change_risk: "Une fermeture non validée peut interrompre un service légitime.",
              verification: "Confirmer l’usage attendu et, si un changement est décidé, vérifier le service lors d’un audit autorisé."
            },
            references: [],
            limitations: [
              "L’état open ne prouve aucune vulnérabilité ni exposition exploitable.",
              "La confiance élevée porte sur la présence de l’état dans le fichier source, pas sur une validation indépendante du service."
            ]
          }
        ' >> "$temporary_jsonl"; then
        _findings_adapter_remove_temp_files "$temporary_jsonl" "$temporary_output"
        return 1
      fi
    done
  done < "$input_path"

  if ! jq -s 'sort_by(.id)' "$temporary_jsonl" > "$temporary_output"; then
    _findings_adapter_remove_temp_files "$temporary_jsonl" "$temporary_output"
    return 1
  fi
  _findings_adapter_remove_temp_files "$temporary_jsonl"

  if ! findings_validate_array_file "$temporary_output"; then
    _findings_adapter_remove_temp_files "$temporary_output"
    return 1
  fi

  mv -f -- "$temporary_output" "$output_path"
}

findings_adapt_run() {
  local run_dir="$1"
  local scope_target="$2"
  local output_path="$3"
  local collected_at="$4"
  local base_path="${5:-}"

  local module_dir source_path evidence_path adapted_path
  local -a input_arrays=()
  local -a temporary_arrays=()

  if [[ ! -d "$run_dir" ]]; then
    printf 'Run directory not found: %s\n' "$run_dir" >&2
    return 1
  fi

  if [[ -n "$base_path" ]]; then
    input_arrays+=("$base_path")
  fi
  if [[ -f "$output_path" && "$output_path" != "$base_path" ]]; then
    input_arrays+=("$output_path")
  fi

  module_dir="$run_dir/$FINDINGS_NMAP_PORTSCAN_MODULE"
  if [[ -d "$module_dir" ]]; then
    while IFS= read -r -d '' source_path; do
      evidence_path="${source_path:${#run_dir}+1}"
      adapted_path="$(mktemp "$run_dir/.findings-adapter.XXXXXX")"
      temporary_arrays+=("$adapted_path")

      if ! findings_adapt_nmap_portscan_file \
        "$source_path" \
        "$evidence_path" \
        "$scope_target" \
        "$collected_at" \
        "$adapted_path"; then
        _findings_adapter_remove_temp_files "${temporary_arrays[@]}"
        return 1
      fi
      input_arrays+=("$adapted_path")
    done < <(
      find "$module_dir" -maxdepth 1 -type f -name '*.gnmap' -print0 \
        | LC_ALL=C sort -z
    )
  fi

  if ! findings_merge_array_files "$output_path" "${input_arrays[@]}"; then
    _findings_adapter_remove_temp_files "${temporary_arrays[@]}"
    return 1
  fi

  _findings_adapter_remove_temp_files "${temporary_arrays[@]}"
}
