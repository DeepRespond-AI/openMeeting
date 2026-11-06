/**
 * App updates from our own server (server/API.md §1.8, §3): the Rust side asks the server
 * through the Tauri updater plugin, verifies the signed package, installs it and restarts.
 */

import { invoke } from '@tauri-apps/api/core';
import { listen } from '@tauri-apps/api/event';

/** First check after start-up, then every few hours while the app runs. */
export const UPDATE_CHECK_INITIAL_DELAY_MS = 5_000;
export const UPDATE_CHECK_INTERVAL_MS = 4 * 60 * 60 * 1000;
/** An optional update is offered again after this long when the user chose "Later". */
export const UPDATE_PROMPT_COOLDOWN_MS = 24 * 60 * 60 * 1000;

const PROMPTED_KEY = 'openmeeting.update.prompted';

/** Result of `update_check`. */
export interface UpdateInfo {
  available: boolean;
  currentVersion: string;
  version: string | null;
  notes: string | null;
  pubDate: string | null;
  /** Must be installed before the app can be used. */
  force: boolean;
  minVersion: string | null;
}

export interface UpdateProgress {
  downloaded: number;
  total: number | null;
  /** 0..100, null while the size is unknown */
  percentage: number | null;
}

export function checkForUpdates(): Promise<UpdateInfo> {
  return invoke<UpdateInfo>('update_check');
}

/** Why installing has to wait right now (recording / background sync), or null. */
export function installBlocker(): Promise<string | null> {
  return invoke<string | null>('update_install_blocker');
}

/** Downloads and installs the update found by the last check; the app restarts when done. */
export async function installUpdate(onProgress?: (progress: UpdateProgress) => void): Promise<void> {
  const unlisten = await listen<{ downloaded: number; total: number | null }>('update-download-progress', (event) => {
    const { downloaded, total } = event.payload;
    onProgress?.({
      downloaded,
      total,
      percentage: total ? Math.min(100, Math.round((downloaded / total) * 100)) : null,
    });
  });
  try {
    await invoke('update_install');
  } finally {
    unlisten();
  }
}

/** Whether to show the optional-update dialog for `version` (not shown within the cooldown). */
export function shouldPrompt(version: string, now = Date.now()): boolean {
  try {
    const raw = localStorage.getItem(PROMPTED_KEY);
    if (!raw) return true;
    const last = JSON.parse(raw) as { version?: string; at?: number };
    return last.version !== version || typeof last.at !== 'number' || now - last.at >= UPDATE_PROMPT_COOLDOWN_MS;
  } catch {
    return true;
  }
}

export function markPrompted(version: string, now = Date.now()): void {
  try {
    localStorage.setItem(PROMPTED_KEY, JSON.stringify({ version, at: now }));
  } catch {
    // Storage unavailable: the dialog may show again next time.
  }
}
