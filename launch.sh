#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
AUDIT="${SCRIPT_DIR}/audit.sh"

[[ -x "$AUDIT" ]] || { echo "[-] audit.sh introuvable."; exit 1; }

TARGETS_DEFAULT="192.168.1.0/24"
DUR_DEFAULT="600"

if command -v whiptail >/dev/null; then
  TARGETS=$(whiptail --title "Cibles" --inputbox "CIDR (ex: 192.168.1.0/24)" 10 70 "$TARGETS_DEFAULT" 3>&1 1>&2 2>&3) || exit 1
  DUR=$(whiptail --title "Durée (s)" --inputbox "Durée du scan" 10 60 "$DUR_DEFAULT" 3>&1 1>&2 2>&3) || exit 1
  PROFILE=$(whiptail --title "Profil" --menu "Choisir un profil" 15 60 4 \
    "fast" "Scan rapide" \
    "full" "Scan complet" \
    "stealth" "Scan furtif" \
    3>&1 1>&2 2>&3) || exit 1
else
  read -rp "CIDR [$TARGETS_DEFAULT]: " TARGETS
  TARGETS=${TARGETS:-$TARGETS_DEFAULT}
  read -rp "Durée [$DUR_DEFAULT]: " DUR
  DUR=${DUR:-$DUR_DEFAULT}
  read -rp "Profil (fast|full|stealth) [fast]: " PROFILE
  PROFILE=${PROFILE:-fast}
fi

echo "[+] Lancement: $AUDIT -t \"$TARGETS\" -d \"$DUR\" -p \"$PROFILE\""
exec "$AUDIT" -t "$TARGETS" -d "$DUR" -p "$PROFILE"
