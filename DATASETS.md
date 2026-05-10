# Adding New Historical Map Datasets to hfd-landscape-explorer

This document describes how to add new georeferenced historical map datasets to the foss4lh Landscape Explorer.

## Overview

Datasets are added as PMTiles archives (`.pmtiles` files) which contain XYZ tile pyramids in the Web Mercator projection (EPSG:3857). The PMTiles format allows efficient serving of large raster datasets without needing a tile server - the browser fetches only the tiles needed for the current view via HTTP range requests.

## Pipeline for Adding a Dataset

1. **Source Data**: Start with a georeferenced raster (GeoTIFF, ECW, etc.) in British National Grid (EPSG:27700)
2. **Generate Tiles**: Use `gdal2tiles.py` to create an XYZ tile pyramid (Web Mercator)
3. **Compute Bounds**: Calculate geographic bounds from tile indices  
4. **Create Metadata**: Generate `metadata.json` with dataset info and bounds
5. **Build PMTiles**: Convert XYZ tiles → PMTiles archive using the `pmtiles` Python package
6. **Host**: Upload the `.pmtiles` file as a GitHub Release asset
7. **Configure**: Add the dataset to `src/App.svelte` with its name, year, region, parish, center coordinates, and zoom level

## Detailed Steps

### 1. Prepare Source Data

Your georeferenced raster must be in a format GDAL can read (GeoTIFF preferred, ECW requires special driver). For the David Lovelace archive, ECW files are available in `/media/robin/foss4lh/david-lovelace-archive/Maps/`.

Verify georeferencing:
```bash
# Using the ECW-enabled Docker container
docker run --rm -v /path/to/your/Maps:/data:ro ginetto/gdal:2.4.4_ECW \
  gdalinfo /data/yourfile.ecw | grep -A5 "Coordinate System"
```

### 2. Generate XYZ Tiles (Docker)

```bash
# Create output directory
mkdir -p /tmp/your-dataset-tiles

# Generate tiles (adjust zoom levels as needed)
docker run --rm \
  -v /media/robin/foss4lh/david-lovelace-archive/Maps:/data:ro \
  -v /tmp/your-dataset-tiles:/out \
  ginetto/gdal:2.4.4_ECW \
  gdal2tiles.py \
    -p mercator \
    -s EPSG:27700 \  # British National Grid
    -z 10-16 \       # Min-max zoom levels
    --processes 4 \  # Parallel processes
    -v \             # Verbose
    /data/yourfile.ecw \
    /out
```

### 3. Compute Geographic Bounds

```bash
# Use the helper script from hfd-data-ops/tithe-pmtiles/compute_bounds.py
python3 /path/to/hfd-data-ops/tithe-pmtiles/compute_bounds.py \
  /tmp/your-dataset-tiles --min-zoom 10 --max-zoom 16
```

This will output bounds in the format: `-2.510,52.238,-2.368,52.174`

### 4. Create metadata.json

In the tile directory, create `metadata.json`:
```json
{
  "name": "Your Dataset Name",
  "description": "Brief description of the dataset",
  "version": "1.0",
  "format": "jpeg",
  "minzoom": 10,
  "maxzoom": 16,
  "bounds": "-2.510,52.238,-2.368,52.174",
  "center": "-2.439,52.206,12"
}
```

### 5. Build PMTiles Archive

Using the Python `pmtiles` package:
```bash
pip install pmtiles
```

Or use the provided script in `hfd-data-ops/tithe-pmtiles/convert_to_pmtiles.sh`:
```bash
# Adjust paths as needed
./convert_to_pmtiles.sh \
  /media/robin/foss4lh/david-lovelace-archive/Maps/yourfile.ecw \
  "Your Dataset Name" \
  /path/to/output/directory \
  10 \  # min zoom
  16    # max zoom
```

This produces `your-dataset-name.pmtiles` (typically 20-100MB depending on area and zoom range).

### 6. Host as GitHub Release

1. Create a new release (or use existing) in the `hfd-landscape-explorer` repo
2. Upload your `.pmtiles` file as a release asset
3. Copy the direct download URL (format: `https://github.com/foss4lh/hfd-landscape-explorer/releases/download/vX.Y.Z/yourfile.pmtiles`)

### 7. Update Build Script

