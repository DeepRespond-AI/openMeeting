import { afterAll, beforeEach, describe, expect, mock, test } from 'bun:test';

const originalCore = { ...await import('@tauri-apps/api/core') };
const originalEvent = { ...await import('@tauri-apps/api/event') };
afterAll(() => {
  mock.module('@tauri-apps/api/core', () => originalCore);
  mock.module('@tauri-apps/api/event', () => originalEvent);
});

// In-memory localStorage (bun has none).
const store = new Map<string, string>();
(globalThis as { localStorage?: unknown }).localStorage = {
  getItem: (k: string) => store.get(k) ?? null,
  setItem: (k: string, v: string) => void store.set(k, v),
  removeItem: (k: string) => void store.delete(k),
};

let progressHandler: ((event: { payload: { downloaded: number; total: number | null } }) => void) | null = null;
const invoke = mock(async (command: string): Promise<unknown> => {
  if (command === 'update_install') {
    progressHandler?.({ payload: { downloaded: 50, total: 200 } });
    progressHandler?.({ payload: { downloaded: 10, total: null } });
    return null;
  }
  return { available: false };
});
mock.module('@tauri-apps/api/core', () => ({ ...originalCore, invoke }));
mock.module('@tauri-apps/api/event', () => ({
  ...originalEvent,
  listen: async (_event: string, handler: typeof progressHandler) => {
    progressHandler = handler;
    return () => {
      progressHandler = null;
    };
  },
}));

const svc = await import('../../src/services/updateService');

describe('updateService', () => {
  beforeEach(() => store.clear());

  test('an optional update is offered once per version within the cooldown', () => {
    const now = 1_000_000;
    expect(svc.shouldPrompt('0.4.2', now)).toBe(true);
    svc.markPrompted('0.4.2', now);
    expect(svc.shouldPrompt('0.4.2', now + 1000)).toBe(false);
    expect(svc.shouldPrompt('0.4.3', now + 1000)).toBe(true);
    expect(svc.shouldPrompt('0.4.2', now + svc.UPDATE_PROMPT_COOLDOWN_MS)).toBe(true);
  });

  test('broken storage never blocks the prompt', () => {
    store.set('openmeeting.update.prompted', '{not json');
    expect(svc.shouldPrompt('0.4.2')).toBe(true);
  });

  test('install reports download progress and stops listening afterwards', async () => {
    const seen: (number | null)[] = [];
    await svc.installUpdate((p) => seen.push(p.percentage));
    expect(invoke).toHaveBeenCalledWith('update_install');
    expect(seen).toEqual([25, null]);
    expect(progressHandler).toBeNull();
  });
});
