#!/usr/bin/env bash
set -Eeuo pipefail
has_cmd(){ command -v "$1" >/dev/null 2>&1; }
_ui_whiptail_list(){
  local title="$1"; shift; local items=("$@")
  whiptail --title "$title" --menu "Sélection" 20 70 10 "${items[@]}" 3>&1 1>&2 2>&3
}
ui_pick_profile(){
  if has_cmd whiptail; then
    local sel; sel="$(_ui_whiptail_list 'Profil' fast 'Rapide' full 'Complet' stealth 'Discret')" || return 1
    echo "$sel"
  else
    echo "fast"
  fi
}
ui_enter_targets(){
  if has_cmd whiptail; then
    whiptail --inputbox "CIDR multiples (ex: 192.168.1.0/24,192.168.27.0/24)" 10 70 "" 3>&1 1>&2 2>&3
  else
    read -rp "Cibles (CIDR, virgules) : " v; echo "$v"
  fi
}
ui_pick_categories(){
  # Case à cocher minimale (stub): renvoie liste modules logique (par tags)
  echo "discovery,portscan,vuln,http,report"
}
ui_confirm_opts(){
  echo "OPTS_NO_UDP=0,OPTS_NO_ZEEK=1,OPTS_NO_SURICATA=1"
}
