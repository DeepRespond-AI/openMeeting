import { expect, test } from 'bun:test';
import { deriveScheduledStatus } from '../../src/services/live-meeting/time';
import type { ScheduledMeeting } from '../../src/services/live-meeting/types';

const scheduled: ScheduledMeeting = { id: 'sched', code: '123456', title: 'Scheduled',
  startAt: '2026-10-28T08:00:00Z', durationMin: 30, pwdEnabled: false, pwd: null, remind: true,
  waitRoom: false, cancelled: false, host: { id: 'host', name: 'Host' }, meetingId: null,
  createdAt: '2026-10-27T08:00:00Z', updatedAt: '2026-10-27T08:00:00Z' };
test('early active scene is ongoing before the planned start', () => {
  expect(deriveScheduledStatus({ ...scheduled, activeRoomId: 'room-1' }, new Date('2026-10-27T08:00:00Z'))).toBe('ongoing');
});
test('time alone does not claim that a scene is ongoing', () => {
  expect(deriveScheduledStatus(scheduled, new Date('2026-10-28T08:15:00Z'))).toBe('past');
});
test('previous records do not consume a reservation', () => {
  expect(deriveScheduledStatus({ ...scheduled, meetingId: 'record-1' }, new Date('2026-10-27T08:00:00Z'))).toBe('upcoming');
});
