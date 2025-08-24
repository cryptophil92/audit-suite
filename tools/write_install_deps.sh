#!/usr/bin/env bash
set -Eeuo pipefail
PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")"/.. && pwd)"
DEST="$PROJECT_ROOT/scripts/install_deps.sh"
backup() { [[ -f "$1" ]] && cp -a -- "$1" "$1.bak.$(date -u +%Y%m%dT%H%M%SZ)" || true; }
backup "$DEST"
cat >"$DEST" <<'SH'
#!/usr/bin/env bash
set -Eeuo pipefail
need() { command -v "$1" >/dev/null 2>&1; }
apt_install() {
  local pkgs=("$@"); (( ${#pkgs[@]} )) || return 0
  if [[ $EUID -ne 0 ]]; then sudo apt-get update -y; sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${pkgs[@]}";
  else apt-get update -y; DEBIAN_FRONTEND=noninteractive apt-get install -y "${pkgs[@]}"; fi
}
to_install=()
need git        || to_install+=(git)
need curl       || to_install+=(curl)
need jq         || to_install+=(jq)
need shellcheck || to_install+=(shellcheck)
need nmap       || to_install+=(nmap)
need arp-scan   || to_install+=(arp-scan)
need tcpdump    || to_install+=(tcpdump)
need tshark     || to_install+=(tshark)
need zeek       || to_install+=(zeek)
need suricata   || to_install+=(suricata)
need parallel   || to_install+=(parallel)
need gawk       || to_install+=(gawk)
(( ${#to_install[@]} )) && { echo "Install: ${to_install[*]}"; apt_install "${to_install[@]}"; } || echo "Dépendances déjà satisfaites"
echo "OK"
SH
chmod +x "$DEST"
echo "scripts/install_deps.sh écrit."
