import React from 'react';
import { afterEach, expect, mock, test } from 'bun:test';
import { act, create } from 'react-test-renderer';
import type { LiveRoom, Participant, RoomEvent } from '../../src/services/live-meeting/types';

const t = (key: string) => key;
const errors: string[] = [];
const successes: string[] = [];
const calls: unknown[][] = [];
let failMember: string | undefined;
let pendingMute: Promise<void> | undefined;
let authoritative: LiveRoom;
let onRoomEvent: (event: RoomEvent) => void;
const microphoneChanges: boolean[] = [];
const snapshot = () => structuredClone(authoritative);
const api = {
  onRoomEvent: (handler: (event: RoomEvent) => void) => { onRoomEvent = handler; return () => {}; },
  joinRoom: async () => ({ room: snapshot(), self: snapshot().participants.find(p => p.isSelf)!, state: 'joined', media: {} }),
  listChat: async () => ({ messages: [], hasMore: false }),
  getRoom: async () => snapshot(),
  leaveRoom: async () => {},
  updateSelf: async (_roomId: string, patch: Partial<Participant>) => {
    calls.push(['updateSelf', patch]);
    const me = authoritative.participants.find(p => p.isSelf)!;
    if (patch.micOn && me.mutedByHost) throw new Error('muted_by_host');
    Object.assign(me, patch);
  },
  muteAll: async () => {
    calls.push(['muteAll']);
    await pendingMute;
    for (const p of authoritative.participants) if (!p.isHost) { p.micOn = false; p.mutedByHost = true; }
  },
  setParticipantMuted: async (_roomId: string, id: string, muted: boolean) => {
    calls.push(['muteMember', id, muted]);
    if (id === failMember) throw new Error('Member request failed');
    const p = authoritative.participants.find(p => p.id === id)!;
    p.mutedByHost = muted;
    if (muted) p.micOn = false;
  },
};
const media = { subscribe: () => () => {}, leave: async () => {}, setMicEnabled: async (on: boolean) => { microphoneChanges.push(on); }, setCamEnabled: async () => {} };
const im = { client: null, status: 'connected', relogin: () => {} };
const searchParams = new URLSearchParams('code=123456');
const router = { push: () => {} };
mock.module('next/navigation', () => ({ useRouter: () => router, useSearchParams: () => searchParams, usePathname: () => '/room' }));
mock.module('../../src/i18n', () => ({ useT: () => t, useI18n: () => ({ locale: 'en' }) }));
mock.module('sonner', () => ({ toast: Object.assign(() => {}, {
  error: (message: string) => errors.push(message), success: (message: string) => successes.push(message),
}) }));
mock.module('../../src/contexts/ServerContext', () => ({ useServer: () => ({ user: null }) }));
mock.module('../../src/contexts/IMContext', () => ({ useIm: () => im }));
mock.module('../../src/components/live-meeting/JoinDialog', () => ({ JOIN_INTENT_KEY: 'join' }));
mock.module('../../src/services/live-meeting/recording', () => ({ RoomRecorder: class {} }));
mock.module('../../src/services/live-meeting', () => ({
  getLiveMeetingApi: () => api, getMediaClient: () => media, getLiveMeetingDataSource: () => 'mock',
  LiveMeetingApiError: class extends Error {},
}));

const { RoomProvider, useRoom } = await import('../../src/components/live-meeting/room/RoomProvider');
const { default: SidePanel } = await import('../../src/components/live-meeting/room/SidePanel');
let root: ReturnType<typeof create> | undefined;
let roomContext!: ReturnType<typeof useRoom>;
function Probe() { roomContext = useRoom(); return <SidePanel />; }
afterEach(() => { act(() => root?.unmount()); root = undefined; });
async function mount(restricted = false, selfId = 'host') {
  calls.length = errors.length = successes.length = 0;
  microphoneChanges.length = 0;
  failMember = undefined;
  pendingMute = undefined;
  const participant = (id: string, isHost: boolean): Participant => ({
    id, name: id, isHost, isSelf: id === selfId, micOn: isHost || !restricted, mutedByHost: !isHost && restricted,
    camOn: false, handRaised: false, screenSharing: false, joinedAt: '2026-10-23T00:00:00Z',
  });
  authoritative = {
    id: 'room-test', code: '123456', title: 'test', hostId: 'host', status: 'active',
    scheduledMeetingId: null, pwdEnabled: false, waitRoom: false, startedAt: null, endedAt: null, meetingId: null,
    participants: [participant('host', true), participant('bob', false), participant('carol', false)], waiting: [],
  };
  await act(async () => { root = create(<RoomProvider><Probe /></RoomProvider>); });
  // The toolbar opens this drawer in the app; exercise its controls only once visible.
  await act(async () => { roomContext.setPanelTab('members'); });
}
function button() { return root!.root.findAllByType('button').find(node => node.props['aria-pressed'] !== undefined)!; }
async function click() { await act(async () => { await button().props.onClick(); }); }

