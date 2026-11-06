/**
 * The single interface the live-meeting UI depends on (plan §5.2). Two implementations exist:
 * `mock/` (in-memory demo) and `real/` (Tauri invoke → Rust → Phase 1 backend).
 * The real contract is server/API.md; documented mock differences remain in P1_MOCK_PLAN.md.
 */
import type {
  ChatMessage,
  ChatPage,
  CreateRoomInput,
  JoinResult,
  JoinRoomInput,
  LiveRoom,
  RoomEvent,
  ScheduledMeeting,
  ScheduledMeetingInput,
  ScheduledRangeQuery,
  SelfPatch,
  RoomMediaConfig,
} from './types';

export interface LiveMeetingApi {
  controlRecording?(roomId: string, action: import('./types').RecordingAction, epoch: number, participantId?: string, requestId?: string): Promise<LiveRoom>;
  updateRoom(roomId: string, patch: import('./types').RoomSettingsPatch): Promise<LiveRoom>;
  getScreenConfig?(roomId: string): Promise<{iceServers: RTCIceServer[]}>;
  startScreenShare?(roomId: string): Promise<{sessionId: string}>;
  stopScreenShare?(roomId: string, sessionId: string): Promise<void>;
  sendScreenSignal?(roomId: string, targetId: string, signal: import('./types').ScreenSignal): Promise<void>;
  getRoomMedia?(roomId: string): Promise<RoomMediaConfig>;
  recoverRoomMedia?(roomId: string, sessionId: string): Promise<{released: boolean}>;
  getChatSession?(roomId: string): Promise<import('./types').MeetingChatSession>;
  /** Detach signaling on route unmount without ending a host's room. */
  disconnectRoom?(roomId: string): Promise<void>;
  /* Scheduled meetings */
  listScheduledMeetings(query: ScheduledRangeQuery): Promise<ScheduledMeeting[]>;
  createScheduledMeeting(input: ScheduledMeetingInput): Promise<ScheduledMeeting>;
  updateScheduledMeeting(id: string, input: ScheduledMeetingInput): Promise<ScheduledMeeting>;
  deleteScheduledMeeting(id: string): Promise<void>;

  /* Rooms */
  createRoom(input: CreateRoomInput): Promise<LiveRoom>;
  /** Resolve a 6-digit code. Unstarted reservations return 'not_started'; unknown codes return 'not_found'. */
  checkRoomCode(code: string): Promise<LiveRoom>;
  joinRoom(input: JoinRoomInput): Promise<JoinResult>;
  leaveRoom(roomId: string): Promise<void>;
  /** Host only — ends the room and returns the created meeting-notes id. */
  endRoom(roomId: string): Promise<{ meetingId: string | null }>;
  admitParticipant(roomId: string, participantId: string): Promise<void>;
  denyParticipant(roomId: string, participantId: string): Promise<void>;
  getRoom(roomId: string): Promise<LiveRoom>;
  updateSelf(roomId: string, patch: SelfPatch): Promise<void>;

  /* Host controls — server/API.md §1.10; mock implements locally. */
  setParticipantMuted(roomId: string, participantId: string, muted: boolean): Promise<void>;
  approveHand(roomId: string, participantId: string): Promise<void>;
  removeParticipant(roomId: string, participantId: string): Promise<void>;
  transferHost(roomId: string, participantId: string): Promise<void>;
  muteAll(roomId: string): Promise<void>;
}

/** Explicit demo-only chat. Real meetings use the authenticated IM SDK. */
export interface MockMeetingChatApi {
  listChat(roomId: string, after?: string): Promise<ChatPage>;
  sendChat(roomId: string, text: string): Promise<ChatMessage>;
  sendChatAttachment(roomId: string, file: { name: string; size: number }): Promise<ChatMessage>;
}

/** Room-scoped signaling stream; envelopes are identical in mock and real. */
export interface LiveMeetingEventBus {
  /** Returns an unsubscribe function. */
  onRoomEvent(listener: (event: RoomEvent) => void): () => void;
}

/** Identity the mock layer stamps onto self/hosts. Real auth comes from the session. */
export interface LiveMeetingUser {
  id: string;
  name: string;
}
