import { invoke } from '@tauri-apps/api/core';
import { mapLiveError } from './real';
import type { Participant } from './types';
import type { MediaTrack } from './media/types';

type Chunk = { chunkId: string; participantId: string; startTime: number; pcm: string; epoch: number };
type Capture = { source: MediaStreamAudioSourceNode; node: ScriptProcessorNode; silent: GainNode; flush: () => void };
export type RecordingState = 'waiting' | 'recording' | 'uploading' | 'error' | 'stopped';

/** Records cloned RTC tracks without stopping or changing SDK-owned capture/playback. */
export class RoomRecorder {
  private context: AudioContext | null = null;
  private captures = new Map<string, Capture>();
  private pending: Chunk[] = [];
  private draining: Promise<void> | null = null;
  private stopped = false;
  private finishing = false;
  private pausedForBacklog = false;
  private lastUploadError: string | null = null;
  private retryTimer: ReturnType<typeof setTimeout> | null = null;
  private retryDelay = 1000;
  private latestTracks: MediaTrack[] = [];
  private latestParticipants: Participant[] = [];
  constructor(private roomId: string, private startedAt: string, private report: (state: RecordingState, error?: string) => void, private epoch = 1) {}

  sync(tracks: MediaTrack[], participants: Participant[]) {
    this.latestTracks = tracks;
    this.latestParticipants = participants;
    if (this.stopped || this.finishing || this.pausedForBacklog) return;
    const valid = tracks.filter(t => t.kind === 'audio' && t.track.readyState === 'live');
    const keys = new Set(valid.map(t => t.key));
    for (const [key, capture] of this.captures) if (!keys.has(key)) {
      capture.flush(); capture.source.disconnect(); capture.node.disconnect(); capture.silent.disconnect(); this.captures.delete(key);
    }
    for (const track of valid) {
      const participant = participants.find(p => track.local ? p.isSelf : p.userId === track.username);
      if (!participant || this.captures.has(track.key)) continue;
      try {
        const context = this.context ?? (this.context = new AudioContext({ sampleRate: 16000 }));
        void context.resume().then(() => {
          if (context.state !== 'running') this.report('error', '录音尚未启动，请点击会议页面激活音频');
        }).catch(error => this.report('error', String(error)));
        const source = context.createMediaStreamSource(new MediaStream([track.track]));
        const node = context.createScriptProcessor(4096, 1, 1);
        const silent = context.createGain(); silent.gain.value = 0;
        let parts: Int16Array[] = [], size = 0, start = 0;
        const flush = () => {
          if (!size) return;
          const bytes = new Uint8Array(size * 2); const view = new DataView(bytes.buffer); let offset = 0;
          for (const part of parts) for (const sample of part) { view.setInt16(offset, sample, true); offset += 2; }
          let binary = ''; for (const byte of bytes) binary += String.fromCharCode(byte);
          this.pending.push({ chunkId: crypto.randomUUID(), participantId: participant.id, startTime: start, pcm: btoa(binary), epoch: this.epoch });
          parts = []; size = 0;
          if (this.pending.length >= 120) {
            this.pauseForBacklog();
            return;
          }
          void this.drain().catch(() => {});
        };
        node.onaudioprocess = event => {
          if (this.stopped) return;
          const input = event.inputBuffer.getChannelData(0);
          const rate = event.inputBuffer.sampleRate;
          const pcm = new Int16Array(Math.round(input.length * 16000 / rate));
          for (let i = 0; i < pcm.length; i++) {
            const sample = input[Math.min(input.length - 1, Math.floor(i * rate / 16000))];
            pcm[i] = Math.round(Math.max(-1, Math.min(1, sample)) * 32767);
          }
          if (!size) start = Math.max(0, (Date.now() - Date.parse(this.startedAt)) / 1000 - pcm.length / 16000);
          parts.push(pcm); size += pcm.length;
          if (size >= 80000) flush();
        };
        source.connect(node); node.connect(silent); silent.connect(context.destination);
        this.captures.set(track.key, { source, node, silent, flush });
        this.report('recording');
      } catch (error) { this.report('error', error instanceof Error ? error.message : '录音采集失败'); }
    }
  }

