#!/usr/bin/env bash
# core/lib_args.sh
# @version 0.2.7
set -Eeuo pipefail

AUDIT_ARG_HELP=0
AUDIT_ARG_ALLOW_PUBLIC=0
AUDIT_ARG_PROFILE=""
AUDIT_ARG_TARGETS=""
AUDIT_ARG_CATEGORIES=""
AUDIT_ARG_OPTS=""

usage() {
  cat <<'EOF'
Usage: ./audit.sh [options]

Options:
  --profile <fast|full|stealth>       Définit le profil sans menu interactif.
  --targets <cidr[,cidr...]>          Définit les cibles sans menu interactif.
  --categories <module[,module...]>   Définit les modules/catégories sans menu interactif.
  --no-udp                            Désactive UDP.
  --no-zeek                           Désactive Zeek.
  --no-suricata                       Désactive Suricata.
  --allow-public                      Autorise les cibles publiques avec autorisation explicite.
  -h, --help                          Affiche cette aide.

Par défaut, AUDIT-SUITE refuse les IP/plages publiques et accepte uniquement les périmètres locaux/lab.

Exemple:
  ./audit.sh --profile fast --targets 192.168.1.0/24 --categories 10_network_discovery.sh,20_portscan_nmap.sh --no-zeek --no-suricata
EOF
}

_args_require_value() {
  local opt="$1"
  local value="${2:-}"

  if [[ -z "$value" || "$value" == --* ]]; then
    echo "Valeur manquante pour $opt" >&2
    return 1
  fi
}

_args_validate_profile() {
  local profile="$1"

  case "$profile" in
    fast|full|stealth)
      return 0
      ;;
    *)
      echo "Profil invalide: $profile" >&2
      return 1
      ;;
  esac
}

_args_append_opt() {
  local opt="$1"

  if [[ -z "$AUDIT_ARG_OPTS" ]]; then
    AUDIT_ARG_OPTS="$opt"
  else
    case ",$AUDIT_ARG_OPTS," in
      *",$opt,"*) ;;
      *) AUDIT_ARG_OPTS=",$AUDIT_ARG_OPTS,$opt" ;;
    esac
  fi
}

parse_audit_args() {
  AUDIT_ARG_HELP=0
  AUDIT_ARG_ALLOW_PUBLIC=0
  AUDIT_ARG_PROFILE=""
  AUDIT_ARG_TARGETS=""
  AUDIT_ARG_CATEGORIES=""
  AUDIT_ARG_OPTS=""

  while (( $# > 0 )); do
    case "$1" in
      --profile)
        _args_require_value "$1" "${2:-}"
        _args_validate_profile "$2"
        AUDIT_ARG_PROFILE="$2"
        shift 2
        ;;
      --profile=*)
        AUDIT_ARG_PROFILE="${1#*=}"
        _args_validate_profile "$AUDIT_ARG_PROFILE"
        shift
        ;;
      --targets)
        _args_require_value "$1" "${2:-}"
        AUDIT_ARG_TARGETS="$2"
        shift 2
        ;;
      --targets=*)
        AUDIT_ARG_TARGETS="${1#*=}"
        _args_require_value "--targets" "$AUDIT_ARG_TARGETS"
        shift
        ;;
      --categories)
        _args_require_value "$1" "${2:-}"
        AUDIT_ARG_CATEGORIES="$2"
        shift 2
        ;;
      --categories=*)
        AUDIT_ARG_CATEGORIES="${1#*=}"
        _args_require_value "--categories" "$AUDIT_ARG_CATEGORIES"
        shift
        ;;
      --no-udp)
        _args_append_opt "no-udp"
        shift
        ;;
      --no-zeek)
        _args_append_opt "no-zeek"
        shift
        ;;
      --no-suricata)
        _args_append_opt "no-suricata"
        shift
        ;;
      --allow-public)
        AUDIT_ARG_ALLOW_PUBLIC=1
        shift
        ;;
      -h|--help)
        AUDIT_ARG_HELP=1
        shift
        ;;
      *)
        echo "Option inconnue: $1" >&2
        return 2
        ;;
    esac
  done
}

normalize_csv_to_commas() {
  local value="$1"
  printf '%s' "$value" | tr ' \n' ',' | sed 's/,,*/,/g; s/^,//; s/,$//'
}
