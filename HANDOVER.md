# Handover: hfd-landscape-explorer

## Current Status
- **Stack**: Svelte 5 (Runes), OpenLayers 10, Bun, Vite.
- **Features**:
    - Interactive map centered on Herefordshire.
    - OpenStreetMap base layer.
    - Local `XYZ` tile layer pointing to `/tiles/rotherwas` (symlinked from `rotherwas-tiles` repo).
    - Prototype `WebGLTile` layer using a Sentinel-2 Cloud-Optimized GeoTIFF (COG).
- **Environment**:
    - Node version: `v24.14.0`
    - Runtime: `Bun 1.3.13`
    - Key dependencies: `ol`, `svelte-openlayers`, `@lucide/svelte`.

## Key Findings & Diagnostics
1. **Component Nesting**: `svelte-openlayers` requires `<Map>` to be a child of `<View>` to properly propagate the OpenLayers context.
2. **WebGL Performance**: The `WebGLTile` layer is the recommended path for high-res historical scans.
3. **COG Integration**: There is a known `fetchSlice` error with the placeholder Sentinel-2 COG URL. This is likely a CORS issue or a change in the S3 bucket access. For the actual Herefordshire data, we should host COGs on **Cloudflare R2** with appropriate CORS headers.
4. **Data Size**: We have downloaded `Habitat.zip` (~21GB) to the parent `foss4lh/` directory. This needs extraction and processing.

## Suggested Next Steps
1. **Host Data**: Move extracted `.tiff` / `.acw` files to a Cloudflare R2 bucket.
2. **Convert to COG/PMTiles**: Use GDAL (in `hfd-data-ops`) to convert raw scans into Web Mercator COGs.
3. **Fix CORS**: Ensure the data hosting bucket allows range requests from the web app's domain.
4. **UI Controls**:
    - Add a layer-switcher component to toggle between modern OSM and historical layers.
    - Implement an opacity slider for temporal comparisons.
5. **Parish Logic**: Implement dynamic routing or a search bar to jump to specific parishes (e.g., Leominster, Rotherwas).

## Developer Notes
- **Vite Server**: Was running on port `5174`.
- **Symlinks**: `public/tiles/rotherwas` is currently a symlink to `/home/robin/github/foss4lh/rotherwas-tiles/t-raf-47`. This needs to be replaced with a proper asset pipeline.