Edit `build.sh` in the `hfd-landscape-explorer` repo to download your new PMTiles:
```bash
# Add after the rotherwas tiles section
YOUR_DATASET_URL="https://github.com/foss4lh/hfd-landscape-explorer/releases/download/v0.1.0/your-dataset-name.pmtiles"
YOUR_DATASET_FILE="/tmp/your-dataset-name.pmtiles"
YOUR_DATASET_DIR="public/"

echo "[4/4] Downloading your dataset PMTiles..."
curl -fsSL "$YOUR_DATASET_URL" -o "$YOUR_DATASET_FILE"
echo "  ✓ Downloaded $(du -h "$YOUR_DATASET_FILE" | cut -f1)"

mv "$YOUR_DATASET_FILE" "$YOUR_DATASET_DIR/"
```

### 8. Register in App.svelte

Edit `src/App.svelte` to add your dataset to the `datasets` array:
```javascript
const datasets = [
  {id:'rotherwas', name:'Rotherwas (demo)', year:1947, region:'Hereford', parish:'Rotherwas', source:new XYZ({url:'tiles/rotherwas/{z}/{x}/{-y}.png',maxZoom:16,minZoom:10})},
  {id:'tithe', name:'Whitby Tithe (PMTiles demo)', year:1947, region:'Hereford', parish:'Whitby', source: whitbyTithe, center:[-2.439,52.206], zoom:12},
  {id:'your-dataset', name:'Your Dataset Name', year:1850, region:'Herefordshire', parish:'Your Parish', source: yourPMTilesSource, center:[lon, lat], zoom:12},
  {id:'aero', name:'Aerofilms', year:1928, region:'Herefordshire', parish:'', source:null}
];
```

Where `yourPMTilesSource` is defined similarly to `whitbyTithe`:
```javascript
const yourPMTilesSource = new PMTilesRasterSource({
  url: 'your-dataset-name.pmtiles',
  attributions: '© David Lovelace Archive — Your Dataset Name',
  tileSize: 256
});
```

## Automation & Reproducibility

All scripts for the Whitby Tithe Map example are available in:
- `~/github/foss4lh/hfd-data-ops/tithe-pmtiles/convert_to_pmtiles.sh` - generic pipeline
- `~/github/foss4lh/hfd-data-ops/tithe-pmtiles/run_whitby.sh` - specific execution for Whitby
- `~/github/foss4lh/hfd-data-ops/tithe-pmtiles/compute_bounds.py` - bounds computation utility

These are version-controlled in the `hfd-data-ops` repository.

## Notes on Projections

- Source data in the David Lovelace archive is primarily in **EPSG:27700** (British National Grid / OSGB 1936)
- Tiles are generated in **EPSG:3857** (Web Mercator) for web compatibility
- The `gdal2tiles.py` command handles the reprojection via `-s EPSG:27700 -t_srs EPSG:3857` (implicit in `-p mercator` with source SRS)

## Storage Considerations

- PMTiles files are typically 20-50 MB for parish-scale datasets at zoom 10-16
- GitHub has a 2 GB limit per release asset and 5 GB total per release
- Consider using Git LFS or external hosting (Cloudflare R2, AWS S3) for larger datasets or many datasets
- The Netlify build process downloads PMTiles at deploy time, so they are not stored in the Git repository

## Troubleshooting

### "No such option: -f" or "--t_s_srs"
Use the correct `gdal2tiles.py` syntax from the OSGeo GDAL Docker image:
```bash
gdal2tiles.py -p mercator -s EPSG:27700 -z 10-16 --processes 4 -v input.tif output/
```

### Bounds appear wrong (e.g., latitude -52 instead of +52)
This indicates a TMS/Y-axis flip issue. Use the fixed `compute_bounds.py` from `hfd-data-ops/tithe-pmtiles/` which correctly handles:
- Raw y → TMS y conversion: `tms_y = (1<<z) - 1 - raw_y`
- Proper geographic coordinate calculation

### PMTiles fails to load in browser
Check:
1. The file is accessible via direct URL (try downloading it with curl/wget)
2. The Netlify deployment includes the file in `dist/`
3. Browser console for 404 errors on `.pmtiles` requests
4. Attributions and tileSize in PMTilesRasterSource configuration