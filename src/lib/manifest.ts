// Load the archive manifest at runtime from the public folder
const manifestUrl = '/archive-manifest.json';

export interface DatasetLocation {
  path: string;
  error?: string;
}

export interface Dataset {
  id: string;
  description: string;
  collection_year_start: number;
  publication_year: number;
  notes: string;
  total_size_bytes: number;
  total_size_human: string;
  format_counts: Record<string, number>;
  total_files: number;
  locations: Record<string, { counts?: Record<string, number>; size_bytes?: number; tree?: unknown; error?: string }>;
}

export interface ArchiveManifest {
  generated_at: string;
  archive_root: string;
  datasets: Dataset[];
  total_size_bytes: number;
  total_size_human: string;
}

let _manifest: ArchiveManifest | null = null;

export async function loadManifest(): Promise<ArchiveManifest> {
  if (_manifest) return _manifest;
  const res = await fetch(manifestUrl);
  if (!res.ok) throw new Error(`Failed to load manifest: ${res.status}`);
  _manifest = await res.json();
  return _manifest;
}

export function formatBytes(bytes: number): string {
  for (const unit of ['B', 'KB', 'MB', 'GB', 'TB']) {
    if (bytes < 1024) return `${bytes.toFixed(1)}${unit}`;
    bytes /= 1024;
  }
  return `${bytes.toFixed(1)}PB`;
}