/**
 * MockLiveMeetingApi — in-memory implementation of LiveMeetingApi + LiveMeetingEventBus (plan §5.4).
 *
 * Behavior contract (mirrors the V2 design prototype):
 * - Every method resolves after a 150–400 ms delay so UI loading states are real.
 * - Bot scripts per room, with timings taken from the design prototype (room.js):
 *     active speaker rotation every 5 s, a raised hand at ~12 s, waiting-room
 *     requests at ~8 s / ~23 s, my hand auto-approved after 5 s, chat replies at
 *     75 % probability after 0.9–2.5 s.
 * - Joining an unknown 6-digit code creates a room on demand with me as host
 *   (the prototype always casts "me" as host). A seeded room keeps its bot host
 *   so the member experience stays testable.
 * - Failures are injectable for developing the join error states.
 */
import type { LiveMeetingApi, LiveMeetingEventBus, LiveMeetingUser } from '../api';
import {
  type ChatMessage,
  type CreateRoomInput,
  type JoinResult,
  type JoinRoomInput,
  type LiveRoom,
  type Participant,
  type RoomEvent,
  type ScheduledMeeting,
  type ScheduledMeetingInput,
  type ScheduledRangeQuery,
  LiveMeetingApiError,
} from '../types';
import {
  CHAT_REPLIES,
  FILE_REPLIES,
  OTHER_NAMES,
  localISO,
  makeParticipant,
  mockId,
  seedActiveRoom,
  seedChatMessages,
  seedScheduledMeetings,
} from './seed';

/** Injectable join failures for developing the error UIs (plan §5.4). */
export interface MockFailures {
  join?: 'not_found' | 'ended' | 'wrong_pwd' | 'full';
}

const ROOM_CAPACITY = 6;
const LS_KEY = 'dr.liveMeeting.scheduled.v1';

function delay(): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, 150 + Math.random() * 250));
}

function rand(min: number, max: number): number {
  return min + Math.floor(Math.random() * (max - min + 1));
}

function pick<T>(arr: readonly T[]): T {
  return arr[Math.floor(Math.random() * arr.length)];
}

function genCode(existing: Set<string>): string {
  for (;;) {
    const code = String(rand(100000, 999999));
    if (!existing.has(code)) return code;
  }
}

export class MockLiveMeetingApi implements LiveMeetingApi, LiveMeetingEventBus {
  async updateRoom(roomId: string, patch: import('../types').RoomSettingsPatch): Promise<LiveRoom> {
    await delay();
    const room=this.findRoom(roomId);
    if(!room.participants.some(p=>p.isSelf&&p.isHost)) throw new Error('仅主持人可修改会议设置');
    if(patch.pwd!==undefined && !/^[0-9]{4,6}$/.test(patch.pwd)) throw new Error('密码须为 4–6 位数字');
    const {pwd, ...settings}=patch;
    if(pwd!==undefined)this.roomPasswords.set(room.id,pwd);
    if(patch.pwdEnabled===false)this.roomPasswords.delete(room.id);
    Object.assign(room,settings);
    // Mock join uses the scheduled meeting's password; keep that source in sync.
    const scheduled=this.scheduled.find(s=>s.id===room.scheduledMeetingId);
    if(scheduled){Object.assign(scheduled,settings);if(pwd!==undefined)scheduled.pwd=pwd;if(patch.pwdEnabled===false)scheduled.pwd=null;}
    this.emit({type:'room_state',ts:localISO(new Date()),data:{room}});
    return structuredClone(room);
  }
  private self: LiveMeetingUser = { id: 'user-self', name: 'Me' };
  private failures: MockFailures = {};
  private scheduled: ScheduledMeeting[] = [];
  private rooms = new Map<string, LiveRoom>();
  private roomPasswords = new Map<string,string>();
  private chat = new Map<string, ChatMessage[]>();
  private listeners = new Set<(e: RoomEvent) => void>();
  /** Per-room script timers; torn down when I leave/end the room. */
  private scripts = new Map<string, number[]>();

  constructor() {
    this.loadScheduled();
    // One bot-hosted room already in progress, so the member experience is testable.
    const active = seedActiveRoom();
    this.rooms.set(active.code, active);
  }

