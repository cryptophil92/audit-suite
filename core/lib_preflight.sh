#!/usr/bin/env bash
# core/lib_preflight.sh
# @version 0.4.0
set -Eeuo pipefail

preflight_command_available() {
  local name="$1"
  local forced_missing=" ${AUDIT_PREFLIGHT_FORCE_MISSING_COMMANDS:-} "
  local forced_available=" ${AUDIT_PREFLIGHT_FORCE_AVAILABLE_COMMANDS:-} "

  if [[ "$forced_missing" == *" $name "* ]]; then
    return 1
  fi
  if [[ "$forced_available" == *" $name "* ]]; then
    return 0
  fi
  command -v "$name" >/dev/null 2>&1
}

preflight_raw_socket_available() {
  local nmap_path capabilities

  case "${AUDIT_PREFLIGHT_FORCE_RAW_SOCKET:-}" in
    0) return 1 ;;
    1) return 0 ;;
    "") ;;
    *)
      printf 'Valeur invalide pour AUDIT_PREFLIGHT_FORCE_RAW_SOCKET: %s\n' \
        "$AUDIT_PREFLIGHT_FORCE_RAW_SOCKET" >&2
      return 1
      ;;
  esac

  if [[ "$(id -u 2>/dev/null || printf 'unknown')" == "0" ]]; then
    return 0
  fi

  preflight_command_available nmap || return 1
  preflight_command_available getcap || return 1
  nmap_path="$(command -v nmap)"
  capabilities="$(getcap "$nmap_path" 2>/dev/null || true)"
  [[ "$capabilities" =~ cap_net_raw[^=]*=[a-z]*e[a-z]* ]]
}

preflight_detect_capabilities() {
  local kernel

  kernel="$(uname -s 2>/dev/null || printf 'unknown')"
  case "$kernel" in
    Linux)
      PREFLIGHT_PLATFORM="linux"
      PREFLIGHT_PLATFORM_SUPPORTED=1
      ;;
    *)
      PREFLIGHT_PLATFORM="other"
      PREFLIGHT_PLATFORM_SUPPORTED=0
      ;;
  esac

  PREFLIGHT_IP_AVAILABLE=0
  preflight_command_available ip && PREFLIGHT_IP_AVAILABLE=1

  PREFLIGHT_PYTHON_AVAILABLE=0
  preflight_command_available python3 && PREFLIGHT_PYTHON_AVAILABLE=1
  PREFLIGHT_PYTHON_VERSION_SUPPORTED=0
  if (( PREFLIGHT_PYTHON_AVAILABLE == 1 )) && \
    python3 -c 'import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)' \
      >/dev/null 2>&1; then
    PREFLIGHT_PYTHON_VERSION_SUPPORTED=1
  fi

  PREFLIGHT_RAW_SOCKET_AVAILABLE=0
  preflight_raw_socket_available && PREFLIGHT_RAW_SOCKET_AVAILABLE=1

  AUDIT_RAW_SOCKET_AVAILABLE="$PREFLIGHT_RAW_SOCKET_AVAILABLE"
  export AUDIT_RAW_SOCKET_AVAILABLE
  export PREFLIGHT_PLATFORM PREFLIGHT_PLATFORM_SUPPORTED
  export PREFLIGHT_IP_AVAILABLE PREFLIGHT_PYTHON_AVAILABLE
  export PREFLIGHT_PYTHON_VERSION_SUPPORTED
  export PREFLIGHT_RAW_SOCKET_AVAILABLE
}

