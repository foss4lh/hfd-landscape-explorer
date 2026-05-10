<script lang="ts">
  import RawDataDocumentation from '@/src/lib/RawDataDocumentation.svelte';
</script>

<div class="docs-shell">
  <nav class="docs-nav">
    <a href="/hfd-landscape-explorer/" class="nav-brand">← Landscape Explorer</a>
    <span class="nav-title">Raw Data Documentation</span>
  </nav>
  <RawDataDocumentation />
</div>

<style>
  :global(body) { margin: 0; background: #fefcf6; }
  .docs-shell { min-height: 100vh; }
  .docs-nav {
    display: flex;
    align-items: center;
    gap: 1rem;
    padding: 0.75rem 1.5rem;
    background: #3d3b36;
    border-bottom: 2px solid #6b7f5e;
  }
  .nav-brand {
    color: #f0eee8;
    text-decoration: none;
    font-size: 0.85rem;
    font-weight: 500;
  }
  .nav-brand:hover { color: #fff; }
  .nav-title {
    color: #9a958a;
    font-size: 0.82rem;
  }
</style>