  /* ---------- configuration ---------- */

  setSelf(user: LiveMeetingUser | null): void {
    if (user) this.self = { id: user.id || this.self.id, name: user.name || this.self.name };
  }

  setFailures(failures: MockFailures): void {
    this.failures = failures;
  }

  /* ---------- persistence (scheduled only; rooms are session-bound) ---------- */

  private loadScheduled(): void {
    try {
      const raw = localStorage.getItem(LS_KEY);
      if (raw) {
        const arr = JSON.parse(raw) as ScheduledMeeting[];
        if (Array.isArray(arr) && arr.length) {
          this.scheduled = arr;
          return;
        }
      }
    } catch {
      /* storage unavailable — fall through to seeds */
    }
    this.scheduled = seedScheduledMeetings(this.self);
    this.persistScheduled();
  }

  private persistScheduled(): void {
    try {
      localStorage.setItem(LS_KEY, JSON.stringify(this.scheduled));
    } catch {
      /* storage unavailable */
    }
  }

  /* ---------- events ---------- */

  onRoomEvent(listener: (e: RoomEvent) => void): () => void {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  }

  private emit(event: RoomEvent): void {
    this.listeners.forEach((fn) => fn(event));
  }

  /* ---------- scheduled meetings ---------- */

  async updateScheduledMeeting(id: string, input: ScheduledMeetingInput): Promise<ScheduledMeeting> {
    await delay();
    const row = this.scheduled.find(m => m.id === id);
    if (!row || row.cancelled || Date.parse(row.startAt) <= Date.now()) throw new Error('预定已取消或会议已开始');
    Object.assign(row, input, { updatedAt: new Date().toISOString() });
    this.persistScheduled();
    return { ...row };
  }

  async listScheduledMeetings(query: ScheduledRangeQuery): Promise<ScheduledMeeting[]> {
    await delay();
    const from = query.from ? new Date(query.from).getTime() : -Infinity;
    const to = query.to ? new Date(query.to).getTime() : Infinity;
    return this.scheduled
      .filter((s) => !s.cancelled)
      .filter((s) => {
        const t = new Date(s.startAt).getTime();
        return t >= from && t < to;
      })
      .sort((a, b) => new Date(a.startAt).getTime() - new Date(b.startAt).getTime());
  }

  async createScheduledMeeting(input: ScheduledMeetingInput): Promise<ScheduledMeeting> {
    await delay();
    const start = new Date(input.startAt);
    if (Number.isNaN(start.getTime())) throw new Error('Invalid start time');
    if (start.getTime() < Date.now() - 60_000) throw new Error('Start time is in the past');
    if (!Number.isInteger(input.durationMin) || input.durationMin < 5 || input.durationMin > 720) {
      throw new Error('Duration must be 5–720 minutes');
    }
    const pwdEnabled = input.pwdEnabled ?? false;
    const pwd = pwdEnabled ? input.pwd ?? null : null;
    if (pwdEnabled && (pwd === null || !/^\d{4,6}$/.test(pwd))) {
      throw new Error('Password must be 4–6 digits');
    }

    const now = localISO(new Date());
    const meeting: ScheduledMeeting = {
      id: mockId('sched'),
      code: genCode(new Set(this.scheduled.map((s) => s.code))),
      title: input.title?.trim() || `${this.self.name}'s meeting`,
      startAt: localISO(start),
      durationMin: input.durationMin,
      pwdEnabled,
      pwd,
      remind: input.remind ?? true,
      waitRoom: input.waitRoom ?? false,
      cancelled: false,
      host: { id: this.self.id, name: this.self.name },
      meetingId: null,
      createdAt: now,
      updatedAt: now,
    };
    this.scheduled.unshift(meeting);
    this.persistScheduled();
    return meeting;
  }

  async deleteScheduledMeeting(id: string): Promise<void> {
    await delay();
    this.scheduled = this.scheduled.filter((s) => s.id !== id);
    this.persistScheduled();
  }

  /* ---------- rooms ---------- */

