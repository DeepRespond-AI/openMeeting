import { afterAll, describe, expect, mock, test } from 'bun:test';
import { act, create } from 'react-test-renderer';

const originalService = { ...await import('../../src/services/updateService') };
const originalToast = { ...await import('sonner') };
const originalRecording = { ...await import('../../src/contexts/RecordingStateContext') };
afterAll(() => {
  mock.module('../../src/services/updateService', () => originalService);
  mock.module('sonner', () => originalToast);
  mock.module('../../src/contexts/RecordingStateContext', () => originalRecording);
});

type Info = import('../../src/services/updateService').UpdateInfo;
const info = (over: Partial<Info>): Info => ({
  available: true,
  currentVersion: '0.4.1',
  version: '0.4.2',
  notes: '修复问题',
  pubDate: null,
  force: false,
  minVersion: null,
  ...over,
});

let next: Info = info({ available: false, version: null });
let prompted = true;
const toasts: string[] = [];
mock.module('../../src/services/updateService', () => ({
  ...originalService,
  checkForUpdates: async () => next,
  installUpdate: async () => {
    throw new Error('正在录音，请结束录音后再更新');
  },
  shouldPrompt: () => prompted,
  markPrompted: () => {},
}));
mock.module('sonner', () => ({
  toast: { success: (m: string) => toasts.push(`ok:${m}`), error: (m: string) => toasts.push(`err:${m}`) },
}));
let recording = false;
mock.module('../../src/contexts/RecordingStateContext', () => ({ useRecordingState: () => ({ isRecording: recording }) }));
// Record what the provider renders instead of the real dialog / gate.
const rendered: { dialog?: { open: boolean; error: string | null; onInstall: () => void }; gate?: boolean } = {};
mock.module('../../src/components/updates/UpdateDialog', () => ({
  UpdateDialog: (p: { open: boolean; error: string | null; onInstall: () => void }) => {
    rendered.dialog = p;
    return null;
  },
}));
mock.module('../../src/components/updates/ForceUpdateGate', () => ({
  ForceUpdateGate: () => {
    rendered.gate = true;
    return null;
  },
}));

function resetRendered() {
  delete rendered.dialog;
  delete rendered.gate;
}

const { UpdateCheckProvider, useUpdateCheckContext } = await import('../../src/components/UpdateCheckProvider');

async function mount() {
  let ctx!: ReturnType<typeof useUpdateCheckContext>;
  function Probe() {
    ctx = useUpdateCheckContext();
    return null;
  }
  let root!: ReturnType<typeof create>;
  await act(async () => {
    root = create(
      <UpdateCheckProvider>
        <Probe />
      </UpdateCheckProvider>,
    );
  });
  const check = async () => {
    await act(async () => {
      await ctx.checkForUpdates();
    });
  };
  const rerender = async () => {
    await act(async () => {
      root.update(
        <UpdateCheckProvider>
          <Probe />
        </UpdateCheckProvider>,
      );
    });
  };
  return { check, rerender, unmount: () => act(() => root.unmount()) };
}

describe('UpdateCheckProvider', () => {
  test('manual check: up to date → toast', async () => {
    toasts.length = 0;
    next = info({ available: false, version: null });
    const m = await mount();
    await m.check();
    expect(toasts).toEqual(['ok:当前已是最新版本']);
    m.unmount();
  });

  test('optional update opens the dialog; install errors stay in the dialog', async () => {
    resetRendered();
    next = info({});
    const m = await mount();
    await m.check();
    expect(rendered.dialog?.open).toBe(true);
    expect(rendered.gate).toBeUndefined();
    await act(async () => {
      rendered.dialog!.onInstall();
    });
    expect(rendered.dialog?.error).toBe('正在录音，请结束录音后再更新');
    m.unmount();
  });

  test('forced update shows the gate, but not while recording', async () => {
    resetRendered();
    next = info({ force: true });
    recording = true;
    const m = await mount();
    await m.check();
    expect(rendered.gate).toBeUndefined();
    expect(rendered.dialog).toBeUndefined();
    recording = false;
    await m.rerender();
    expect(rendered.gate).toBe(true);
    m.unmount();
  });
});
