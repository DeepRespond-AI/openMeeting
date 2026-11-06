/**
 * Media pipeline abstraction (plan §5.3). The mock client performs no device access —
 * tiles render gradient avatars per the design mockup — so the entire live-meeting UI is
 * developable without camera/mic permissions. ImChannelMediaClient connects to the
 * UI window's authenticated RTC channels and publishes MediaStreamTracks. Unavailable
 * platform capabilities degrade to controls/chat (server/P1_BACKEND_DESIGN.md §9).
 */

export type SignalQuality = 'good' | 'fair' | 'poor';
export interface NetworkSample { rttMs?:number; lossPercent?:number; sampledAt:number; }
export interface MediaTrack {
  key: string;
  username: string | null;
  kind: 'audio' | 'video';
  track: MediaStreamTrack;
  local: boolean;
  source?: 'screen';
}
export interface MediaState {
  status: 'idle' | 'connecting' | 'connected' | 'unavailable' | 'error';
  reason?: 'unavailable' | 'unsupported' | 'loginRequired' | 'connectionFailed' | 'permissionDenied'
    | 'joinedOnOtherDevice' | 'sessionConflict' | 'sessionReleasing' | 'sessionReleaseTimeout' | 'sessionEnded' | 'channelClosed' | 'restored' | 'accessDenied';
  tracks: MediaTrack[];
  speakerEnabled: boolean;
  microphoneDeviceId?: string;
  speakerDeviceId?: string;
  activeSpeakerUsername?: string | null;
  network?: Record<string,NetworkSample>;
  /** Only exposed for a leaving session in this exact meeting's channel. */
  releasingSessionId?: string;
}

export interface MediaClient {
  screen?: import('./screenShare').ScreenShareClient;
  connect?(config: import('../types').RoomMediaConfig, channels: import('@deeprespond/im-web').ChannelsApi | null): Promise<void>;
  subscribe?(listener: (state: MediaState) => void): () => void;
  setMicEnabled(on: boolean): Promise<void>;
  setCamEnabled(on: boolean): Promise<void>;
  /** Mock: flag only. Real: getDisplayMedia + authenticated IM RTC screen track. */
  startScreenShare(): Promise<void>;
  stopScreenShare(): Promise<void>;
  /** Toggle local speaker/mute for remote audio (no-op in mock). */
  setSpeakerEnabled(on: boolean): Promise<void>;
  setMicrophoneDevice?(deviceId: string): Promise<void>;
  setSpeakerDevice?(deviceId: string): Promise<void>;
  leave(): Promise<void>;
}