  private selfParticipant(micOn: boolean, camOn: boolean, isHost: boolean): Participant {
    // Stamp the injected self id so waiting-room resolution and leave cleanup match.
    return makeParticipant(this.self.name, { id: this.self.id, isSelf: true, isHost, micOn, camOn });
  }

  private ensureChat(roomId: string): ChatMessage[] {
    let list = this.chat.get(roomId);
    if (!list) {
      list = seedChatMessages(roomId);
      this.chat.set(roomId, list);
    }
    return list;
  }

  async createRoom(input: CreateRoomInput): Promise<LiveRoom> {
    await delay();
    const sched = input.scheduledMeetingId
      ? this.scheduled.find((s) => s.id === input.scheduledMeetingId) ?? null
      : null;
    const now = new Date();
    const room: LiveRoom = {
      id: mockId('room'),
      title: input.title || sched?.title || 'Quick meeting',
      code: sched?.code ?? genCode(new Set([...this.rooms.keys(), ...this.scheduled.map((s) => s.code)])),
      scheduledMeetingId: sched?.id ?? null,
      status: 'active',
      pwdEnabled: sched?.pwdEnabled ?? false,
      waitRoom: sched?.waitRoom ?? false,
      hostId: this.self.id,
      participants: [this.selfParticipant(true, false, true)],
      waiting: [],
      startedAt: localISO(now),
      endedAt: null,
      meetingId: null,
    };
    this.rooms.set(room.code, room);
    return room;
  }

  async checkRoomCode(code: string): Promise<LiveRoom> {
    await delay();
    const room = this.rooms.get(code);
    if (!room) {
      // On-demand rooms: joining an unknown code opens a new room with me as host
      // (prototype behavior). This keeps "join" the single entry point for the UI.
      const sched = this.scheduled.find((s) => s.code === code) ?? null;
      if (sched?.cancelled) throw new LiveMeetingApiError('ended', 'This meeting was cancelled');
      const now = new Date();
      const created: LiveRoom = {
        id: mockId('room'),
        title: sched?.title ?? `Meeting ${code}`,
        code,
        scheduledMeetingId: sched?.id ?? null,
        status: 'active',
        pwdEnabled: sched?.pwdEnabled ?? false,
        waitRoom: sched?.waitRoom ?? false,
        hostId: sched && sched.host.id === this.self.id ? this.self.id : '', // resolved on join
        participants: [],
        waiting: [],
        startedAt: localISO(now),
        endedAt: null,
        meetingId: null,
      };
      this.rooms.set(code, created);
      return created;
    }
    if (room.status === 'ended') throw new LiveMeetingApiError('ended', 'This meeting has ended');
    return room;
  }

  async joinRoom(input: JoinRoomInput): Promise<JoinResult> {
    await delay();
    if (this.failures.join) {
      throw new LiveMeetingApiError(this.failures.join, `Injected failure: ${this.failures.join}`);
    }
    if (!/^\d{6}$/.test(input.code)) throw new LiveMeetingApiError('not_found', 'Malformed meeting code');

    const room = await this.checkRoomCode(input.code);
    const existing = room.participants.find((p) => p.isSelf);
    if (existing) {
      // Already inside (e.g. quick-meeting host re-entering the page).
      this.startScripts(room);
      return { room, self: existing, state: 'joined', media: this.mediaConfig() };
    }
    if (room.participants.length >= ROOM_CAPACITY) {
      throw new LiveMeetingApiError('full', 'The room is full');
    }
    if (!room.hostId) room.hostId = this.self.id;
    const amHost = room.hostId === this.self.id;
    if (room.pwdEnabled && !amHost) {
      const expected = this.roomPasswords.get(room.id)??this.scheduled.find((s) => s.code === room.code)?.pwd ?? '0000';
      if (input.pwd !== expected) throw new LiveMeetingApiError('wrong_pwd', 'Wrong meeting password');
    }

    // Wait-room gate: I am parked until the (bot) host admits me after 5 s.
    if (room.waitRoom && room.hostId !== this.self.id) {
      const pending = makeParticipant(input.name.trim() || this.self.name, {
        id: this.self.id, isSelf: true, micOn: input.micOn, camOn: input.camOn,
      });
      room.waiting.push({ participantId: pending.id, name: pending.name, requestedAt: localISO(new Date()) });
      this.emit({ type: 'waiting_requested', ts: localISO(new Date()), data: { participantId: pending.id, name: pending.name } });
      window.setTimeout(() => {
        const live = this.rooms.get(room.code);
        if (!live) return;
        if (!live.waiting.some((w) => w.participantId === pending.id)) return; // cancelled meanwhile
        live.waiting = live.waiting.filter((w) => w.participantId !== pending.id);
        live.participants.push(pending);
        this.emit({ type: 'waiting_resolved', ts: localISO(new Date()), data: { participantId: pending.id, admitted: true } });
        this.emit({ type: 'participant_joined', ts: localISO(new Date()), data: { participant: pending } });
        this.startScripts(live);
      }, 5000);
      return { room, self: pending, state: 'waiting', media: this.mediaConfig() };
    }

    const me = this.selfParticipant(input.micOn, input.camOn, room.hostId === this.self.id);
    me.name = input.name.trim() || me.name;
    room.participants.push(me);
    this.emit({ type: 'participant_joined', ts: localISO(new Date()), data: { participant: me } });
    this.startScripts(room);
    return { room, self: me, state: 'joined', media: this.mediaConfig() };
  }

