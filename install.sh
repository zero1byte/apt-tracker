#!/bin/bash
set -e

WRAPPER_SRC="./apt-wrapper"
INSTALL_BIN="/usr/local/bin/apt"
TRACKER_DIR="/var/lib/apt-tracker"
RECORDS_FILE="$TRACKER_DIR/records.csv"

[ "$EUID" -ne 0 ] && { echo "Run as root"; exit 1; }

mkdir -p "$TRACKER_DIR"
[ -f "$RECORDS_FILE" ] || echo "action,package,version,timestamp,user,status" > "$RECORDS_FILE"
chmod 666 "$RECORDS_FILE"

cp "$WRAPPER_SRC" "$INSTALL_BIN"
chmod +x "$INSTALL_BIN"

echo "✅ Installed successfully"
