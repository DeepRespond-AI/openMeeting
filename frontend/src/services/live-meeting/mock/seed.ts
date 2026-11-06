/**
 * Seed data for the mock layer. Names/copy pools are lifted from the V2 design
 * prototype (设计图V2/电脑端/assets/js/views/room.js) so the demo feels identical.
 * Scheduled seeds are relative to "now" so the home "today" panel is always populated.
 */
import type { ChatMessage, LiveRoom, Participant, ScheduledMeeting } from '../types';

export const OTHER_NAMES = ['李娜', '王凯', '陈静', '刘洋', '孙倩'] as const;

/** Bot replies after I send a chat message (design room.js CHAT_REPLIES). */
export const CHAT_REPLIES = [
  '收到',
  '同意，就按这个来',
  '我这边没问题',
  '稍等，我看一下',
  '好的，会后我同步给你',
  'This plan works for me',
  '补充一点：数据明天上午给大家',
] as const;

/** Bot replies after I send a file message (design room.js FILE_REPLIES). */
export const FILE_REPLIES = [
  '文件已收到，我看看',
  '收到，谢谢！',
  '好的，我下载看一下',
  '收到，稍后回复你',
] as const;

/** Pre-seeded chat so the panel is never empty on open (design room.js chatMsgs). */
export const SEED_CHAT: { name: string; text: string }[] = [
  { name: '李娜', text: '大家好，材料我已经发到群里了' },
  { name: '王凯', text: '收到，我们开始吧' },
];

export function localISO(d: Date): string {
  // ISO-8601 with the local offset kept simple: mock stores UTC-calibrated strings
  // via Date.prototype.toISOString, so everything flows through Date parsing.
  return d.toISOString();
}

function at(hour: number, minute = 0, dayOffset = 0): Date {
  const d = new Date();
  d.setDate(d.getDate() + dayOffset);
  d.setHours(hour, minute, 0, 0);
  return d;
}

let seq = 0;
export function mockId(prefix: string): string {
  seq += 1;
  return `${prefix}-${Date.now().toString(36)}${seq.toString(36)}`;
}

export function makeParticipant(
  name: string,
  opts: Partial<Participant> & { isSelf?: boolean; id?: string } = {},
): Participant {
  return {
    id: opts.id ?? (opts.isSelf ? 'user-self' : mockId('user')),
    name,
    isHost: opts.isHost ?? false,
    isSelf: opts.isSelf ?? false,
    micOn: opts.micOn ?? false,
    mutedByHost: opts.mutedByHost ?? false,
    camOn: opts.camOn ?? false,
    handRaised: opts.handRaised ?? false,
    screenSharing: opts.screenSharing ?? false,
    joinedAt: opts.joinedAt ?? localISO(new Date()),
  };
}

export function seedScheduledMeetings(self: { id: string; name: string }): ScheduledMeeting[] {
  const now = new Date();
  const upcoming = at(16, 30, 0);
  // If 16:30 today already passed, push to tomorrow so "upcoming" stays true.
  if (upcoming.getTime() <= now.getTime()) upcoming.setDate(upcoming.getDate() + 1);

  return [
    {
      id: mockId('sched'),
      code: '246810',
      title: 'Product weekly',
      startAt: localISO(upcoming),
      durationMin: 60,
      pwdEnabled: false,
      pwd: null,
      remind: true,
      waitRoom: false,
      cancelled: false,
      host: { id: self.id, name: self.name },
      meetingId: null,
      createdAt: localISO(now),
      updatedAt: localISO(now),
    },
    {
      id: mockId('sched'),
      code: '135790',
      title: 'Design review (password required)',
      startAt: localISO(at(10, 0, 1)),
      durationMin: 45,
      pwdEnabled: true,
      pwd: '1234',
      remind: false,
      waitRoom: true,
      cancelled: false,
      host: { id: self.id, name: self.name },
      meetingId: null,
      createdAt: localISO(now),
      updatedAt: localISO(now),
    },
  ];
}

/** A room already in progress, hosted by a bot — lets me test the member experience. */
export function seedActiveRoom(): LiveRoom {
  const now = new Date();
  const host = makeParticipant('李娜', { isHost: true, micOn: true });
  const members = [
    host,
    makeParticipant('王凯', { micOn: true }),
    makeParticipant('陈静', { micOn: false }),
  ];
  return {
    id: mockId('room'),
    title: 'Engineering sync',
    code: '112233',
    scheduledMeetingId: null,
    status: 'active',
    pwdEnabled: false,
    waitRoom: false,
    hostId: host.id,
    participants: members,
    waiting: [],
    startedAt: localISO(new Date(now.getTime() - 8 * 60 * 1000)),
    endedAt: null,
    meetingId: null,
  };
}

export function seedChatMessages(roomId: string): ChatMessage[] {
  const base = Date.now() - 5 * 60 * 1000;
  return SEED_CHAT.map((c, i) => ({
    id: mockId('msg'),
    roomId,
    sender: { id: `user-seed-${i}`, name: c.name, isSelf: false },
    text: c.text,
    attachment: null,
    createdAt: localISO(new Date(base + i * 40_000)),
  }));
}
