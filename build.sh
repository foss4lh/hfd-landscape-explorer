#!/bin/bash
set -euo pipefail

echo "=== Netlify Build ==="

# Download Rotherwas tiles from GitHub Release
TILES_URL="https://github.com/foss4lh/hfd-landscape-explorer/releases/download/v0.1.0/rotherwas-tiles.tar.gz"
TILES_TAR="/tmp/rotherwas-tiles.tar.gz"
TILES_DIR="public/tiles/rotherwas"

echo "[1/4] Downloading Rotherwas tiles from GitHub Release..."
curl -fsSL "$TILES_URL" -o "$TILES_TAR"
echo "  ✓ Downloaded $(du -h "$TILES_TAR" | cut -f1)"

echo "[2/4] Extracting Rotherwas tiles..."
mkdir -p "$TILES_DIR"
tar xzf "$TILES_TAR" -C public/tiles
TILE_COUNT=$(find "$TILES_DIR" -name "*.png" | wc -l)
echo "  ✓ $TILE_COUNT tiles extracted"

# Download Whitby Tithe PMTiles (example historical dataset)
WHITBY_URL="https://github.com/foss4lh/hfd-landscape-explorer/releases/download/v0.1.0/whitby-tithe.pmtiles"
WHITBY_FILE="/tmp/whitby-tithe.pmtiles"

echo "[3/4] Downloading Whitby Tithe PMTiles..."
curl -fsSL "$WHITBY_URL" -o "$WHITBY_FILE"
echo "  ✓ Downloaded $(du -h "$WHITBY_FILE" | cut -f1)"
mv "$WHITBY_FILE" public/

# TODO: Add additional dataset downloads here
# Example format:
# DATASET_URL="https://github.com/foss4lh/hfd-landscape-explorer/releases/download/v0.1.0/your-dataset.pmtiles"
# DATASET_FILE="/tmp/your-dataset.pmtiles"
# echo "[4/4] Downloading Your Dataset PMTiles..."
# curl -fsSL "$DATASET_URL" -o "$DATASET_FILE"
# echo "  ✓ Downloaded $(du -h "$DATASET_FILE" | cut -f1)"
# mv "$DATASET_FILE" public/

echo "[4/4] Building app..."
bun run build

echo "=== Build complete ==="