import { afterEach, expect, mock, test } from 'bun:test';
import { AudioLevelMonitor, rmsToLevel } from '../../src/services/live-meeting/media/audioLevels';
import type { AudioLevels } from '../../src/services/live-meeting/media/audioLevels';
import type { MediaTrack } from '../../src/services/live-meeting/media/types';

const windowDescriptor = Object.getOwnPropertyDescriptor(globalThis, 'window');
const streamDescriptor = Object.getOwnPropertyDescriptor(globalThis, 'MediaStream');
let monitors: AudioLevelMonitor[] = [];
let contexts: FakeContext[] = [];
let allowResume = true;
type Track = { enabled: boolean; muted: boolean; readyState: string; amplitude: number; stop: ReturnType<typeof mock> };
class FakeStream { constructor(readonly tracks: Track[]) {} }
class FakeAnalyser {
  fftSize = 1024;
  track!: Track;
  disconnected = false;
  getFloatTimeDomainData(samples: Float32Array) { samples.fill(this.track.amplitude); }
  disconnect() { this.disconnected = true; }
}
class FakeContext {
  state = allowResume ? 'running' : 'suspended';
  sources: { disconnected: boolean; disconnect: () => void }[] = [];
  constructor() { contexts.push(this); }
  createAnalyser() { return new FakeAnalyser(); }
  createMediaStreamSource(stream: FakeStream) {
    const source = {
      disconnected: false,
      connect(analyser: FakeAnalyser) { analyser.track = stream.tracks[0]; },
      disconnect() { this.disconnected = true; },
    };
    this.sources.push(source);
    return source;
  }
  async resume() { if (allowResume) this.state = 'running'; }
  async close() { this.state = 'closed'; }
}
function setup() {
  contexts = []; allowResume = true;
  const events = Object.assign(new EventTarget(), { AudioContext: FakeContext });
  Object.defineProperty(globalThis, 'window', { value: events, configurable: true, writable: true });
  Object.defineProperty(globalThis, 'MediaStream', { value: FakeStream, configurable: true, writable: true });
  return events;
}
function track(key: string, amplitude: number, extra: Partial<MediaTrack> = {}) {
  const native: Track = { enabled: true, muted: false, readyState: 'live', amplitude, stop: mock(() => {}) };
  const item: MediaTrack = { key, username: key, kind: 'audio', local: false, track: native as unknown as MediaStreamTrack, ...extra };
  return { item, native };
}
const tick = () => new Promise(resolve => setTimeout(resolve, 130));
afterEach(() => {
  for (const monitor of monitors) monitor.stop();
  monitors = [];
  if (windowDescriptor) Object.defineProperty(globalThis, 'window', windowDescriptor); else Reflect.deleteProperty(globalThis, 'window');
  if (streamDescriptor) Object.defineProperty(globalThis, 'MediaStream', streamDescriptor); else Reflect.deleteProperty(globalThis, 'MediaStream');
});
function monitor(tracks: () => MediaTrack[]) {
  const analyser = new AudioLevelMonitor(); monitors.push(analyser);
  let latest: AudioLevels = {};
  const events: AudioLevels[] = [];
  analyser.start(tracks, levels => { latest = levels; events.push(levels); });
  return { analyser, events, levels: () => latest };
}

test('relative level rejects invalid samples and increases with actual RMS amplitude', () => {
  for (const value of [0, -1, NaN, Infinity, 0.00001]) expect(rmsToLevel(value)).toBe(0);
  expect(rmsToLevel(0.01)).toBeCloseTo(0.2);
  expect(rmsToLevel(0.1)).toBeCloseTo(0.6);
  expect(rmsToLevel(1)).toBe(1);
  expect(rmsToLevel(2)).toBe(1);
});

test('local and remote signals remain separate and screen audio is excluded', () => {
  setup();
  const local = track('local', 0.01, { local: true, username: null });
  const remote = track('remote', 0.1);
  const screen = track('screen', 1, { source: 'screen' });
  const camera = track('camera', 1, { kind: 'video' });
  const m = monitor(() => [local.item, remote.item, screen.item, camera.item]);
  expect(m.levels()).toEqual({ local: 0.2, remote: 0.6 });
  expect(contexts.length).toBe(1);
  expect(contexts[0].sources.length).toBe(2);
  m.analyser.stop();
  expect(contexts[0].state).toBe('closed');
  expect(contexts[0].sources.every(source => source.disconnected)).toBe(true);
  for (const t of [local, remote, screen, camera]) expect(t.native.stop).not.toHaveBeenCalled();
});

test('mute, remote silence and track removal clear meters without restarting capture', async () => {
  setup();
  const a = track('a', 0.1), b = track('b', 0.1);
  let tracks = [a.item, b.item];
  const m = monitor(() => tracks);
  expect(m.levels().a).toBeGreaterThan(0);
  a.native.enabled = false; b.native.muted = true;
  await tick();
  expect(m.levels()).toEqual({ a: 0, b: 0 });
  a.native.enabled = true;
  await tick();
  expect(m.levels().a).toBeGreaterThan(0);
  expect(contexts[0].sources.length).toBe(2);
  tracks = [];
  await tick();
  expect(m.levels()).toEqual({});
  expect(contexts[0].state).toBe('closed');
  expect(a.native.stop).not.toHaveBeenCalled();
});

test('suspended contexts wait for a user gesture and stop removes timers and listeners', async () => {
  const events = setup(); allowResume = false;
  const a = track('a', 0.1);
  const m = monitor(() => [a.item]);
  expect(m.levels().a).toBe(0);
  allowResume = true;
  events.dispatchEvent(new Event('pointerdown'));
  await tick();
  expect(m.levels().a).toBeGreaterThan(0);
  const count = m.events.length;
  m.analyser.stop();
  events.dispatchEvent(new Event('pointerdown'));
  await tick();
  expect(m.events.length).toBe(count);
  expect(contexts[0].state).toBe('closed');
});

test('replaced and ended SDK tracks cannot leave stale volume or analyser nodes', async () => {
  setup();
  const original = track('mic', 0.1), replacement = track('mic', 0.005);
  let current = original.item;
  const m = monitor(() => [current]);
  current = replacement.item;
  await tick();
  expect(contexts[0].sources[0].disconnected).toBe(true);
  expect(m.levels().mic).toBeLessThan(0.1);
  replacement.native.readyState = 'ended';
  await tick();
  expect(m.levels()).toEqual({});
  expect(contexts[0].state).toBe('closed');
  expect(original.native.stop).not.toHaveBeenCalled();
});