  async leaveRoom(roomId: string): Promise<void> {
    await delay();
    const room = this.findRoom(roomId);
    const me = room.participants.find((p) => p.isSelf);
    if (me) {
      room.participants = room.participants.filter((p) => p.id !== me.id);
      this.emit({ type: 'participant_left', ts: localISO(new Date()), data: { participantId: me.id } });
    }
    // Also covers cancelling out of the wait-room gate.
    room.waiting = room.waiting.filter((w) => w.participantId !== this.self.id);
    this.stopScripts(room.id);
  }

  async endRoom(roomId: string): Promise<{ meetingId: string | null }> {
    await delay();
    const room = this.findRoom(roomId);
    if (!room.participants.some((p) => p.isSelf && p.isHost)) {
      throw new LiveMeetingApiError('not_found', 'Only the host can end the meeting');
    }
    room.status = 'ended';
    room.endedAt = localISO(new Date());
    // The real backend creates the meeting-notes record server-side and returns its id;
    // the mock has no notes record to point at, so it returns null and the UI shows
    // the "ended" toast + navigates home (both branches exist in the room flow).
    room.meetingId = null;
    this.stopScripts(room.id);
    this.emit({ type: 'room_ended', ts: localISO(new Date()), data: { meetingId: null } });
    return { meetingId: null };
  }

  async admitParticipant(roomId: string, participantId: string): Promise<void> {
    await delay();
    const room = this.findRoom(roomId);
    const entry = room.waiting.find((w) => w.participantId === participantId);
    if (!entry) return;
    room.waiting = room.waiting.filter((w) => w.participantId !== participantId);
    const p = makeParticipant(entry.name, { micOn: false, camOn: false });
    room.participants.push(p);
    this.emit({ type: 'waiting_resolved', ts: localISO(new Date()), data: { participantId, admitted: true } });
    this.emit({ type: 'participant_joined', ts: localISO(new Date()), data: { participant: p } });
  }

  async denyParticipant(roomId: string, participantId: string): Promise<void> {
    await delay();
    const room = this.findRoom(roomId);
    room.waiting = room.waiting.filter((w) => w.participantId !== participantId);
    this.emit({ type: 'waiting_resolved', ts: localISO(new Date()), data: { participantId, admitted: false } });
  }

  async getRoom(roomId: string): Promise<LiveRoom> {
    await delay();
    return this.findRoom(roomId);
  }

