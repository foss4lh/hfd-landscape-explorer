<script lang="ts">
  import { onMount } from 'svelte';
  import { loadManifest, formatBytes, type ArchiveManifest, type Dataset } from './manifest';

  let manifest: ArchiveManifest | null = $state(null);
  let loading = $state(true);
  let error: string | null = $state(null);
  let activeSection: string | null = $state(null);

  const FORMAT_LABELS: Record<string, string> = {
    'jpeg': 'JPEG', 'tiff': 'TIFF', 'crw': 'Canon RAW', 'arw': 'Sony RAW',
    'ecw': 'ECW', 'pdf': 'PDF', 'doc': 'Word', 'docx': 'Word', 'xls': 'Excel',
    'xlsx': 'Excel', 'csv': 'CSV', 'xml': 'XML', 'shapefile': 'Shapefile',
    'sqlite': 'SQLite', 'mdb': 'Access', 'qml': 'QGIS Style', 'qgz': 'QGIS Project',
    'ascii-grid': 'ASCII Grid', 'hgt': 'HGT', 'zip': 'ZIP', 'psd': 'Photoshop',
    'html': 'HTML', 'gif': 'GIF', 'png': 'PNG', 'other': 'Other',
  };

  function humanName(id: string): string {
    return id.replace('hfd-', '').replace(/-/g, ' ').replace(/\b\w/g, c => c.toUpperCase());
  }

  function formatLabel(f: string): string {
    return FORMAT_LABELS[f] || f.toUpperCase();
  }

  function toggleSection(id: string) {
    activeSection = activeSection === id ? null : id;
  }

  onMount(async () => {
    try {
      manifest = await loadManifest();
    } catch (e) {
      error = e instanceof Error ? e.message : 'Failed to load manifest';
    } finally {
      loading = false;
    }
  });
</script>

