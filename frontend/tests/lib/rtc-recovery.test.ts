import { expect, test } from 'bun:test';
import { MediaReleaseTimeout, recoverRoomRtc, rtcWait } from '../../src/services/live-meeting/media/recovery';
import type { LiveMeetingApi } from '../../src/services/live-meeting/api';

test('release confirmation precedes the fresh ticket for the same room', async () => {
  const calls: string[] = [];
  let attempts = 0;
  const api = {
    recoverRoomMedia: async (roomId: string, sessionId: string) => {
      calls.push(`release:${roomId}:${sessionId}`);
      return {released: ++attempts === 2};
    },
    getRoomMedia: async (roomId: string) => {
      calls.push(`ticket:${roomId}`);
      return {transport:'dr-rtc',channelId:roomId};
    },
  } as unknown as LiveMeetingApi;
  const result = await recoverRoomRtc(api, 'room-original', 'stale', new AbortController().signal);
  expect(calls).toEqual(['release:room-original:stale','release:room-original:stale','ticket:room-original']);
  expect(result.transport).toBe('dr-rtc');
  if (result.transport==='dr-rtc') expect(result.channelId).toBe('room-original');
});

test('platform refusal never issues a new ticket', async () => {
  let tickets = 0;
  const api = {
    recoverRoomMedia: async () => {throw new Error('Platform refused release');},
    getRoomMedia: async () => {tickets++;},
  } as unknown as LiveMeetingApi;
  await expect(recoverRoomRtc(api,'room','stale',new AbortController().signal)).rejects.toThrow('Platform refused');
  expect(tickets).toBe(0);
});

test('leaving during release ignores a late success and never requests a ticket', async () => {
  let resolve!: (result: {released: boolean}) => void, tickets = 0;
  const controller = new AbortController();
  const api = {
    recoverRoomMedia: () => new Promise<{released:boolean}>(done => {resolve=done;}),
    getRoomMedia: async () => {tickets++;},
  } as unknown as LiveMeetingApi;
  const pending = recoverRoomRtc(api,'room','stale',controller.signal);
  controller.abort();
  await expect(pending).rejects.toThrow('cancelled');
  resolve({released:true});
  await Promise.resolve();
  expect(tickets).toBe(0);
});

test('an unresponsive lookup is bounded and its late result is ignored', async () => {
  let resolve!: (value: string) => void;
  const pending = rtcWait(new Promise<string>(done => {resolve=done;}), new AbortController().signal, Date.now()+10);
  await expect(pending).rejects.toBeInstanceOf(MediaReleaseTimeout);
  resolve('late');
});

test('release polling stops at its deadline without issuing a ticket', async () => {
  const original = Date.now;
  let now = original(), attempts = 0, tickets = 0;
  Date.now = () => now;
  try {
    const api = {
      recoverRoomMedia: async () => {attempts++;now+=21_000;return {released:false};},
      getRoomMedia: async () => {tickets++;},
    } as unknown as LiveMeetingApi;
    await expect(recoverRoomRtc(api,'room','stale',new AbortController().signal)).rejects.toBeInstanceOf(MediaReleaseTimeout);
    expect(attempts).toBe(1);
    expect(tickets).toBe(0);
  } finally {Date.now=original;}
});