  async updateSelf(roomId: string, patch: Partial<Pick<Participant, 'micOn' | 'camOn' | 'handRaised' | 'screenSharing'>>): Promise<void> {
    await delay();
    const room = this.findRoom(roomId);
    const me = room.participants.find((p) => p.isSelf);
    if (!me) return;
    if (patch.handRaised === true && me.isHost) return;
    if (patch.screenSharing === true) {
      // Server arbitration: at most one sharer — the newcomer takes over.
      room.participants.forEach((p) => {
        if (p.screenSharing) p.screenSharing = false;
      });
    }
    Object.assign(me, patch);
    this.emit({ type: 'participant_updated', ts: localISO(new Date()), data: { participant: { ...me } } });

    // Design demo: as a member, my raised hand is auto-approved after 5 s.
    if (patch.handRaised === true && !me.isHost) {
      window.setTimeout(() => {
        const live = this.rooms.get(room.code);
        const self = live?.participants.find((p) => p.isSelf);
        if (!live || !self || !self.handRaised) return;
        self.handRaised = false;
        self.mutedByHost = false;
        this.emit({ type: 'participant_updated', ts: localISO(new Date()), data: { participant: { ...self } } });
      }, 5000);
    }
  }

  /* ---------- host controls (backend contract TBD, plan §8.5) ---------- */

  async setParticipantMuted(roomId: string, participantId: string, muted: boolean): Promise<void> {
    await delay();
    const room = this.findRoom(roomId);
    const p = room.participants.find((x) => x.id === participantId);
    if (!p || p.isSelf) return;
    if (muted) p.micOn = false;
    p.mutedByHost = muted;
    this.emitUpdated(room, p);
  }

  async approveHand(roomId: string, participantId: string): Promise<void> {
    await delay();
    const room = this.findRoom(roomId);
    const p = room.participants.find((x) => x.id === participantId);
    if (!p) return;
    p.handRaised = false;
    p.mutedByHost = false;
    this.emitUpdated(room, p);
  }

  async removeParticipant(roomId: string, participantId: string): Promise<void> {
    await delay();
    const room = this.findRoom(roomId);
    room.participants = room.participants.filter((x) => x.id !== participantId);
    this.emit({ type: 'participant_left', ts: localISO(new Date()), data: { participantId } });
  }

  async transferHost(roomId: string, participantId: string): Promise<void> {
    await delay();
    const room = this.findRoom(roomId);
    const next = room.participants.find((x) => x.id === participantId);
    if (!next) return;
    room.hostId = next.id;
    room.participants.forEach((x) => { x.isHost = x.id === next.id; });
    next.handRaised = false;
    next.mutedByHost = false;
    room.participants.forEach((x) => this.emitUpdated(room, x));
  }

  async muteAll(roomId: string): Promise<void> {
    await delay();
    const room = this.findRoom(roomId);
    room.participants.forEach((p) => {
      if (!p.isHost) {
        p.micOn = false;
        p.mutedByHost = true;
        this.emitUpdated(room, p);
      }
    });
  }

  private emitUpdated(room: LiveRoom, p: Participant): void {
    this.emit({ type: 'participant_updated', ts: localISO(new Date()), data: { participant: { ...p } } });
  }

  /* ---------- chat ---------- */

  async listChat(roomId: string, after?: string): Promise<{ messages: ChatMessage[]; hasMore: boolean }> {
    await delay();
    const list = this.ensureChat(this.findRoom(roomId).id);
    const idx = after ? list.findIndex((m) => m.id === after) : -1;
    const messages = idx >= 0 ? list.slice(idx + 1) : list;
    return { messages, hasMore: false };
  }

  async sendChat(roomId: string, text: string): Promise<ChatMessage> {
    await delay();
    const room = this.findRoom(roomId);
    const msg: ChatMessage = {
      id: mockId('msg'),
      roomId: room.id,
      sender: { id: this.self.id, name: this.self.name, isSelf: true },
      text: text.slice(0, 200),
      attachment: null,
      createdAt: localISO(new Date()),
    };
    this.pushChat(room, msg);
    return msg;
  }

  async sendChatAttachment(roomId: string, file: { name: string; size: number }): Promise<ChatMessage> {
    await delay();
    const room = this.findRoom(roomId);
    const msg: ChatMessage = {
      id: mockId('msg'),
      roomId: room.id,
      sender: { id: this.self.id, name: this.self.name, isSelf: true },
      text: '',
      attachment: { name: file.name, size: file.size },
      createdAt: localISO(new Date()),
    };
    this.pushChat(room, msg);
    return msg;
  }