test('button mutes, switches to release, then restores permission without opening microphones', async () => {
  await mount();
  expect(button().props['aria-pressed']).toBe(false);
  await click();
  expect(calls).toEqual([['muteAll']]);
  expect(button().props.children[1]).toBe('liveMeeting.room.member.unmuteAll');
  expect(roomContext.room!.participants[0].micOn).toBe(true);
  await click();
  expect(calls.slice(1)).toEqual([['muteMember', 'bob', false], ['muteMember', 'carol', false]]);
  expect(roomContext.room!.participants.slice(1).every(p => !p.mutedByHost && !p.micOn)).toBe(true);
  expect(button().props['aria-pressed']).toBe(false);
  expect(successes.at(-1)).toBe('liveMeeting.room.member.allUnmutedToast');
  expect(errors).toEqual([]);
});

test('existing host restrictions are recognized on initial join and can be released', async () => {
  await mount(true);
  expect(button().props['aria-pressed']).toBe(true);
  await click();
  expect(button().props['aria-pressed']).toBe(false);
  expect(calls).not.toContainEqual(['muteAll']);
});

test('partial release failure stays visible and can be retried', async () => {
  await mount(true);
  failMember = 'carol';
  await click();
  expect(button().props['aria-pressed']).toBe(true);
  expect(button().props.disabled).toBe(false);
  expect(errors).toEqual(['Member request failed']);
  expect(successes).toEqual([]);
  failMember = undefined;
  calls.length = 0;
  await click();
  expect(calls).toEqual([['muteMember', 'carol', false]]);
  expect(button().props['aria-pressed']).toBe(false);
});

test('pending action disables the button and rejects duplicate submissions', async () => {
  await mount();
  let finish!: () => void;
  pendingMute = new Promise<void>(resolve => { finish = resolve; });
  let first!: Promise<void>;
  await act(async () => { first = button().props.onClick(); });
  expect(button().props.disabled).toBe(true);
  expect(await roomContext.setAllMuted(true)).toBe(false);
  expect(calls).toEqual([['muteAll']]);
  await act(async () => { finish(); await first; });
  expect(button().props.disabled).toBe(false);
});

test('approved guest receives the unlock and can open their own microphone', async () => {
  await mount(true, 'bob');
  await act(async () => { roomContext.toggleHand(); });
  expect(roomContext.self!.handRaised).toBe(true);
  await act(async () => { roomContext.toggleMic(); });
  expect(errors).toEqual(['muted_by_host']);
  expect(microphoneChanges).not.toContain(true);

  const approved = authoritative.participants.find(p => p.id === 'bob')!;
  approved.handRaised = false;
  approved.mutedByHost = false;
  await act(async () => { onRoomEvent({type:'participant_updated',ts:'now',data:{participant:{...approved}}}); });
  expect(roomContext.self!.mutedByHost).toBe(false);
  expect(roomContext.self!.micOn).toBe(false);
  expect(microphoneChanges).not.toContain(true);
  await act(async () => { roomContext.toggleMic(); });
  expect(roomContext.self!.micOn).toBe(true);
  expect(microphoneChanges).toContain(true);
  expect(roomContext.room!.participants.find(p => p.id === 'carol')!.mutedByHost).toBe(true);
});

test('hosts cannot raise a hand, and host transfer updates that permission', async () => {
  await mount();
  await act(async () => { roomContext.toggleHand(); });
  expect(calls).toEqual([]);
  const demoted = {...roomContext.self!,isHost:false};
  await act(async () => { onRoomEvent({type:'participant_updated',ts:'now',data:{participant:demoted}}); });
  await act(async () => { roomContext.toggleHand(); });
  expect(calls).toEqual([['updateSelf',{handRaised:true}]]);
});
