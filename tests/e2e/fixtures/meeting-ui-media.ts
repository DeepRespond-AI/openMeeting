import { ImChannelMediaClient as BaseMedia } from './desktop-layout-media';
import { ScreenShareClient } from '../../../frontend/src/services/live-meeting/media/screenShare';

function record(operation: string, value?: boolean) {
  if (typeof window !== 'undefined') {
    const fixture = (window as any).__meetingUiMedia ||= { calls: [], denied: false };
    fixture.calls.push({ operation, value });
    if (fixture.denied && value && (operation === 'mic' || operation === 'camera')) {
      throw new DOMException('UI fixture permission denied', 'NotAllowedError');
    }
  }
}
/** Isolated SDK boundary, with actual production screen-sharing lifecycle. */
export class ImChannelMediaClient extends BaseMedia {
  readonly screen = new ScreenShareClient();
  async connect() { record('connect'); await super.connect(); }
  async setMicEnabled(on = false) { record('mic', on); }
  async setCamEnabled(on = false) { record('camera', on); }
  async setSpeakerEnabled(on: boolean) { record('speaker', on); await super.setSpeakerEnabled(on); }
  async startScreenShare() { record('share', true); await this.screen.start(); }
  async stopScreenShare() { record('share', false); await this.screen.stop(); }
}