  private pushChat(room: LiveRoom, msg: ChatMessage): void {
    this.ensureChat(room.id).push(msg);
    this.emit({ type: 'chat', ts: localISO(new Date()), data: { message: msg } });
    this.scheduleBotReply(room, msg.attachment ? FILE_REPLIES : CHAT_REPLIES, 0.75);
  }

  /* ---------- room scripts (design prototype timings) ---------- */

  private findRoom(roomId: string): LiveRoom {
    for (const room of this.rooms.values()) {
      if (room.id === roomId) return room;
    }
    throw new LiveMeetingApiError('not_found', 'Room not found');
  }

  private script(room: LiveRoom, fn: () => void, ms: number): void {
    const timers = this.scripts.get(room.id) ?? [];
    timers.push(window.setTimeout(() => {
      if (this.rooms.get(room.code)?.status === 'active') fn();
    }, ms));
    this.scripts.set(room.id, timers);
  }

  private startScripts(room: LiveRoom): void {
    if (this.scripts.has(room.id)) return; // already running

    // Active speaker rotation — every 5 s pick another unmuted participant.
    this.script(room, () => {
      const live = this.rooms.get(room.code);
      if (!live) return;
      const candidates = live.participants.filter((p) => p.micOn);
      const next = candidates.length ? pick(candidates).id : null;
      this.emit({ type: 'active_speaker', ts: localISO(new Date()), data: { participantId: next } });
    }, 5000);

    // A bot raises a hand ~12 s in, waiting for my approval.
    this.script(room, () => {
      const live = this.rooms.get(room.code);
      if (!live) return;
      const others = live.participants.filter((p) => !p.isSelf && !p.isHost && !p.handRaised);
      if (!others.length) return;
      const who = pick(others);
      who.handRaised = true;
      this.emit({ type: 'participant_updated', ts: localISO(new Date()), data: { participant: { ...who } } });
    }, 12_000);

    // Waiting-room requests at ~8 s and ~23 s (wait-room rooms only).
    if (room.waitRoom) {
      this.script(room, () => {
        const live = this.rooms.get(room.code);
        if (!live) return;
        const name = OTHER_NAMES[rand(0, OTHER_NAMES.length - 1)];
        const id = mockId('user');
        live.waiting.push({ participantId: id, name, requestedAt: localISO(new Date()) });
        this.emit({ type: 'waiting_requested', ts: localISO(new Date()), data: { participantId: id, name } });
      }, 8000);
      this.script(room, () => {
        const live = this.rooms.get(room.code);
        if (!live || live.waiting.length) return;
        const name = OTHER_NAMES[rand(0, OTHER_NAMES.length - 1)];
        const id = mockId('user');
        live.waiting.push({ participantId: id, name, requestedAt: localISO(new Date()) });
        this.emit({ type: 'waiting_requested', ts: localISO(new Date()), data: { participantId: id, name } });
      }, 23_000);
    }
  }

  private scheduleBotReply(room: LiveRoom, pool: readonly string[], probability: number): void {
    if (Math.random() >= probability) return;
    const others = room.participants.filter((p) => !p.isSelf);
    if (!others.length) return;
    const who = pick(others);
    this.script(room, () => {
      const live = this.rooms.get(room.code);
      if (!live) return;
      const msg: ChatMessage = {
        id: mockId('msg'),
        roomId: live.id,
        sender: { id: who.id, name: who.name, isSelf: false },
        text: pick(pool),
        attachment: null,
        createdAt: localISO(new Date()),
      };
      this.ensureChat(live.id).push(msg);
      this.emit({ type: 'chat', ts: localISO(new Date()), data: { message: msg } });
    }, rand(900, 2500));
  }

  private stopScripts(roomId: string): void {
    const timers = this.scripts.get(roomId);
    if (timers) {
      timers.forEach((t) => window.clearTimeout(t));
      this.scripts.delete(roomId);
    }
  }

  private mediaConfig() {
    return {
      transport: 'webrtc' as const,
      iceServers: [{ urls: 'stun:stun.l.google.com:19302' }],
      token: null,
    };
  }
}
