import config from './meeting-ui.json';

/** Client build configuration. Server authorization remains authoritative. */
export interface MeetingUiConfig {
  audio: boolean;
  video: boolean;
  chat: boolean;
  screenShare: boolean;
  members: boolean;
  handRaise: boolean;
  recording: boolean;
  settings: boolean;
}

// Keep one source of truth; malformed/missing fields fail type checking.
export const meetingUi: Readonly<MeetingUiConfig> = Object.freeze({
  ...config satisfies MeetingUiConfig,
  // Meeting recording consumes meeting audio tracks.
  recording: config.recording && config.audio,
});
