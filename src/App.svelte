<script>
	import 'ol/ol.css';
	import { Map, View, LayerTile } from 'svelte-openlayers';
	import XYZ from 'ol/source/XYZ';
	import OSM from 'ol/source/OSM';
	import { fromLonLat } from 'ol/proj';
	import ScaleLine from 'ol/control/ScaleLine';
	import YearRangeSlider from './lib/YearRangeSlider.svelte';
	import Combobox from './lib/Combobox.svelte';
	import DatasetList from './lib/DatasetList.svelte';
	import { PMTilesRasterSource } from 'ol-pmtiles';

	let olMap = $state(null);
	let z=$state(10.5), c=$state(fromLonLat([-2.72, 52.08]));
	let yearRange = $state([1800, 2024]);
	let datasetFilter = $state('all');
	let regionFilter = $state('');
	let zoomToDataset = $state(false);
	let overlayOpacity = $state(0.8);
	let selectedBasemap = $state('positron');
	let isSidebarOpen = $state(true);

	const basemaps = [
		{
			id: 'positron',
			name: 'CARTO Positron',
			source: new XYZ({
				url: 'https://a.basemaps.cartocdn.com/rastertiles/light_all/{z}/{x}/{y}.png',
				attributions: '&copy; <a href="https://carto.com/">CARTO</a> &copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
				crossOrigin: 'anonymous',
				maxZoom: 20
			})
		},
		{
			id: 'voyager',
			name: 'CARTO Voyager',
			source: new XYZ({
				url: 'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
				attributions: '&copy; <a href="https://carto.com/">CARTO</a> &copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
				crossOrigin: 'anonymous',
				maxZoom: 20
			})
		},
		{
			id: 'osm',
			name: 'OpenStreetMap',
			source: new OSM()
		},
		{
			id: 'imagery',
			name: 'Esri World Imagery',
			source: new XYZ({
				url: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
				attributions: '&copy; Esri',
				crossOrigin: 'anonymous',
				maxZoom: 19
			})
		}
	];

    // Whitby tithe map PMTiles source
    const whitbyTithe = new PMTilesRasterSource({
        url: 'whitby-tithe.pmtiles',
        attributions: '© David Lovelace Archive — Whitby Tithe Map (ECW)',
        tileSize: 256
    });

    const datasets = [
        {id:'rotherwas', name:'Rotherwas (demo)', year:1947, region:'Hereford', parish:'Rotherwas', source:new XYZ({url:'tiles/rotherwas/{z}/{x}/{-y}.png',maxZoom:16,minZoom:10})},
        {id:'tithe', name:'Whitby Tithe (PMTiles demo)', year:1947, region:'Hereford', parish:'Whitby', source: whitbyTithe, center:[-2.439,52.206], zoom:12},
        {id:'aero', name:'Aerofilms', year:1928, region:'Herefordshire', parish:'', source:null}
    ];

	const datasetOptions = [
		{ value:'all', label:'All Datasets', year:null },
		...datasets.map(d => ({ value:d.id, label:d.name, year:d.year, region:d.region, parish:d.parish }))
	];

	const regionOptions = [
		{ value:'', label:'All Regions', year:null },
		...Array.from(new Set(datasets.flatMap(d => [d.region, d.parish].filter(Boolean)))).map(r => ({ value:r, label:r, year:null }))
	];

	const visibleDatasetIds = $derived(datasets
		.filter(d => {
			const inRange = d.year >= yearRange[0] && d.year <= yearRange[1];
			const matchDataset = datasetFilter === 'all' || d.id === datasetFilter;
			const matchRegion = !regionFilter || d.region === regionFilter || d.parish === regionFilter;
			return d.source && inRange && matchDataset && matchRegion;
		})
		.map(d => d.id)
	);

	function onSelectDataset(id) {
		datasetFilter = id;
		if (!zoomToDataset) return;
		const ds = datasets.find(d => d.id === id);
		if (ds && ds.source) {
			c = fromLonLat(ds.center || [-2.72, 52.08]);
			z = ds.zoom || 12;
		}
	}

	function onZoom(ds) {
		if (!ds.source || !zoomToDataset) return;
		c = fromLonLat(ds.center || [-2.72, 52.08]);
		z = ds.zoom || 12;
	}

	// Add scale bar control once the map is ready
	$effect(() => {
		if (olMap) {
			olMap.addControl(new ScaleLine({
				units: 'metric',
				bar: true,
				steps: 4,
				text: true,
				minWidth: 140
			}));
		}
	});
</script>

