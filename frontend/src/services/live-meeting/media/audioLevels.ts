import type { MediaTrack } from './types';

export type AudioLevels = Record<string, number>;

/** Relative signal strength, not a calibrated sound-pressure measurement. */
export function rmsToLevel(rms: number): number {
  if (!Number.isFinite(rms) || rms <= 0) return 0;
  return Math.min(1, Math.max(0, (20 * Math.log10(rms) + 50) / 50));
}

interface Entry {
  track: MediaStreamTrack;
  source: MediaStreamAudioSourceNode;
  analyser: AnalyserNode;
  samples: Float32Array<ArrayBuffer>;
  level: number;
}

/** Observe SDK-owned tracks without opening devices, playing audio or stopping tracks. */
export class AudioLevelMonitor {
  private context: AudioContext | null = null;
  private entries = new Map<string, Entry>();
  private timer: ReturnType<typeof setInterval> | null = null;
  private last: AudioLevels = {};
  private resume = () => {
    if (this.context?.state === 'suspended') void this.context.resume().catch(() => {});
  };

  start(tracks: () => MediaTrack[], emit: (levels: AudioLevels) => void) {
    this.stop();
    if (typeof window === 'undefined' || typeof window.AudioContext !== 'function') return;
    const sample = () => {
      try {
        const current = tracks().filter(t => t.kind === 'audio' && t.source !== 'screen' && t.track.readyState === 'live');
        const byKey = new Map(current.map(t => [t.key, t.track]));
        for (const [key, entry] of this.entries) {
          if (byKey.get(key) !== entry.track) {
            entry.source.disconnect(); entry.analyser.disconnect(); this.entries.delete(key);
          }
        }
        // A silent/muted room does not need a new audio context.
        if (!this.context && current.some(t => t.track.enabled && !t.track.muted)) {
          this.context = new window.AudioContext();
          this.resume();
        }
        const levels: AudioLevels = {};
        for (const item of current) {
          const track = item.track;
          let entry = this.entries.get(item.key);
          if (!entry && this.context && track.enabled && !track.muted) {
            try {
              const source = this.context.createMediaStreamSource(new MediaStream([track]));
              const analyser = this.context.createAnalyser();
              analyser.fftSize = 1024;
              source.connect(analyser); // No destination connection: never play local audio.
              entry = { track, source, analyser, samples: new Float32Array(analyser.fftSize), level: 0 };
              this.entries.set(item.key, entry);
            } catch { /* A disappearing/unsupported track must not affect the meeting. */ }
          }
          let level = 0;
          if (entry && track.enabled && !track.muted && this.context?.state === 'running') {
            entry.analyser.getFloatTimeDomainData(entry.samples);
            const rms = Math.sqrt(entry.samples.reduce((sum, value) => sum + value * value, 0) / entry.samples.length);
            const measured = rmsToLevel(rms);
            level = measured >= entry.level ? measured : measured * 0.45 + entry.level * 0.55;
            if (level < 0.02) level = 0;
          }
          if (entry) entry.level = level;
          levels[item.key] = Math.round(level * 100) / 100;
        }
        if (!current.length && this.context) {
          void this.context.close().catch(() => {}); this.context = null;
        }
        const keys = Object.keys(levels);
        if (keys.length !== Object.keys(this.last).length || keys.some(key => levels[key] !== this.last[key])) {
          this.last = levels; emit(levels);
        }
      } catch { /* Signal metering is optional; RTC capture remains owned by the SDK. */ }
    };
    window.addEventListener('pointerdown', this.resume);
    window.addEventListener('keydown', this.resume);
    sample();
    this.timer = setInterval(sample, 100);
  }

  stop() {
    if (this.timer) clearInterval(this.timer);
    this.timer = null;
    if (typeof window !== 'undefined') {
      window.removeEventListener('pointerdown', this.resume);
      window.removeEventListener('keydown', this.resume);
    }
    for (const entry of this.entries.values()) { entry.source.disconnect(); entry.analyser.disconnect(); }
    this.entries.clear();
    if (this.context) void this.context.close().catch(() => {});
    this.context = null;
    this.last = {};
  }
}
