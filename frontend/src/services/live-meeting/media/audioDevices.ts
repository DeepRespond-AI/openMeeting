export interface AudioPreferences {
  microphoneId: string;
  speakerId: string;
  autoJoin: boolean;
  unmuteSound: boolean;
}

const KEY = 'openmeeting:meeting-audio';
const defaults: AudioPreferences = { microphoneId: 'default', speakerId: 'default', autoJoin: false, unmuteSound: false };

export class AudioDeviceError extends Error {
  constructor(readonly reason: 'sdkReloadRequired' | 'mediaNotReady') {
    super(reason);
    this.name = 'AudioDeviceError';
  }
}

/** Keep SDK/version failures distinct from operating-system device permissions. */
export function microphoneErrorMessage(error: unknown):
  'sdkReloadRequired' | 'mediaNotReady' | 'permissionDenied' | 'inputMissing' | 'inputBusy' | 'inputUnsupported' | 'inputSwitchFailed' {
  if (error instanceof AudioDeviceError) return error.reason;
  if (typeof error !== 'object' || error === null) return 'inputSwitchFailed';
  const e = error as { name?: string; code?: string; reason?: string; details?: { reason?: string } };
  const reason = e.reason ?? e.details?.reason;
  if (reason === 'media_not_connected' || e.code === 'aborted') return 'mediaNotReady';
  if (e.code === 'unsupported') return 'inputUnsupported';
  if (e.name === 'NotAllowedError' || e.code === 'permission_denied') return 'permissionDenied';
  if (e.name === 'NotFoundError' || e.name === 'OverconstrainedError') return 'inputMissing';
  if (e.name === 'NotReadableError' || e.name === 'AbortError') return 'inputBusy';
  return 'inputSwitchFailed';
}

export function readAudioPreferences(): AudioPreferences {
  try {
    const value = JSON.parse(localStorage.getItem(KEY) || '{}');
    return {
      microphoneId: typeof value.microphoneId === 'string' && value.microphoneId ? value.microphoneId : 'default',
      speakerId: typeof value.speakerId === 'string' && value.speakerId ? value.speakerId : 'default',
      autoJoin: value.autoJoin === true,
      unmuteSound: value.unmuteSound === true,
    };
  } catch { return { ...defaults }; }
}

export function saveAudioPreferences(patch: Partial<AudioPreferences>): AudioPreferences {
  const value = { ...readAudioPreferences(), ...patch };
  try { localStorage.setItem(KEY, JSON.stringify(value)); } catch { /* Preferences are optional. */ }
  return value;
}

export function supportsSpeakerSelection(): boolean {
  return typeof HTMLMediaElement !== 'undefined' && 'setSinkId' in HTMLMediaElement.prototype;
}

export async function routeAudio(element: HTMLMediaElement, deviceId: string): Promise<void> {
  const sink = element as HTMLMediaElement & { setSinkId?: (id: string) => Promise<void> };
  if (!sink.setSinkId) {
    if (deviceId && deviceId !== 'default') throw new Error('speakerUnsupported');
    return;
  }
  await sink.setSinkId(deviceId === 'default' ? '' : deviceId);
}

/** A short, locally generated chime; never sent to the meeting or microphone. */
export function createSpeakerTest(): { audio: HTMLAudioElement; dispose: () => void } {
  const rate = 24000, duration = 2, samples = rate * duration;
  const buffer = new ArrayBuffer(44 + samples * 2);
  const view = new DataView(buffer);
  const ascii = (offset: number, value: string) => [...value].forEach((char, i) => view.setUint8(offset + i, char.charCodeAt(0)));
  ascii(0, 'RIFF'); view.setUint32(4, 36 + samples * 2, true); ascii(8, 'WAVE');
  ascii(12, 'fmt '); view.setUint32(16, 16, true); view.setUint16(20, 1, true); view.setUint16(22, 1, true);
  view.setUint32(24, rate, true); view.setUint32(28, rate * 2, true); view.setUint16(32, 2, true); view.setUint16(34, 16, true);
  ascii(36, 'data'); view.setUint32(40, samples * 2, true);
  for (let i = 0; i < samples; i++) {
    const time = i / rate, beat = time % 0.5;
    const envelope = Math.min(1, beat / 0.02) * Math.max(0, 1 - beat / 0.42);
    const note = [523.25, 659.25, 783.99, 659.25][Math.floor(time / 0.5)];
    view.setInt16(44 + i * 2, Math.sin(2 * Math.PI * note * time) * envelope * 0.2 * 32767, true);
  }
  const url = URL.createObjectURL(new Blob([buffer], { type: 'audio/wav' }));
  const audio = new Audio(url);
  audio.loop = true;
  return { audio, dispose: () => { audio.pause(); audio.removeAttribute('src'); audio.load(); URL.revokeObjectURL(url); } };
}
