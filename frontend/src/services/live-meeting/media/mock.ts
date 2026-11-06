/**
 * MockMediaClient — state flips only, zero device access (plan §5.3).
 * Tiles render gradient avatars per the design mockup, so nothing here touches
 * getUserMedia. The screen-share flag is purely informational; room state flows
 * through LiveMeetingApi.updateSelf.
 */
import type { MediaClient,MediaState } from './types';

export class MockMediaClient implements MediaClient {
  private micOn = true;
  private camOn = true;
  private sharing = false;
  private speakerOn = true;
  private microphoneDeviceId = 'default';
  private speakerDeviceId = 'default';
  private listeners=new Set<(state:MediaState)=>void>();
  private emit() { for (const listener of this.listeners) listener({status:'idle',tracks:[],speakerEnabled:this.speakerOn,microphoneDeviceId:this.microphoneDeviceId,speakerDeviceId:this.speakerDeviceId}); }
  subscribe(listener:(state:MediaState)=>void){this.listeners.add(listener);this.emit();return()=>{this.listeners.delete(listener);};}

  async setMicEnabled(on: boolean): Promise<void> {
    this.micOn = on;
  }

  async setCamEnabled(on: boolean): Promise<void> {
    this.camOn = on;
  }

  async startScreenShare(): Promise<void> {
    this.sharing = true;
  }

  async stopScreenShare(): Promise<void> {
    this.sharing = false;
  }

  async setSpeakerEnabled(on: boolean): Promise<void> {
    this.speakerOn = on;
    this.emit();
  }
  async setMicrophoneDevice(deviceId: string) { this.microphoneDeviceId = deviceId; this.emit(); }
  async setSpeakerDevice(deviceId: string) { this.speakerDeviceId = deviceId; this.emit(); }

  isSharing(): boolean {
    return this.sharing;
  }

  async leave(): Promise<void> {
    this.sharing = false;
  }
}
