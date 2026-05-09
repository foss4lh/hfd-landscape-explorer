<script>
  let {
    min,
    max,
    step = 1,
    values = $bindable([min, max])
  } = $props();

  let trackEl = $state();
  let dragging = $state(null);

  const pipYears = [1800, 1850, 1900, 1950, 2000];

  function posToVal(clientX) {
    const rect = trackEl.getBoundingClientRect();
    const pct = Math.max(0, Math.min(1, (clientX - rect.left) / rect.width));
    return Math.round((min + pct * (max - min)) / step) * step;
  }

  function onPointerDown(e, index) {
    e.preventDefault();
    dragging = index;
    const move = (ev) => {
      const v = posToVal(ev.clientX);
      if (index === 0) {
        values = [Math.min(Math.max(v, min), values[1] - step), values[1]];
      } else {
        values = [values[0], Math.max(Math.min(v, max), values[0] + step)];
      }
    };
    const up = () => {
      dragging = null;
      window.removeEventListener('pointermove', move);
      window.removeEventListener('pointerup', up);
    };
    window.addEventListener('pointermove', move);
    window.addEventListener('pointerup', up);
  }

  function pct(v) {
    return ((v - min) / (max - min)) * 100;
  }
</script>

<div class="slider-outer">
  <div class="track" bind:this={trackEl}>
    <div
      class="fill"
      style="left: {pct(values[0])}%; width: {pct(values[1]) - pct(values[0])}%;"
    ></div>
    <button
      class="thumb"
      class:active={dragging === 0}
      style="left: {pct(values[0])}%;"
      onpointerdown={(e) => onPointerDown(e, 0)}
      aria-label="Minimum year {values[0]}"
    ></button>
    <button
      class="thumb"
      class:active={dragging === 1}
      style="left: {pct(values[1])}%;"
      onpointerdown={(e) => onPointerDown(e, 1)}
      aria-label="Maximum year {values[1]}"
    ></button>
  </div>
  <div class="pips">
    {#each pipYears as year}
      <div class="pip" style="left: {pct(year)}%">
        <div class="tick"></div>
        <span class="pip-label">{year}</span>
      </div>
    {/each}
  </div>
</div>

<style>
  .slider-outer {
    padding: 6px 10px 2px;
    user-select: none;
  }

  .track {
    position: relative;
    height: 6px;
    background: #c9c4b8;
    border-radius: 3px;
  }

  .fill {
    position: absolute;
    top: 0;
    height: 100%;
    background: #6b7f5e;
    border-radius: 3px;
  }

  .thumb {
    position: absolute;
    top: 50%;
    width: 14px;
    height: 14px;
    background: #4a5c40;
    border-radius: 50%;
    border: 2px solid #fff;
    transform: translate(-50%, -50%);
    cursor: grab;
    padding: 0;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.25);
    transition: transform 0.05s;
  }

  .thumb:active,
  .thumb.active {
    cursor: grabbing;
    transform: translate(-50%, -50%) scale(1.15);
  }

  .pips {
    position: relative;
    height: 18px;
    margin-top: 6px;
  }

  .pip {
    position: absolute;
    transform: translateX(-50%);
    display: flex;
    flex-direction: column;
    align-items: center;
    pointer-events: none;
  }

  .tick {
    width: 1px;
    height: 5px;
    background: #b0ab9e;
  }

  .pip-label {
    font-size: 0.65rem;
    color: #9a958a;
    margin-top: 3px;
    white-space: nowrap;
  }
</style>
