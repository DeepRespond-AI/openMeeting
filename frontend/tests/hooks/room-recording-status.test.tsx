import { afterAll, afterEach, beforeEach, describe, expect, mock, test } from 'bun:test';
import { act, create, type ReactTestRenderer } from 'react-test-renderer';
import type { RecordingSnapshot } from '../../src/lib/meeting-processing';
import type { RecordingStatus } from '../../src/services/live-meeting/recording';

const original = { ...await import('../../src/services/live-meeting/recording') };
const reads: { meetingId: string; resolve: (value: RecordingStatus) => void }[] = [];
mock.module('../../src/services/live-meeting/recording', () => ({
  ...original,
  getRecordingStatus: (meetingId: string) => new Promise<RecordingStatus>(resolve => reads.push({ meetingId, resolve })),
}));
const { default: RoomRecordingStatus } = await import('../../src/components/meeting-details/RoomRecordingStatus');
const realTimeout = globalThis.setTimeout, realClear = globalThis.clearTimeout;
let renderer: ReactTestRenderer | undefined;
const timers = new Map<number, () => void>(); let timerId = 0;
beforeEach(() => {
  reads.length = 0; timers.clear();
  globalThis.setTimeout = ((fn: () => void) => { const id = ++timerId; timers.set(id, fn); return id; }) as typeof setTimeout;
  globalThis.clearTimeout = ((id: number) => timers.delete(id)) as typeof clearTimeout;
});
afterEach(async () => {
  if (renderer) await act(async () => renderer!.unmount()); renderer = undefined;
  globalThis.setTimeout = realTimeout; globalThis.clearTimeout = realClear;
});
afterAll(() => mock.module('../../src/services/live-meeting/recording', () => original));
const result = (status: string): RecordingStatus => ({ status, jobId: 'fixture', error: null, message: null });
describe('recording status poll ownership', () => {
  test('a delayed old meeting cannot complete or overwrite the new meeting', async () => {
    const changes: RecordingSnapshot[] = [], completed = mock(() => {});
    const view = (meetingId: string) => <RoomRecordingStatus meetingId={meetingId} onComplete={completed} onStatusChange={value => changes.push(value)} />;
    await act(async () => { renderer = create(view('meeting-a')); });
    await act(async () => { renderer!.update(view('meeting-b')); });
    expect(reads.map(r => r.meetingId)).toEqual(['meeting-a', 'meeting-b']);
    await act(async () => { reads[1].resolve(result('running')); });
    const before = changes.length;
    await act(async () => { reads[0].resolve(result('completed')); });
    expect(changes).toHaveLength(before);
    expect(changes.at(-1)?.data?.status).toBe('running');
    expect(completed).not.toHaveBeenCalled();
  });
  test('a terminal status refreshes once and unmounted reads stay silent', async () => {
    const changes = mock(() => {}), completed = mock(() => {});
    await act(async () => { renderer = create(<RoomRecordingStatus meetingId="meeting-a" onComplete={completed} onStatusChange={changes} />); });
    await act(async () => { reads[0].resolve(result('completed')); });
    expect(completed).toHaveBeenCalledTimes(1);
    await act(async () => { const [id, fn] = [...timers][0]; timers.delete(id); fn(); });
    await act(async () => { reads[1].resolve(result('completed')); });
    expect(completed).toHaveBeenCalledTimes(1);
    await act(async () => { const [id, fn] = [...timers][0]; timers.delete(id); fn(); });
    await act(async () => { renderer!.unmount(); }); renderer = undefined;
    const before = changes.mock.calls.length;
    await act(async () => { reads[2].resolve(result('failed')); });
    expect(changes.mock.calls).toHaveLength(before);
    expect(completed).toHaveBeenCalledTimes(1);
    expect(timers.size).toBe(0);
  });
});
