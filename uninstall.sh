#!/bin/bash
# =============================================================================
# APT Tracker — Uninstaller
# =============================================================================

set -e

INSTALL_BIN="/usr/local/bin/apt"
TRACKER_DIR="/var/lib/apt-tracker"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
RESET='\033[0m'

ok()   { echo -e "${GREEN}✔ $1${RESET}"; }
warn() { echo -e "${YELLOW}⚠ $1${RESET}"; }
fail() { echo -e "${RED}✘ $1${RESET}"; exit 1; }

echo ""
echo -e "${BOLD}APT Tracker Uninstaller${RESET}"
echo ""

[ "$EUID" -ne 0 ] && fail "Run as root: sudo bash uninstall.sh"

# ─────────────────────────────────────────────
# Remove wrapper safely
# ─────────────────────────────────────────────
if [ -f "$INSTALL_BIN" ]; then
    if grep -q "APT Tracker Wrapper" "$INSTALL_BIN"; then
        rm -f "$INSTALL_BIN"
        ok "Wrapper removed"
    else
        warn "File exists but not our wrapper — skipping"
    fi
else
    warn "Wrapper not found"
fi

# ─────────────────────────────────────────────
# Remove data
# ─────────────────────────────────────────────
echo ""
read -p "Delete all logs ($TRACKER_DIR)? [y/N]: " confirm

if [[ "$confirm" =~ ^[Yy]$ ]]; then
    rm -rf "$TRACKER_DIR"
    ok "All logs deleted"
else
    ok "Logs preserved at $TRACKER_DIR"
fi

echo ""
echo -e "${GREEN}Uninstalled successfully${RESET}"
echo "System apt (/usr/bin/apt) is untouched."
echo ""
