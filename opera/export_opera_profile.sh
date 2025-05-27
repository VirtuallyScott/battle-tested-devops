#!/bin/bash

# Export a "golden" Opera profile for replication

set -euo pipefail

SOURCE_DIR="$HOME/Library/Application Support/com.operasoftware.Opera"
DEST_DIR="$HOME/Desktop/opera_profile_export"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
EXPORT_TAR="$DEST_DIR/opera_profile_$TIMESTAMP.tar.gz"

mkdir -p "$DEST_DIR"

echo "[INFO] Archiving Opera profile from: $SOURCE_DIR"
tar --exclude="Crash Reports" \
    --exclude="Thumbnails" \
    --exclude="GPUCache" \
    --exclude="ShaderCache" \
    --exclude="GrShaderCache" \
    --exclude="Media Cache" \
    --exclude="Application Cache" \
    -czf "$EXPORT_TAR" -C "$SOURCE_DIR" .

echo "[INFO] Opera profile exported to: $EXPORT_TAR"
