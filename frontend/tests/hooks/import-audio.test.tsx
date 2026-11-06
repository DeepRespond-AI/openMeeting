import { afterAll, describe, expect, mock, test } from 'bun:test';
import { act, create } from 'react-test-renderer';

const originalCore = { ...await import('@tauri-apps/api/core') };
const originalEvent = { ...await import('@tauri-apps/api/event') };
const originalAnalytics = { ...await import('../../src/lib/analytics') };
const originalPreferences = { ...await import('../../src/lib/summary-language-preferences') };
const originalToast = { ...await import('sonner') };
afterAll(() => {
  mock.module('@tauri-apps/api/core', () => originalCore);
  mock.module('@tauri-apps/api/event', () => originalEvent);
  mock.module('../../src/lib/analytics', () => originalAnalytics);
  mock.module('../../src/lib/summary-language-preferences', () => originalPreferences);
  mock.module('sonner', () => originalToast);
});

// A fake Tauri event bus: `emit` delivers a payload to the hook's listeners.
const handlers = new Map<string, (event: { payload: unknown }) => void>();
const emit = async (event: string, payload: unknown) => {
  await act(async () => {
    handlers.get(event)?.({ payload });
  });
};
mock.module('@tauri-apps/api/event', () => ({
  ...originalEvent,
  listen: async (event: string, handler: (event: { payload: unknown }) => void) => {
    handlers.set(event, handler);
    return () => handlers.delete(event);
  },
}));
const invoke = mock(async (_command: string, _args?: Record<string, unknown>): Promise<unknown> => ({ message: 'Import started' }));
mock.module('@tauri-apps/api/core', () => ({ ...originalCore, invoke }));
mock.module('../../src/lib/analytics', () => ({ default: { track: async () => {}, trackError: async () => {} } }));
mock.module('../../src/lib/summary-language-preferences', () => ({ applyPinnedSummaryLanguageToMeeting: async () => {} }));
mock.module('sonner', () => ({ toast: { info() {}, error() {}, success() {}, warning() {} } }));

const { useImportAudio } = await import('../../src/hooks/useImportAudio');
type Hook = ReturnType<typeof useImportAudio>;

describe('useImportAudio', () => {
  test('the dialog only waits for the upload; transcription is reported in the background', async () => {
    const calls: string[] = [];
    let hook!: Hook;
    function Probe() {
      hook = useImportAudio({
        onUploaded: (r) => calls.push(`uploaded:${r.meeting_id}`),
        onError: (e) => calls.push(`error:${e}`),
        onTranscribed: (r) => calls.push(`transcribed:${r.meeting_id}:${r.segments_count}`),
        onTranscribeFailed: (r) => calls.push(`failed:${r.meeting_id}:${r.error}`),
      });
      return null;
    }
    await act(async () => { create(<Probe />); });
    await act(async () => {});

    await act(async () => { await hook.startImport('/tmp/a.wav', 'A'); });
    expect(invoke).toHaveBeenCalledWith('start_import_audio_command', expect.objectContaining({ sourcePath: '/tmp/a.wav', title: 'A' }));
    expect(hook.status).toBe('uploading');
    expect(hook.isProcessing).toBe(true);

    await emit('import-progress', { stage: 'uploading', progress_percentage: 40, message: '' });
    expect(hook.progress?.progress_percentage).toBe(40);

    await emit('import-uploaded', { meeting_id: 'meeting-1', title: 'A' });
    expect(hook.status).toBe('uploaded');
    expect(hook.isProcessing).toBe(false);

    // The dialog is reset (closed and reopened) while the server is still transcribing.
    await act(async () => { hook.reset(); });
    await emit('import-complete', { meeting_id: 'meeting-1', title: 'A', segments_count: 3, duration_seconds: 9 });
    await emit('import-failed', { meeting_id: 'meeting-2', title: 'B', error: 'boom' });
    expect(hook.status).toBe('idle');

    await emit('import-error', { error: 'network down' });
    expect(hook.status).toBe('error');

    expect(calls).toEqual(['uploaded:meeting-1', 'transcribed:meeting-1:3', 'failed:meeting-2:boom', 'error:network down']);
  });
});
