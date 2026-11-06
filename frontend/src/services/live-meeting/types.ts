/**
 * Live-meeting domain types (contract draft in frontend/P1_MOCK_PLAN.md §3.1/§3.3/§3.4).
 * UI layers may only import from here — field names converge on this single file so a
 * contract change never fans out into components.
 */

/* ---------- Scheduled meetings ---------- */

/** Display-only status derived from `startAt` (+`durationMin`); only cancellation is stored. */
export type ScheduledDisplayStatus = 'ongoing' | 'upcoming' | 'past';

export interface ScheduledHost {
  id: string;
  name: string;
}

export interface ScheduledMeeting {
  id: string;
  /** 6-digit meeting code, globally unique, generated on create. */
  code: string;
  title: string;
  /** ISO-8601 UTC. */
  startAt: string;
  /** 5–720 minutes. */
  durationMin: number;
  pwdEnabled: boolean;
  /** 4–6 digits, only meaningful while `pwdEnabled`. */
  pwd: string | null;
  /** Remind in-app 10 minutes before start (fired client-side, see plan §8.9). */
  remind: boolean;
  /** Joiners must be admitted by the host. */
  waitRoom: boolean;
  /** Explicit cancellation; display status is derived, never stored. */
  cancelled: boolean;
  host: ScheduledHost;
  /** Most recent scene's record; does not end or cancel this reservation. */
  meetingId: string | null;
  /** Current scene; absent on older servers. */
  activeRoomId?: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface ScheduledMeetingInput {
  title?: string;
  startAt: string;
  durationMin: number;
  pwdEnabled?: boolean;
  pwd?: string | null;
  remind?: boolean;
  waitRoom?: boolean;
}

export interface ScheduledRangeQuery {
  /** Optional ISO-8601 bounds: from inclusive, to exclusive. Omit both for all reservations. */
  from?: string;
  to?: string;
}

/* ---------- Live room ---------- */

export type RoomStatus = 'waiting' | 'active' | 'ended';
export type JoinState = 'joined' | 'waiting';

export interface Participant {
  id: string;
  /** Authenticated IM identity, used to associate RTC tracks with the roster. */
  userId?: string;
  name: string;
  isHost: boolean;
  isSelf: boolean;
  micOn: boolean;
  /** Host mute restriction; clearing it lets the participant turn their own mic on. */
  mutedByHost?: boolean;
  camOn: boolean;
  handRaised: boolean;
  /** At most one participant may share at a time (server arbitrates). */
  screenSharing: boolean;
  screenShareId?: string | null;
  joinedAt: string;
}

export interface WaitingEntry {
  participantId: string;
  name: string;
  requestedAt: string;
}

export interface LiveRoom {
  id: string;
  /** Scheduled title, else "Quick meeting" / "Meeting <code>". */
  title: string;
  code: string;
  scheduledMeetingId: string | null;
  status: RoomStatus;
  pwdEnabled: boolean;
  waitRoom: boolean;
  hostId: string;
  hostUserId?: string;
  /** Optional only for older servers and explicit demo fixtures. */
  recording?: RoomRecording;
  participants: Participant[];
  waiting: WaitingEntry[];
  startedAt: string | null;
  endedAt: string | null;
  meetingId: string | null;
}

/** Host-only settings. An omitted password keeps the current secret unchanged. */
export type RecordingAction = 'start' | 'stop' | 'request' | 'approve' | 'deny';
export interface RecordingRequest { participantId: string; name: string; requestId: string; status: 'pending' | 'approved' | 'denied' }
export interface RoomRecording { active: boolean; epoch: number; startedAt: string | null; requests: RecordingRequest[] }

export interface RoomSettingsPatch {
  title?: string;
  pwdEnabled?: boolean;
  pwd?: string;
  waitRoom?: boolean;
}

export interface ChatAttachment {
  id?: string;
  /** Stable IM file reference; never a temporary signed download URL. */
  url?: string;
  name: string;
  size: number;
}

export interface ChatMessage {
  /** Present for real IM messages; retain SDK metadata for reusable rich rendering/actions. */
  sdk?: import('@deeprespond/im-web').MessageView;
  id: string;
  sequence?: number;
  roomId: string;
  sender: { id: string; name: string; isSelf: boolean };
  text: string;
  attachment: ChatAttachment | null;
  createdAt: string;
}

export interface MeetingChatSession {
  transport: 'dr-im-group';
  groupId: string;
}

export type RoomMediaConfig = {
  transport: 'webrtc';
  iceServers: { urls: string; username?: string; credential?: string }[];
  token: string | null;
  unavailableReason?: string;
} | {
  transport: 'dr-rtc';
  channelId: string;
  /** One-use ticket. Keep in memory only; never log or persist it. */
  ticket: string;
  expiresAt: string;
};

export interface JoinRoomInput {
  code: string;
  name: string;
  micOn: boolean;
  camOn: boolean;
  /** Required when the room has `pwdEnabled`. */
  pwd?: string;
}

export interface JoinResult {
  room: LiveRoom;
  self: Participant;
  /** `waiting` while the room's wait-room gate is open for us. */
  state: JoinState;
  media: RoomMediaConfig;
}

export interface CreateRoomInput {
  title?: string;
  scheduledMeetingId?: string;
}

export interface SelfPatch {
  micOn?: boolean;
  camOn?: boolean;
  handRaised?: boolean;
  screenSharing?: boolean;
}

export interface ChatPage {
  messages: ChatMessage[];
  hasMore: boolean;
}

/* ---------- Errors ---------- */

/** Machine-readable join failures so the UI can render each state distinctly. */
export type LiveMeetingJoinErrorCode = 'not_found' | 'not_started' | 'ended' | 'wrong_pwd' | 'full';

export class LiveMeetingApiError extends Error {
  constructor(
    public readonly code: LiveMeetingJoinErrorCode,
    message: string,
  ) {
    super(message);
    this.name = 'LiveMeetingApiError';
  }
}

/* ---------- Signaling events (plan §3.4) ---------- */

export interface RoomEventEnvelope<T> {
  ts: string;
  data: T;
}

export type RoomEvent =
  | ({ type: 'screen_signal' } & RoomEventEnvelope<ScreenSignal & {senderId: string}>)
  | ({ type: 'connection_state' } & RoomEventEnvelope<{ state: string }>)
  | ({ type: 'participant_joined' } & RoomEventEnvelope<{ participant: Participant }>)
  | ({ type: 'participant_left' } & RoomEventEnvelope<{ participantId: string }>)
  | ({ type: 'participant_updated' } & RoomEventEnvelope<{ participant: Participant }>)
  | ({ type: 'waiting_requested' } & RoomEventEnvelope<{ participantId: string; name: string }>)
  | ({ type: 'waiting_resolved' } & RoomEventEnvelope<{ participantId: string; admitted: boolean }>)
  | ({ type: 'chat' } & RoomEventEnvelope<{ message: ChatMessage }>)
  | ({ type: 'active_speaker' } & RoomEventEnvelope<{ participantId: string | null }>)
  | ({ type: 'room_ended' } & RoomEventEnvelope<{ meetingId: string | null }>)
  | ({ type: 'room_state' } & RoomEventEnvelope<{ room: LiveRoom }>);

export type RoomEventListener = (event: RoomEvent) => void;

export interface ScreenSignal {
  sessionId: string;
  kind: 'ready' | 'offer' | 'answer' | 'candidate';
  payload: string;
}
