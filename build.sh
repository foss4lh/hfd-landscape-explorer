#!/bin/bash
set -euo pipefail

echo "=== Netlify Build ==="

# Download tiles from GitHub Release
TILES_URL="https://github.com/foss4lh/hfd-landscape-explorer/releases/download/v0.1.0/rotherwas-tiles.tar.gz"
TILES_TAR="/tmp/rotherwas-tiles.tar.gz"
TILES_DIR="public/tiles/rotherwas"

echo "[1/3] Downloading tiles from GitHub Release..."
curl -fsSL "$TILES_URL" -o "$TILES_TAR"
echo "  ✓ Downloaded $(du -h "$TILES_TAR" | cut -f1)"

echo "[2/3] Extracting tiles..."
mkdir -p "$TILES_DIR"
tar xzf "$TILES_TAR" -C public/tiles
TILE_COUNT=$(find "$TILES_DIR" -name "*.png" | wc -l)
echo "  ✓ $TILE_COUNT tiles extracted"

echo "[3/3] Building app..."
bun run build

echo "=== Build complete ==="