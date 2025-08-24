#!/usr/bin/env bash
# core/lib_detect.sh
# @version 0.1.0
set -Eeuo pipefail

detect_env() {
  DEF_IFACE="$(ip route show default 2>/dev/null | awk '/default/ {print $5; exit}')" || true
  [[ -z "${DEF_IFACE:-}" ]] && DEF_IFACE="$(ip -o link show | awk -F': ' '$2!~/(lo)/{print $2; exit}')"
  DEF_CIDR="$(ip -o -f inet addr show "$DEF_IFACE" 2>/dev/null | awk '{print $4; exit}')" || true
  HAVE_X11=0; [[ -n "${DISPLAY:-}" ]] && HAVE_X11=1
  HAVE_TMUX=0; command -v tmux >/dev/null 2>&1 && HAVE_TMUX=1
  export DEF_IFACE DEF_CIDR HAVE_X11 HAVE_TMUX
}