<div class="doc-page">
  <header class="doc-header">
    <h1>Raw Data Documentation</h1>
    <p class="subtitle">David Lovelace Archive — Herefordshire landscape history collection</p>
    {#if manifest}
      <p class="meta">
        Archive root: <code>{manifest.archive_root}</code>
        &nbsp;·&nbsp;
        Total size: <strong>{manifest.total_size_human}</strong>
        &nbsp;·&nbsp;
        Generated: {new Date(manifest.generated_at).toLocaleDateString('en-GB', { year: 'numeric', month: 'long', day: 'numeric' })}
      </p>
    {/if}
  </header>

  {#if loading}
    <div class="loading">Loading archive manifest…</div>
  {:else if error}
    <div class="error">Failed to load manifest: {error}</div>
  {:else if manifest}
    <nav class="dataset-nav">
      {#each manifest.datasets as ds}
        <a href="#{ds.id}" class="nav-item" class:active={activeSection === ds.id}>
          {humanName(ds.id)}
          <span class="nav-size">{ds.total_size_human}</span>
        </a>
      {/each}
    </nav>

    <div class="sections">
      {#each manifest.datasets as ds}
        <section class="dataset-section" id={ds.id}>
          <button class="section-header" onclick={() => toggleSection(ds.id)}>
            <div class="section-title">
              <h2>{humanName(ds.id)}</h2>
              <span class="section-meta">
                {ds.collection_year_start}–{ds.publication_year}
                &nbsp;·&nbsp;
                {ds.total_size_human}
                &nbsp;·&nbsp;
                {ds.total_files.toLocaleString()} files
              </span>
            </div>
            <span class="expand-icon">{activeSection === ds.id ? '−' : '+'}</span>
          </button>

          {#if activeSection === ds.id}
            <div class="section-body">
              <p class="description">{ds.description}</p>

              <div class="grid">
                <div class="card formats">
                  <h3>File Formats</h3>
                  <div class="format-list">
                    {#each Object.entries(ds.format_counts).sort((a, b) => b[1] - a[1]) as [fmt, count]}
                      <div class="format-item">
                        <span class="format-name">{formatLabel(fmt)}</span>
                        <span class="format-count">{Number(count).toLocaleString()}</span>
                      </div>
                    {/each}
                  </div>
                </div>

                <div class="card locations">
                  <h3>Locations on Archive</h3>
                  <ul class="location-list">
                    {#each Object.entries(ds.locations) as [path, info]}
                      <li class="location-item">
                        <code class="path">{path}</code>
                        {#if info.counts}
                          <span class="loc-meta">
                            {Object.values(info.counts).reduce((a, b) => a + b, 0)} files
                            {#if info.size_bytes}
                              &nbsp;·&nbsp; {formatBytes(info.size_bytes)}
                            {/if}
                          </span>
                        {:else if info.error}
                          <span class="loc-error">⚠ {info.error}</span>
                        {/if}
                      </li>
                    {/each}
                  </ul>
                </div>
              </div>

              {#if ds.notes}
                <div class="card notes">
                  <h3>Notes</h3>
                  <p>{ds.notes}</p>
                </div>
              {/if}
            </div>
          {/if}
        </section>
      {/each}
    </div>
  {/if}
</div>

<style>
  :global(body) { margin: 0; background: #fefcf6; font-family: system-ui, -apple-system, sans-serif; }

  .doc-page {
    max-width: 900px;
    margin: 0 auto;
    padding: 2rem 1.5rem;
  }

  .doc-header { margin-bottom: 2rem; border-bottom: 2px solid #e8e4da; padding-bottom: 1rem; }
  .doc-header h1 { margin: 0 0 0.25rem; font-size: 1.75rem; color: #3d3b36; letter-spacing: -0.02em; }
  .subtitle { margin: 0 0 0.5rem; color: #6b665c; font-size: 0.95rem; }
  .meta { margin: 0; font-size: 0.8rem; color: #9a958a; }
  .meta code { background: #f0eee8; padding: 1px 5px; border-radius: 3px; font-size: 0.78rem; }

  .dataset-nav {
    display: flex;
    flex-wrap: wrap;
    gap: 0.5rem;
    margin-bottom: 1.5rem;
  }
  .nav-item {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.35rem 0.75rem;
    background: #f0eee8;
    border: 1px solid #d5d0c5;
    border-radius: 20px;
    text-decoration: none;
    color: #3d3b36;
    font-size: 0.8rem;
    font-weight: 500;
    transition: all 0.1s;
  }
  .nav-item:hover { background: #e8e4da; border-color: #b0ab9e; }
  .nav-item.active { background: #6b7f5e; color: white; border-color: #5a6d4e; }
  .nav-size { font-size: 0.72rem; opacity: 0.7; }

  .dataset-section { margin-bottom: 0.5rem; border: 1px solid #e8e4da; border-radius: 8px; overflow: hidden; }
  .section-header {
    width: 100%;
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 0.85rem 1rem;
    background: #faf7f2;
    border: none;
    cursor: pointer;
    text-align: left;
    transition: background 0.1s;
  }
  .section-header:hover { background: #f0eee8; }
  .section-title h2 { margin: 0 0 0.15rem; font-size: 1rem; color: #3d3b36; }
  .section-meta { font-size: 0.78rem; color: #9a958a; }
  .expand-icon { font-size: 1.2rem; color: #6b665c; font-weight: 300; }

  .section-body { padding: 1rem; border-top: 1px solid #e8e4da; }
  .description { margin: 0 0 1rem; font-size: 0.9rem; color: #4a4740; line-height: 1.5; }

  .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; }
  @media (max-width: 600px) { .grid { grid-template-columns: 1fr; } }

  .card { background: #fff; border: 1px solid #e8e4da; border-radius: 6px; padding: 0.85rem; }
  .card h3 { margin: 0 0 0.65rem; font-size: 0.78rem; text-transform: uppercase; letter-spacing: 0.05em; color: #9a958a; font-weight: 600; }

  .format-list { display: flex; flex-direction: column; gap: 4px; }
  .format-item { display: flex; justify-content: space-between; align-items: center; font-size: 0.82rem; }
  .format-name { color: #3d3b36; }
  .format-count { background: #f0eee8; color: #6b665c; padding: 1px 7px; border-radius: 10px; font-size: 0.75rem; }

  .location-list { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 6px; }
  .location-item { font-size: 0.8rem; }
  .path { display: block; color: #3d3b36; font-size: 0.78rem; word-break: break-all; }
  .loc-meta { font-size: 0.72rem; color: #9a958a; }
  .loc-error { font-size: 0.72rem; color: #b05050; }

  .notes { grid-column: 1 / -1; }
  .notes p { margin: 0; font-size: 0.85rem; color: #4a4740; line-height: 1.5; }

  .loading, .error { padding: 2rem; text-align: center; color: #6b665c; }
  .error { color: #b05050; }
</style>