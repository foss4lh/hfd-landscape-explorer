<script>
  let {
    label = '',
    options = [],
    value = $bindable('all'),
    placeholder = 'Search...',
    yearRange = [1800, 2024],
  } = $props();

  let open = $state(false);
  let inputValue = $state('');
  let selectedIndex = $state(-1);
  let inputEl = $state();
  let dropdownEl = $state();
  const inputId = `combobox-${Math.random().toString(36).slice(2)}`;

  // Init input text from current value
  $effect(() => {
    if (!open) {
      const opt = options.find(o => o.value === value);
      inputValue = opt ? opt.label : '';
    }
  });

  function matchesSearch(text, query) {
    if (!query) return true;
    return text.toLowerCase().includes(query.toLowerCase());
  }

  function inYearRange(year, range) {
    if (year === null || year === undefined) return true;
    return year >= range[0] && year <= range[1];
  }

  function boldMatch(text, query) {
    if (!query) return text;
    const idx = text.toLowerCase().indexOf(query.toLowerCase());
    if (idx === -1) return text;
    const end = idx + query.length;
    return `${text.slice(0, idx)}<strong>${text.slice(idx, end)}</strong>${text.slice(end)}`;
  }

  // Sort: matches first (bold), in-range first, then alpha
  let sortedOptions = $derived(
    [...options].map(o => ({
      ...o,
      match: matchesSearch(o.label, inputValue),
      inRange: inYearRange(o.year, yearRange),
    })).sort((a, b) => {
      if (a.match && !b.match) return -1;
      if (!a.match && b.match) return 1;
      if (a.inRange && !b.inRange) return -1;
      if (!a.inRange && b.inRange) return 1;
      return a.label.localeCompare(b.label);
    })
  );

  function selectOption(opt) {
    value = opt.value;
    inputValue = opt.label;
    open = false;
    selectedIndex = -1;
  }

  function onInput() {
    open = true;
    selectedIndex = -1;
  }

  function onKeyDown(e) {
    if (!open) return;
    const items = sortedOptions;
    if (e.key === 'ArrowDown') {
      e.preventDefault();
      selectedIndex = Math.min(selectedIndex + 1, items.length - 1);
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      selectedIndex = Math.max(selectedIndex - 1, 0);
    } else if (e.key === 'Enter' && selectedIndex >= 0) {
      e.preventDefault();
      selectOption(items[selectedIndex]);
    } else if (e.key === 'Escape') {
      open = false;
      selectedIndex = -1;
      const opt = options.find(o => o.value === value);
      inputValue = opt ? opt.label : '';
    }
  }

  function onClickOutside(e) {
    if (!dropdownEl?.contains(e.target) && !inputEl?.contains(e.target)) {
      open = false;
      const opt = options.find(o => o.value === value);
      inputValue = opt ? opt.label : '';
    }
  }
</script>

<svelte:window onclick={onClickOutside} />

<div class="combobox">
  {#if label}
    <label class="combobox-label" for={inputId}>{label}</label>
  {/if}
  <input
    id={inputId}
    bind:this={inputEl}
    type="text"
    placeholder={placeholder}
    bind:value={inputValue}
    oninput={onInput}
    onkeydown={onKeyDown}
    onclick={() => open = true}
    autocomplete="off"
  />

  {#if open}
    <div class="dropdown" bind:this={dropdownEl}>
      {#each sortedOptions as opt, i}
        <button
          class="dropdown-item"
          class:selected={i === selectedIndex}
          class:match={opt.match}
          class:out-of-range={!opt.inRange}
          onclick={() => selectOption(opt)}
          onmouseenter={() => selectedIndex = i}
        >
          <span class="item-label">{@html boldMatch(opt.label, inputValue)}</span>
          {#if opt.year !== null && opt.year !== undefined}
            <span class="item-year" class:out-of-range={!opt.inRange}>{opt.year}</span>
          {/if}
        </button>
      {/each}
    </div>
  {/if}
</div>

<style>
  .combobox {
    position: relative;
    display: flex;
    flex-direction: column;
    gap: 4px;
  }
  .combobox-label {
    font-size: 0.85rem;
    color: #6b665c;
    font-weight: 500;
  }
  input {
    padding: 0.4rem 0.5rem;
    border: 1px solid #d5d0c5;
    border-radius: 6px;
    font-size: 0.9rem;
    background: #fff;
    color: #3d3b36;
    width: 100%;
    box-sizing: border-box;
    outline: none;
  }
  input:focus {
    border-color: #6b7f5e;
    box-shadow: 0 0 0 2px rgba(107, 127, 94, 0.15);
  }
  .dropdown {
    position: absolute;
    top: calc(100% + 4px);
    left: 0;
    right: 0;
    background: #fff;
    border: 1px solid #d5d0c5;
    border-radius: 6px;
    box-shadow: 0 4px 12px rgba(0,0,0,0.15);
    z-index: 200;
    max-height: 240px;
    overflow-y: auto;
  }
  .dropdown-item {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 0.5rem 0.75rem;
    border: none;
    background: none;
    cursor: pointer;
    text-align: left;
    font-size: 0.85rem;
    color: #3d3b36;
    width: 100%;
    transition: background 0.05s;
  }
  .dropdown-item:hover,
  .dropdown-item.selected {
    background: #f0ebe0;
  }
  .dropdown-item.match {
    font-weight: 600;
  }
  .dropdown-item:not(.match),
  .dropdown-item.out-of-range {
    color: #b0ab9e;
  }
  .dropdown-item.out-of-range {
    opacity: 0.6;
  }
  .item-year {
    font-size: 0.75rem;
    color: #9a958a;
    flex-shrink: 0;
    margin-left: 0.5rem;
  }
  .item-year.out-of-range {
    color: #c9c4b8;
  }
</style>
