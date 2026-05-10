#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TILES_REPO="https://github.com/foss4lh/rotherwas-tiles.git"
TILES_BRANCH="gh-pages"
TILES_DIR="$SCRIPT_DIR/public/tiles/rotherwas"

echo "=== foss4lh Landscape Explorer Deploy ==="

# Step 1: Download tiles from rotherwas-tiles repo
echo "[1/3] Fetching raster tiles from $TILES_REPO (branch: $TILES_BRANCH)..."
if [ -d "$TILES_DIR/.git" ]; then
  echo "  Updating existing tile cache..."
  cd "$TILES_DIR" && git pull origin "$TILES_BRANCH" --ff-only 2>/dev/null || true
else
  echo "  Cloning tiles..."
  rm -rf "${TILES_DIR:?}"
  git clone --depth 1 --branch "$TILES_BRANCH" "$TILES_REPO" "$TILES_DIR" --sparse
  cd "$TILES_DIR" && git sparse-checkout set t-raf-47 && mv t-raf-47/* . && rmdir t-raf-47 2>/dev/null || true
fi
TILE_COUNT=$(find "$TILES_DIR" -name "*.png" | wc -l)
echo "  ✓ $TILE_COUNT tiles ready ($(du -sh "$TILES_DIR" | cut -f1))"

# Step 2: Build the app
echo ""
echo "[2/3] Building..."
cd "$SCRIPT_DIR"
bun install 2>/dev/null || npm install 2>/dev/null || true
bun run build || npm run build

# Step 3: Deploy to GitHub Pages
echo ""
echo "[3/3] Deploying to gh-pages branch..."
npx gh-pages -d dist -m "Deploy $(date -u '+%Y-%m-%d %H:%M UTC') [skip ci]"

echo ""
echo "=== Deploy complete ==="
echo "Map app:    https://foss4lh.github.io/hfd-landscape-explorer/"
echo "Docs page: https://foss4lh.github.io/hfd-landscape-explorer/docs.html"
echo "Tiles:     $TILE_COUNT PNG files served statically"
