#!/bin/bash

# Import Opera profile to a target machine

set -euo pipefail

TARBALL="$1"
TARGET_DIR="$HOME/Library/Application Support/com.operasoftware.Opera"

if [ ! -f "$TARBALL" ]; then
    echo "[ERROR] Opera profile archive not found: $TARBALL"
    exit 1
fi

echo "[INFO] Backing up current Opera config (if any)..."
if [ -d "$TARGET_DIR" ]; then
    mv "$TARGET_DIR" "${TARGET_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
fi

echo "[INFO] Restoring Opera config from archive..."
mkdir -p "$TARGET_DIR"
tar -xzf "$TARBALL" -C "$TARGET_DIR"

echo "[INFO] Import complete. You may want to restart Opera."
