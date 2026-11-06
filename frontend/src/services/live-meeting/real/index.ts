/** Authenticated Phase 1 REST/WS transport; all networking stays in Rust. */
import { invoke } from '@tauri-apps/api/core';
import { listen, type UnlistenFn } from '@tauri-apps/api/event';
import type { LiveMeetingApi, LiveMeetingEventBus } from '../api';
import { LiveMeetingApiError, type LiveMeetingJoinErrorCode, type ScheduledRangeQuery,
  type ScheduledMeetingInput, type ScheduledMeeting, type LiveRoom, type CreateRoomInput,
  type JoinRoomInput, type JoinResult, type SelfPatch, type MeetingChatSession, type RoomEvent } from '../types';

type Failure = { status?: number; code?: string; detail?: string };
export function mapLiveError(error: unknown): Error {
  let data: Failure = typeof error === 'object' && error !== null ? error as Failure : {};
  if (typeof error === 'string') {
    try { data = JSON.parse(error) as Failure; } catch { return new Error(error); }
  }
  const message = data.detail || (error instanceof Error ? error.message : 'Request failed');
  // Only explicit domain codes may select join-specific UX. Permission and
  // concurrency failures must retain their actual detail, including old servers.
  const fallback = data.status === 404 ? 'not_found' : undefined;
  // Older meeting services used not_found for this exact reserved-room state.
  const legacyNotStarted = data.status === 404 && (!data.code || data.code === 'not_found')
    && ['会议尚未开始', '会议尚未开始，请等待房主进入后重试'].includes(data.detail || '');
  const code = legacyNotStarted ? 'not_started' : data.code ?? fallback;
  if (code && ['not_found', 'not_started', 'ended', 'wrong_pwd', 'full'].includes(code)) {
    return new LiveMeetingApiError(code as LiveMeetingJoinErrorCode, message);
  }
  return new Error(message);
}
export class RealLiveMeetingApi implements LiveMeetingApi, LiveMeetingEventBus {
  controlRecording(roomId: string, action: import('../types').RecordingAction, epoch: number, participantId?: string, requestId?: string) {
    return this.call<LiveRoom>('room_recording_control', {roomId, action, epoch, participantId, requestId});
  }
  updateRoom(roomId: string, patch: import('../types').RoomSettingsPatch) { return this.call<LiveRoom>('room_patch',{roomId,...patch}); }
  getScreenConfig(roomId: string) { return this.call<{iceServers: RTCIceServer[]}>('room_screen_config',{roomId}); }
  startScreenShare(roomId: string) { return this.call<{sessionId:string}>('room_screen_start',{roomId}); }
  stopScreenShare(roomId: string, sessionId:string) { return this.call<void>('room_screen_stop',{roomId,sessionId}); }
  sendScreenSignal(roomId:string,targetId:string,signal:import('../types').ScreenSignal) { return this.call<void>('room_screen_signal',{roomId,targetId,...signal}); }
  private listeners = new Set<(event: RoomEvent) => void>();
  private listening: Promise<void> | null = null;
  private off: UnlistenFn[] = [];
  private activeRoom: string | null = null;
  private waitingPoll: ReturnType<typeof setInterval> | null = null;
  private pendingEvents: (RoomEvent & {roomId?: string})[] = [];
  private async call<T>(command: string, args?: Record<string, unknown>): Promise<T> {
    try { return await invoke<T>(command, args); } catch (error) { throw mapLiveError(error); }
  }
  private ensureListening(): Promise<void> {
    if (!this.listening) this.listening = (async () => {
      try {
        this.off.push(await listen<RoomEvent & { roomId?: string }>('room-event', ({ payload }) => {
          if (!this.activeRoom) {
            this.pendingEvents.push(payload);
            this.pendingEvents = this.pendingEvents.slice(-100);
            return;
          }
          if (this.activeRoom && (!payload.roomId || payload.roomId === this.activeRoom)) {
            for (const listener of this.listeners) listener(payload);
          }
        }));
        this.off.push(await listen<{roomId: string; state: string}>('room-connection', ({ payload }) => {
          if (payload.roomId !== this.activeRoom) return;
          const event: RoomEvent = { type: 'connection_state', ts: new Date().toISOString(), data: { state: payload.state } };
          for (const listener of this.listeners) listener(event);
        }));
      } catch (error) {
        this.off.splice(0).forEach((off) => off());
        this.listening = null;
        throw error;
      }
    })();
    return this.listening;
  }
  listScheduledMeetings(query: ScheduledRangeQuery) { return this.call<ScheduledMeeting[]>('sched_list', { ...query }); }
  createScheduledMeeting(input: ScheduledMeetingInput) { return this.call<ScheduledMeeting>('sched_create', { ...input }); }
  deleteScheduledMeeting(id: string) { return this.call<void>('sched_delete', { id }); }
  updateScheduledMeeting(id: string, input: ScheduledMeetingInput) { return this.call<ScheduledMeeting>('sched_update', { id, ...input }); }
  createRoom(input: CreateRoomInput) { return this.call<LiveRoom>('room_create', { ...input }); }
  checkRoomCode(code: string) { return this.call<LiveRoom>('room_get_code', { code }); }
  async joinRoom(input: JoinRoomInput): Promise<JoinResult> {
    await this.ensureListening();
    const result = await this.call<JoinResult>('room_join', { ...input });
    this.activeRoom = result.room.id;
    if (result.state === 'waiting') {
      // Phase 1 servers admit only joined participants to WS. Poll the existing
      // code precheck while waiting, without retrying join (which would recreate
      // a denied participant). Upgrade to WS immediately after admission.
      let polling = false;
      this.waitingPoll = setInterval(() => {
        if (polling || this.activeRoom !== result.room.id) return;
        polling = true;
        void (async () => {
          try {
            const snapshot = await this.checkRoomCode(input.code);
            if (this.activeRoom !== result.room.id) return;
            const admitted = snapshot.participants.some((p) => p.id === result.self.id);
            if (!admitted && snapshot.waiting.some((p) => p.participantId === result.self.id)) return;
            if (this.waitingPoll) clearInterval(this.waitingPoll);
            this.waitingPoll = null;
            if (admitted) {
              snapshot.participants = snapshot.participants.map((p) => ({ ...p, isSelf: p.id === result.self.id }));
              for (const listener of this.listeners) listener({ type: 'room_state', ts: new Date().toISOString(), data: {room: snapshot} });
              await this.call('room_signal_connect', {roomId: result.room.id});
            }
            for (const listener of this.listeners) listener({ type: 'waiting_resolved', ts: new Date().toISOString(), data: {participantId: result.self.id, admitted} });
          } catch (error) {
            if (error instanceof LiveMeetingApiError && error.code === 'ended') {
              if (this.waitingPoll) clearInterval(this.waitingPoll);
              this.waitingPoll = null;
              for (const listener of this.listeners) listener({type:'room_ended',ts:new Date().toISOString(),data:{meetingId:null}});
            }
          } finally { polling = false; }
        })();
      }, 1000);
    } else {
      await this.call('room_signal_connect', { roomId: result.room.id });
    }
    // A fast WS snapshot may beat the HTTP response. Replay it after the caller
    // installs JoinResult, so the newest roster is not overwritten by that result.
    const pending = this.pendingEvents.splice(0);
    setTimeout(() => {
      if (this.activeRoom !== result.room.id) return;
      for (const event of pending) if (event.roomId === result.room.id) {
        for (const listener of this.listeners) listener(event);
      }
    }, 0);
    return result;
  }
  async disconnectRoom(roomId: string): Promise<void> {
    if (this.activeRoom !== roomId) return;
    this.activeRoom = null;
    this.pendingEvents = [];
    if (this.waitingPoll) clearInterval(this.waitingPoll);
    this.waitingPoll = null;
    await this.call('room_signal_disconnect', { roomId });
    this.off.splice(0).forEach((off) => off());
    this.listening = null;
  }
  async leaveRoom(roomId: string): Promise<void> { await this.call('room_leave', { roomId }); await this.disconnectRoom(roomId); }
  async endRoom(roomId: string): Promise<{meetingId: string | null}> {
    const result = await this.call<{meetingId: string | null}>('room_end', { roomId });
    await this.disconnectRoom(roomId); return result;
  }
  admitParticipant(roomId: string, participantId: string) { return this.call<void>('room_admit', { roomId, participantId }); }
  denyParticipant(roomId: string, participantId: string) { return this.call<void>('room_deny', { roomId, participantId }); }
  getRoom(roomId: string) { return this.call<LiveRoom>('room_get', { roomId }); }
  updateSelf(roomId: string, patch: SelfPatch) { return this.call<void>('room_update_self', { roomId, ...patch }); }
  getChatSession(roomId: string) { return this.call<MeetingChatSession>('room_chat_session', { roomId }); }
  getRoomMedia(roomId: string) { return this.call<import('../types').RoomMediaConfig>('room_media_ticket', {roomId}); }
  recoverRoomMedia(roomId: string, sessionId: string) { return this.call<{released:boolean}>('room_media_recover', {roomId,sessionId}); }
  setParticipantMuted(roomId: string, participantId: string, muted: boolean) { return this.call<void>('room_mute_participant', { roomId, participantId, muted }); }
  approveHand(roomId: string, participantId: string) { return this.call<void>('room_approve_hand', { roomId, participantId }); }
  removeParticipant(roomId: string, participantId: string) { return this.call<void>('room_remove_participant', { roomId, participantId }); }
  transferHost(roomId: string, participantId: string) { return this.call<void>('room_transfer_host', { roomId, participantId }); }
  muteAll(roomId: string) { return this.call<void>('room_mute_all', { roomId }); }
  onRoomEvent(listener: (event: RoomEvent) => void): () => void {
    this.listeners.add(listener);
    return () => { this.listeners.delete(listener); };
  }
}