_preflight_module_metadata() {
  local module="$1"

  bash -c '
    set -Eeuo pipefail
    module="$1"

    # shellcheck source=/dev/null
    source "core/lib_logging.sh"
    # shellcheck source=/dev/null
    source "$module" >/dev/null

    : "${MOD_ID:=unknown_module}"
    : "${MOD_NAME:=Unknown}"
    : "${MOD_SKIP_OPTION:=-}"
    : "${MOD_RAW_SOCKET_FOR_UDP:=0}"
    : "${MOD_RAW_SOCKET_FALLBACK:=mode dégradé documenté}"
    : "${MOD_SELECTABLE:=1}"
    : "${MOD_MATURITY:=experimental}"
    : "${MOD_LIMITATIONS:=}"

    requires=""
    if declare -p MOD_REQUIRES >/dev/null 2>&1; then
      if declare -p MOD_REQUIRES 2>/dev/null | grep -q "declare -[aA]"; then
        requires="${MOD_REQUIRES[*]}"
      else
        requires="$MOD_REQUIRES"
      fi
    fi

    raw_profiles=""
    if declare -p MOD_RAW_SOCKET_PROFILES >/dev/null 2>&1; then
      if declare -p MOD_RAW_SOCKET_PROFILES 2>/dev/null | grep -q "declare -[aA]"; then
        raw_profiles="${MOD_RAW_SOCKET_PROFILES[*]}"
      else
        raw_profiles="$MOD_RAW_SOCKET_PROFILES"
      fi
    fi

    printf "%s|%s|%s|%s|%s|%s|%s|%s|%s|%s\n" \
      "$MOD_ID" "$MOD_NAME" "$MOD_SKIP_OPTION" "$requires" \
      "$raw_profiles" "$MOD_RAW_SOCKET_FOR_UDP" "$MOD_RAW_SOCKET_FALLBACK" \
      "$MOD_SELECTABLE" "$MOD_MATURITY" "$MOD_LIMITATIONS"
  ' _ "$module"
}

_preflight_raw_socket_needed() {
  local raw_profiles="$1"
  local raw_for_udp="$2"
  local profile="${PROFILE:-fast}"

  if [[ " $raw_profiles " == *" $profile "* ]]; then
    return 0
  fi
  if [[ "$raw_for_udp" == "1" && "${OPTS_NO_UDP:-0}" != "1" ]]; then
    return 0
  fi
  return 1
}

