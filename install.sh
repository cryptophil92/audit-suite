#!/usr/bin/env bash
set -Eeuo pipefail

echo "[*] Installing dependencies (idempotent)…"

sudo apt update
sudo apt -y install nmap masscan jq tmux whiptail

# Optionnels : Zeek & Suricata (commenter si inutile)
sudo apt -y install zeek suricata || true

echo "[+] All dependencies installed."
