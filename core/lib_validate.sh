#!/usr/bin/env bash
# core/lib_validate.sh
# Validation stricte des cibles d'audit.
# @version 0.2.1
set -Eeuo pipefail

_ipv4_to_int() {
  local ip="$1"
  local IFS=.
  local -a octets=()
  read -r -a octets <<< "$ip"

  printf '%u\n' $((
    (10#${octets[0]} << 24) +
    (10#${octets[1]} << 16) +
    (10#${octets[2]} << 8) +
    10#${octets[3]}
  ))
}

_is_ipv4() {
  local ip="$1"
  local IFS=.
  local -a octets=()
  local octet n

  [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || return 1
  read -r -a octets <<< "$ip"
  [[ ${#octets[@]} -eq 4 ]] || return 1

  for octet in "${octets[@]}"; do
    [[ "$octet" =~ ^[0-9]{1,3}$ ]] || return 1
    if [[ ${#octet} -gt 1 && "$octet" == 0* ]]; then
      return 1
    fi
    n=$((10#$octet))
    (( n >= 0 && n <= 255 )) || return 1
  done
}

_is_prefix() {
  local prefix="$1"
  [[ "$prefix" =~ ^[0-9]{1,2}$ ]] || return 1
  prefix=$((10#$prefix))
  (( prefix >= 0 && prefix <= 32 )) || return 1
}

_cidr_bounds() {
  local ip="$1"
  local prefix="$2"
  local ip_int mask network broadcast

  ip_int="$(_ipv4_to_int "$ip")"

  if (( prefix == 0 )); then
    mask=0
  else
    mask=$(( (0xFFFFFFFF << (32 - prefix)) & 0xFFFFFFFF ))
  fi

  network=$(( ip_int & mask ))
  broadcast=$(( network | (0xFFFFFFFF ^ mask) ))

  printf '%u %u\n' "$network" "$broadcast"
}

_is_allowed_non_public_scope() {
  local ip="$1"
  local prefix="$2"
  local target_start target_end range range_ip range_prefix range_start range_end

  read -r target_start target_end < <(_cidr_bounds "$ip" "$prefix")

  # Scopes autorisés par défaut : RFC1918, loopback, link-local IPv4 et CGNAT.
  for range in \
    "10.0.0.0/8" \
    "172.16.0.0/12" \
    "192.168.0.0/16" \
    "127.0.0.0/8" \
    "169.254.0.0/16" \
    "100.64.0.0/10"; do
    range_ip="${range%/*}"
    range_prefix="${range#*/}"
    read -r range_start range_end < <(_cidr_bounds "$range_ip" "$range_prefix")

    if (( target_start >= range_start && target_end <= range_end )); then
      return 0
    fi
  done

  return 1
}

_validate_one_target() {
  local target="$1"
  local allow_public="${2:-0}"
  local ip prefix

  [[ -n "$target" ]] || return 1
  [[ "$target" =~ ^[0-9./]+$ ]] || {
    printf 'Cible refusée: %s (format non autorisé)\n' "$target" >&2
    return 1
  }

  if [[ "$target" == */* ]]; then
    [[ "$target" != */*/* ]] || {
      printf 'Cible refusée: %s (CIDR invalide)\n' "$target" >&2
      return 1
    }
    ip="${target%/*}"
    prefix="${target#*/}"
  else
    ip="$target"
    prefix="32"
  fi

  _is_ipv4 "$ip" || {
    printf 'Cible refusée: %s (IPv4 invalide)\n' "$target" >&2
    return 1
  }

  _is_prefix "$prefix" || {
    printf 'Cible refusée: %s (préfixe CIDR invalide)\n' "$target" >&2
    return 1
  }

  if [[ "$allow_public" != "1" ]] && ! _is_allowed_non_public_scope "$ip" "$prefix"; then
    printf 'Cible refusée: %s (IP publique ou plage non locale bloquée par défaut)\n' "$target" >&2
    printf 'Utiliser --allow-public uniquement avec autorisation explicite.\n' >&2
    return 1
  fi
}

validate_targets() {
  local raw_targets="$1"
  local allow_public="${2:-0}"
  local normalized target
  local -a parsed_targets=()
  local -a valid_targets=()

  normalized="${raw_targets//,/ }"
  read -r -a parsed_targets <<< "$normalized"

  for target in "${parsed_targets[@]}"; do
    [[ -n "$target" ]] || continue
    _validate_one_target "$target" "$allow_public"
    valid_targets+=("$target")
  done

  if (( ${#valid_targets[@]} == 0 )); then
    printf 'Aucune cible valide fournie.\n' >&2
    return 1
  fi

  printf '%s\n' "${valid_targets[*]}"
}