preflight_run() {
  local selected="${1:-}"
  local module metadata id name skip_option requires_raw
  local raw_profiles raw_for_udp fallback selectable maturity limitations dep
  local core_command core_missing=0 module_missing raw_needed
  local ready_count=0 degraded_count=0 skipped_count=0 disabled_count=0
  local blocker_count=0
  local -a modules=()
  local -a missing_dependencies=()

  preflight_detect_capabilities

  printf 'Préflight Audit Suite — vérification locale sans scan\n'

  for core_command in ${AUDIT_PREFLIGHT_CORE_COMMANDS:-jq timeout tar gzip}; do
    if preflight_command_available "$core_command"; then
      printf '[OK] Socle moteur : %s disponible.\n' "$core_command"
    else
      printf '[BLOQUANT] Socle moteur : %s manque. Installez cette commande avant de lancer un audit.\n' \
        "$core_command"
      ((core_missing += 1))
      ((blocker_count += 1))
    fi
  done

  if (( PREFLIGHT_PLATFORM_SUPPORTED == 1 )); then
    printf '[OK] Plateforme : Linux détecté.\n'
  else
    printf "%s\n" "[DÉGRADÉ] Plateforme : environnement non Linux. Utilisez Kali/Linux ou WSL validé ; aucun support natif n'est promis."
    ((degraded_count += 1))
  fi

  if (( PREFLIGHT_IP_AVAILABLE == 1 )); then
    printf '[OK] Environnement réseau : commande ip disponible.\n'
  else
    printf "%s\n" "[DÉGRADÉ] Environnement réseau : commande ip absente. Installez iproute2 ; les cibles explicites restent utilisables, mais l'interface et le CIDR ne seront pas détectés automatiquement."
    ((degraded_count += 1))
  fi

  if (( PREFLIGHT_PYTHON_VERSION_SUPPORTED == 1 )); then
    printf '[OK] API locale : Python 3.10+ disponible.\n'
  elif (( PREFLIGHT_PYTHON_AVAILABLE == 1 )); then
    printf "%s\n" "[INFO] API locale : Python est antérieur à 3.10. Mettez-le à niveau pour l'API et le dashboard ; le moteur Bash reste utilisable."
  else
    printf "%s\n" "[INFO] API locale : Python 3 absent. Installez Python 3.10+ pour l'API et le dashboard ; le moteur Bash reste utilisable."
  fi

  read -r -a modules <<< "${selected//,/ }"
  for module in "${modules[@]}"; do
    [[ -n "$module" ]] || continue
    [[ "$module" == modules/* ]] || module="modules/$module"

    if [[ ! -f "$module" ]]; then
      printf '[IGNORÉ] Module inconnu : %s.\n' "$module"
      ((skipped_count += 1))
      continue
    fi

    if ! metadata="$(_preflight_module_metadata "$module")"; then
      printf '[IGNORÉ] Métadonnées illisibles : %s. Le module sera marqué skipped.\n' "$module"
      ((skipped_count += 1))
      continue
    fi

    IFS='|' read -r id name skip_option requires_raw raw_profiles raw_for_udp fallback \
      selectable maturity limitations <<< "$metadata"
    : "${id:=unknown_module}"
    : "${name:=Unknown}"
    : "${skip_option:=-}"
    : "${raw_for_udp:=0}"
    : "${selectable:=1}"
    : "${maturity:=experimental}"

    if [[ "$selectable" != "1" ]]; then
      printf '[INDISPONIBLE] %s : maturité %s. %s\n' \
        "$name" "$maturity" "${limitations:-Ce module n’est pas sélectionnable.}"
      ((disabled_count += 1))
      continue
    fi

    if [[ "$skip_option" != "-" ]]; then
      if ! [[ "$skip_option" =~ ^[A-Z][A-Z0-9_]*$ ]]; then
        printf "%s\n" "[IGNORÉ] $name : métadonnée d'option invalide. Le module sera marqué skipped."
        ((skipped_count += 1))
        continue
      fi
      if [[ "${!skip_option:-0}" == "1" ]]; then
        printf '[DÉSACTIVÉ] %s : option %s demandée.\n' "$name" "$skip_option"
        ((disabled_count += 1))
        continue
      fi
    fi

    missing_dependencies=()
    for dep in $requires_raw; do
      if ! preflight_command_available "$dep"; then
        missing_dependencies+=("$dep")
      fi
    done

    module_missing=0
    if (( ${#missing_dependencies[@]} > 0 )); then
      printf '[IGNORÉ] %s : commande(s) manquante(s) : %s. Installez-les pour activer ce module ; il sera marqué skipped sinon.\n' \
        "$name" "${missing_dependencies[*]}"
      ((skipped_count += 1))
      module_missing=1
    fi
    (( module_missing == 1 )) && continue

    raw_needed=0
    _preflight_raw_socket_needed "$raw_profiles" "$raw_for_udp" && raw_needed=1
    if (( raw_needed == 1 && PREFLIGHT_RAW_SOCKET_AVAILABLE == 0 )); then
      printf '[DÉGRADÉ] %s : sockets brutes indisponibles. %s\n' "$name" "$fallback"
      ((degraded_count += 1))
      continue
    fi

    if [[ "$maturity" == "partial" ]]; then
      printf '[LIMITÉ] Module : %s prêt pour une couverture partielle. %s\n' \
        "$name" "${limitations:-Consultez le catalogue pour les limites.}"
      ((degraded_count += 1))
      continue
    fi

    printf '[OK] Module : %s prêt.\n' "$name"
    ((ready_count += 1))
  done

  printf 'Résumé : %d prêt(s), %d dégradé(s), %d ignoré(s), %d désactivé(s), %d bloquant(s).\n' \
    "$ready_count" "$degraded_count" "$skipped_count" "$disabled_count" "$blocker_count"

  if (( core_missing > 0 )); then
    printf '[ARRÊT] Corrigez les éléments bloquants ci-dessus ; aucun module ne sera lancé.\n'
    return 1
  fi

  printf '[PRÊT] Le lancement peut continuer avec les limites annoncées ci-dessus.\n'
}
