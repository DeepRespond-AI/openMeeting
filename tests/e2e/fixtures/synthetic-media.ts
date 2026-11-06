/** Development-only input fixture. HTTP, recording and postprocessing remain real. */
import type { MediaState, MediaClient } from '../../../frontend/src/services/live-meeting/media/types';
export class ImChannelMediaClient implements MediaClient {
  private state: MediaState = {status:'idle',tracks:[],speakerEnabled:true};
  private listeners = new Set<(state: MediaState) => void>();
  private context: AudioContext | null = null;
  subscribe(listener: (state: MediaState) => void) { this.listeners.add(listener); listener(this.state); return () => { this.listeners.delete(listener); }; }
  private update(patch: Partial<MediaState>) { this.state = {...this.state,...patch}; this.listeners.forEach(fn=>fn(this.state)); }
  async connect() {
    await this.leave();
    this.context = new AudioContext({sampleRate:16000}); await this.context.resume();
    const tracks = [440,880].map((frequency,i) => {
      const oscillator = this.context!.createOscillator(); oscillator.frequency.value=frequency;
      const gain=this.context!.createGain(); gain.gain.value=.15;
      const destination=this.context!.createMediaStreamDestination();
      oscillator.connect(gain); gain.connect(destination); oscillator.start();
      const track=destination.stream.getAudioTracks()[0];
      return {key:`fixture-${frequency}`,username:i?sessionStorage.getItem('e2e-member-id'):null,kind:'audio' as const,track,local:i===0};
    });
    this.update({status:'connected',tracks});
  }
  async setMicEnabled(on: boolean) { const local=this.state.tracks.find(t=>t.local); if(local)local.track.enabled=on; }
  async setCamEnabled() {}
  async startScreenShare() { throw new Error('夹具不提供屏幕共享'); }
  async stopScreenShare() {}
  async setSpeakerEnabled(on: boolean) { this.update({speakerEnabled:on}); }
  async leave() { for(const t of this.state.tracks)t.track.stop(); if(this.context){await this.context.close();this.context=null;} this.update({status:'idle',tracks:[]}); }
}