<main>
    {#if isSidebarOpen}
	<div class="c">
        <div class="header">
		    <h2>foss4lh Explorer</h2>
            <button class="toggle-btn" onclick={() => isSidebarOpen = false}>✕</button>
        </div>
        <Combobox label="Dataset" options={datasetOptions} bind:value={datasetFilter} placeholder="Search datasets..." yearRange={yearRange} />
        <Combobox label="Region/Parish" options={regionOptions} bind:value={regionFilter} placeholder="Search region or parish..." yearRange={yearRange} />
        <label class="zoom-toggle">
			<input type="checkbox" bind:checked={zoomToDataset} /> Zoom to dataset
		</label>
        <div class="field-label">Years: {yearRange[0]} – {yearRange[1]}</div>
        <div class="s">
            <YearRangeSlider bind:values={yearRange} min={1800} max={2024} step={10} />
        </div>
        <div class="field-label">Overlay opacity: {Math.round(overlayOpacity * 100)}%</div>
        <div class="opacity-control">
            <input type="range" min="0" max="1" step="0.05" bind:value={overlayOpacity} />
        </div>
        <DatasetList datasets={datasets} visibleIds={visibleDatasetIds} {yearRange} onSelect={onSelectDataset} onZoom={onZoom} />
	</div>
    {/if}

    <div class="map-wrapper">
        {#if !isSidebarOpen}
            <button class="toggle-btn open-btn" onclick={() => isSidebarOpen = true}>☰</button>
        {/if}
        <View bind:zoom={z} bind:center={c}>
            <Map class="m" bind:map={olMap}>
                {#each basemaps as bm}
                    <LayerTile source={bm.source} visible={selectedBasemap === bm.id} />
                {/each}
                {#each datasets as ds}
                    {#if visibleDatasetIds.includes(ds.id)}
                        <LayerTile source={ds.source} opacity={overlayOpacity} />
                    {/if}
                {/each}
            </Map>
        </View>

        <div class="basemap-selector">
            <label for="basemap-select">Basemap</label>
            <select id="basemap-select" bind:value={selectedBasemap}>
                {#each basemaps as bm}
                    <option value={bm.id}>{bm.name}</option>
                {/each}
            </select>
        </div>
    </div>
</main>

<style>
    :global(body){margin:0;padding:0;overflow:hidden;font-family:system-ui,-apple-system,sans-serif}
    main { display: flex; height: 100vh; width: 100vw; }
    .map-wrapper { position: relative; flex: 1; height: 100vh; }
    :global(.m){width:100%;height:100%}
    .c{width:320px;max-width:100vw;height:100vh;background:#fefcf6;padding:1.1rem;box-shadow:2px 0 12px rgba(0,0,0,0.1);display:flex;flex-direction:column;gap:0.6rem;overflow-y:auto;border-right:1px solid #e8e4da;box-sizing:border-box;flex-shrink:0}
    .header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 0.5rem; }
    h2{margin:0;font-size:1.25rem;color:#3d3b36;letter-spacing:-0.02em}
    .toggle-btn { background: #fff; border: 1px solid #d5d0c5; border-radius: 6px; padding: 4px 8px; cursor: pointer; font-size: 1.1rem; color: #6b665c; }
    .toggle-btn:hover { background: #f0eee8; }
    .open-btn { position: absolute; top: 70px; left: 10px; z-index: 1000; box-shadow: 0 2px 8px rgba(0,0,0,0.15); padding: 6px 10px; font-size: 1.3rem; }
    .s{display:flex;flex-direction:column}
    label,.field-label{font-size:0.85rem;color:#6b665c;font-weight:500}
    .zoom-toggle{display:flex;align-items:center;gap:0.4rem;cursor:pointer;padding:0.2rem 0;font-size:0.8rem;color:#6b665c}
    .zoom-toggle input{accent-color:#6b7f5e;cursor:pointer}

    .basemap-selector {
        position: absolute;
        top: 10px;
        right: 10px;
        z-index: 100;
        display: flex;
        flex-direction: column;
        gap: 4px;
    }
    .basemap-selector label {
        font-size: 0.75rem;
        color: #6b665c;
        font-weight: 500;
    }
    .basemap-selector select {
        padding: 0.35rem 2rem 0.35rem 0.5rem;
        border: 1px solid #d5d0c5;
        border-radius: 6px;
        font-size: 0.85rem;
        background: #fefcf6;
        color: #3d3b36;
        box-shadow: 0 4px 12px rgba(0,0,0,0.15);
        outline: none;
        cursor: pointer;
        -webkit-appearance: none;
        appearance: none;
        background-image: url("data:image/svg+xml,%3Csvg width='10' height='6' viewBox='0 0 10 6' fill='none' xmlns='http://www.w3.org/2000/svg'%3E%3Cpath d='M1 1l4 4 4-4' stroke='%236b665c' stroke-width='1.5' stroke-linecap='round' stroke-linejoin='round'/%3E%3C/svg%3E");
        background-repeat: no-repeat;
        background-position: right 0.5rem center;
    }
    .basemap-selector select:focus {
        border-color: #6b7f5e;
        box-shadow: 0 0 0 2px rgba(107, 127, 94, 0.15), 0 4px 12px rgba(0,0,0,0.15);
    }

    .opacity-control {
        padding: 2px 0;
    }
    .opacity-control input[type="range"] {
        width: 100%;
        height: 6px;
        accent-color: #6b7f5e;
        cursor: pointer;
    }
</style>