  async resume() { if (this.context?.state === 'suspended') await this.context.resume(); }
  private pauseForBacklog() {
    if (this.pausedForBacklog) return;
    this.pausedForBacklog = true;
    // Keep each track's final partial segment before suspending capture.
    for (const capture of this.captures.values()) capture.flush();
    this.detach();
    this.report('error', this.lastUploadError
      ? `录音上传已暂停：${this.lastUploadError}`
      : '录音上传积压，已暂停采集，请重试上传');
  }
  async retryUploads() {
    this.clearRetry();
    if (this.draining) await this.draining.catch(() => {});
    await this.drain();
    if (this.pausedForBacklog && !this.finishing && !this.stopped) {
      this.pausedForBacklog = false;
      this.sync(this.latestTracks, this.latestParticipants);
    }
  }
  private clearRetry() {
    if (this.retryTimer) clearTimeout(this.retryTimer);
    this.retryTimer = null;
  }
  private drain(): Promise<void> {
    if (this.draining) return this.draining;
    if (!this.pending.length) return Promise.resolve();
    const work = (async () => {
      try {
        while (this.pending.length) {
          await invoke('room_recording_chunk', { roomId: this.roomId, chunk: this.pending[0] });
          this.pending.shift();
        }
        this.lastUploadError = null;
        this.retryDelay = 1000;
        this.clearRetry();
        if (this.pausedForBacklog && !this.finishing && !this.stopped) {
          this.pausedForBacklog = false;
          this.sync(this.latestTracks, this.latestParticipants);
        }
        if (!this.stopped) this.report(this.finishing ? 'uploading' : this.captures.size ? 'recording' : 'waiting');
      } catch (error) {
        let failure = error as { status?: number; detail?: string };
        if (typeof error === 'string') {
          try { failure = JSON.parse(error); } catch { /* Native missing-command errors are plain strings. */ }
        }
        const message = mapLiveError(error).message;
        this.lastUploadError = /room_recording_chunk.*not found|not found.*room_recording_chunk/i.test(message)
          ? '客户端录音组件版本过旧，请重新编译并启动客户端'
          : failure?.status === 404 && /资源不存在|Not Found/i.test(message)
            ? '服务器未提供会议录音接口，请更新后端服务'
            : message;
        if (!this.stopped) this.report('error', this.lastUploadError);
        if (!this.stopped && !this.finishing && (!failure?.status || failure.status >= 500 || failure.status === 408 || failure.status === 429)) {
          this.clearRetry();
          this.retryTimer = setTimeout(() => {
            this.retryTimer = null;
            void this.retryUploads().catch(() => {});
          }, this.retryDelay);
          this.retryDelay = Math.min(30000, this.retryDelay * 2);
        }
        throw error;
      }
    })();
    this.draining = work.finally(() => { this.draining = null; });
    return this.draining;
  }
  private detach() {
    for (const capture of this.captures.values()) { capture.node.onaudioprocess = null; capture.source.disconnect(); capture.node.disconnect(); capture.silent.disconnect(); }
    this.captures.clear();
    if (this.context) { void this.context.close(); this.context = null; }
  }
  async finish() {
    this.finishing = true;
    this.clearRetry();
    this.report('uploading');
    for (const capture of this.captures.values()) capture.flush();
    // Freeze capture before waiting for HTTP: no final segment may arrive after end.
    this.detach();
    // A failed upload remains queued with the same chunkId for the next attempt.
    if (this.draining) await this.draining.catch(() => {});
    try {
      await this.drain();
      this.stopped = true; this.report('stopped');
    } catch (error) {
      this.pausedForBacklog = true;
      throw error;
    } finally { this.finishing = false; }
  }
  dispose() { this.stopped = true; this.clearRetry(); this.detach(); }
}

export type RecordingStatus = { status: string; error: string | null; message: string | null; jobId: string | null };
export const getRecordingStatus = (meetingId: string) => invoke<RecordingStatus>('room_recording_status', { meetingId });
export const retryRecording = (meetingId: string) => invoke('room_recording_retry', { meetingId });
