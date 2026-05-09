<script>
  let {
    datasets = [],
    visibleIds = [],
    yearRange = [1800, 2024],
    onSelect = (id) => {},
    onZoom = (dataset) => {},
  } = $props();

  function isInRange(ds) {
    return ds.year >= yearRange[0] && ds.year <= yearRange[1];
  }

  let sorted = $derived(
    [...datasets].map(ds => ({
      ...ds,
      visible: visibleIds.includes(ds.id),
      inRange: isInRange(ds),
    })).sort((a, b) => {
      if (a.visible && !b.visible) return -1;
      if (!a.visible && b.visible) return 1;
      if (a.inRange && !b.inRange) return -1;
      if (!a.inRange && b.inRange) return 1;
      return a.name.localeCompare(b.name);
    })
  );
</script>

<div class="dataset-list">
  <div class="list-header">Datasets ({datasets.length})</div>
  {#each sorted as ds}
    <div
      class="dataset-item"
      class:visible={ds.visible}
      class:out-of-range={!ds.inRange}
      onclick={() => onSelect(ds.id)}
      role="button"
      tabindex="0"
      onkeydown={(e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); onSelect(ds.id); }}}
    >
      <div class="item-main">
        <span class="dot" class:visible={ds.visible} class:in-range={ds.inRange && !ds.visible}></span>
        <span class="name" class:visible={ds.visible} class:out-of-range={!ds.inRange}>{ds.name}</span>
        {#if ds.visible}
          <button class="zoom-btn" onclick={(e) => { e.stopPropagation(); onZoom(ds); }} aria-label="Zoom to {ds.name}">⤷</button>
        {/if}
      </div>
      <div class="item-meta">
        <span class="year" class:out-of-range={!ds.inRange}>{ds.year}</span>
        {#if ds.region}
          <span class="region">· {ds.region}</span>
        {/if}
      </div>
    </div>
  {/each}
</div>

<style>
  .dataset-list {
    display: flex;
    flex-direction: column;
    gap: 2px;
    max-height: 300px;
    overflow-y: auto;
    scrollbar-width: thin;
  }
  .list-header {
    font-size: 0.75rem;
    color: #9a958a;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    padding: 0.25rem 0.5rem;
  }
  .dataset-item {
    display: flex;
    flex-direction: column;
    gap: 2px;
    padding: 0.5rem 0.75rem;
    border: none;
    background: none;
    border-radius: 4px;
    cursor: pointer;
    text-align: left;
    transition: background 0.05s;
  }
  .dataset-item:hover {
    background: #f5f0e6;
  }
  .item-main {
    display: flex;
    align-items: center;
    gap: 0.5rem;
  }
  .dot {
    width: 7px;
    height: 7px;
    border-radius: 50%;
    background: #c9c4b8;
    flex-shrink: 0;
  }
  .dot.visible {
    background: #6b7f5e;
  }
  .dot.in-range {
    background: #b0ab9e;
  }
  .name {
    font-size: 0.85rem;
    color: #b0ab9e;
  }
  .name.visible {
    color: #3d3b36;
    font-weight: 600;
  }
  .name.out-of-range {
    color: #c9c4b8;
    text-decoration: line-through;
  }
  .zoom-btn {
    margin-left: auto;
    border: none;
    background: none;
    cursor: pointer;
    font-size: 0.9rem;
    padding: 0 0.25rem;
    border-radius: 4px;
    transition: background 0.05s;
  }
  .zoom-btn:hover {
    background: #e8e4da;
  }
  .item-meta {
    display: flex;
    gap: 0.4rem;
    padding-left: 1.15rem;
    font-size: 0.75rem;
    color: #9a958a;
  }
  .year.out-of-range {
    color: #c9c4b8;
  }
  .region {
    color: #b0ab9e;
  }
</style>
