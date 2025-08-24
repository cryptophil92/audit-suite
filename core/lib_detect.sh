#!/usr/bin/env bash
set -Eeuo pipefail
has_cmd(){ command -v "$1" >/dev/null 2>&1; }
is_x11(){ [[ -n "${DISPLAY:-}" ]]; }
detect_env(){
  DEF_IFACE="$(ip route | awk '/default/ {print $5; exit}')"
  DEF_CIDR="$(ip -o -f inet addr show "$DEF_IFACE" | awk '{print $4; exit}')"
  HAVE_X11=$([[ -n "${DISPLAY:-}" ]] && echo 1 || echo 0)
  HAVE_TMUX=$([[ -n "${TMUX:-}" ]] || has_cmd tmux && echo 1 || echo 0)
  export DEF_IFACE DEF_CIDR HAVE_X11 HAVE_TMUX
}
