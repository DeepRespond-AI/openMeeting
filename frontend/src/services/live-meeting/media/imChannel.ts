/** UI-window media only. The hidden IM engine continues to own authentication. */
import type { ChannelHandle, ChannelsApi, ChannelTrack } from '@deeprespond/im-web';
import type { RoomMediaConfig } from '../types';
import type { MediaClient, MediaState, MediaTrack } from './types';
import {ScreenShareClient} from './screenShare';
import {RtcTelemetry} from './rtcTelemetry';
import { AudioDeviceError, readAudioPreferences, routeAudio } from './audioDevices';
import { MediaReleaseTimeout, rtcWait } from './recovery';

export class ImChannelMediaClient implements MediaClient {
  readonly screen=new ScreenShareClient();
  private telemetry=new RtcTelemetry();
  private handle: ChannelHandle | null = null;
  private generation = 0;
  private joinAbort: AbortController | null = null;
  private pendingAttach: Promise<ChannelHandle> | null = null;
  private releaseTask: Promise<void> = Promise.resolve();
  private offs: (() => void)[] = [];
  private listeners = new Set<(state: MediaState) => void>();
  private state: MediaState = {status:'idle',tracks:[],speakerEnabled:true,speakerDeviceId:'default'};
  private microphoneId = readAudioPreferences().microphoneId;

  subscribe(listener: (state: MediaState) => void) {
    this.listeners.add(listener); listener(this.state);
    return () => { this.listeners.delete(listener); };
  }
  private update(patch: Partial<MediaState>) {
    this.state={...this.state,...patch};
    for (const listener of this.listeners) listener(this.state);
  }
  async connect(config: RoomMediaConfig, channels: ChannelsApi | null) {
    const generation=this.generation+1;
    await this.leave(true);
    if(generation!==this.generation)return;
    if(config.transport!=='dr-rtc') { this.update({status:'unavailable',reason:'unavailable'});return; }
    if(!channels) { this.update({status:'unavailable',reason:'loginRequired'});return; }
    if(!channels.supported) { this.update({status:'unavailable',reason:'unsupported'});return; }
    this.update({status:'connecting',reason:undefined});
    this.telemetry.start(()=>this.state.tracks,(activeSpeakerUsername,network)=>this.update(this.state.status==='connected'?{activeSpeakerUsername,network}:{activeSpeakerUsername:null,network:{}}));
    try {
      const abort = new AbortController();
      this.joinAbort = abort;
      const releaseDeadline = Date.now() + 15_000;
      let existing = await rtcWait(channels.getCurrentSession(), abort.signal, releaseDeadline);
      while (existing?.status === 'leaving' && generation === this.generation) {
        this.update({status:'connecting',reason:'sessionReleasing',
          releasingSessionId:existing.channel_id===config.channelId?existing.session_id:undefined});
        if (Date.now() >= releaseDeadline) {
          this.telemetry.stop();
          this.update({status:'error',reason:'sessionReleaseTimeout',tracks:[]});
          return;
        }
        await new Promise<void>(resolve => {
          const done = () => { clearTimeout(timer); abort.signal.removeEventListener('abort',done); resolve(); };
          const timer = setTimeout(done,400);
          abort.signal.addEventListener('abort',done,{once:true});
          if (abort.signal.aborted) done();
        });
        if (generation !== this.generation) return;
        existing = await rtcWait(channels.getCurrentSession(), abort.signal, releaseDeadline);
      }
      if (generation !== this.generation) return;
      this.update({reason:undefined,releasingSessionId:undefined});
      // DeepRespond owns media reconnect/heartbeat. Resume a valid session
      // instead of reserving a second seat or consuming another one-use ticket.
      const resumable = existing && ['joining','joined'].includes(existing.status);
      if (existing && existing.status !== 'left' && (!resumable || existing.channel_id !== config.channelId)) {
        this.telemetry.stop();
        this.update({status:'error',reason:'sessionConflict',tracks:[]});
        return;
      }
      if (!resumable && Date.parse(config.expiresAt)<=Date.now()) throw new Error('Expired media authorization');
      const attaching = resumable && existing
        ? channels.resume({channel_id:existing.channel_id,session_id:existing.session_id,signal:abort.signal})
        : channels.join(config.channelId,{ticket:config.ticket,signal:abort.signal,microphoneEnabled:false,cameraEnabled:false});
      this.pendingAttach = attaching;
      let handle: ChannelHandle;
      try { handle = await attaching; }
      finally { if (this.pendingAttach === attaching) this.pendingAttach = null; }
      if(generation!==this.generation) {await handle.leave();return;}
      this.handle=handle;
      this.screen.setChannel(handle,handle.getSnapshot().media_state==='connected');
      const key=(track:ChannelTrack)=>`${track.session_id}:${track.kind}:${track.track.id}`;
      this.offs.push(handle.on('track',track=>{
        if(generation!==this.generation)return;
        if(track.source==='screen'){this.screen.acceptTrack(track);return;}
        const item:MediaTrack={key:key(track),username:track.username,kind:track.kind,track:track.track,local:track.local};
        this.update({tracks:[...this.state.tracks.filter(t=>t.key!==item.key),item]});
      }));
      this.offs.push(handle.on('trackRemoved',track=>{
        if(generation===this.generation&&track.source==='screen'){this.screen.acceptTrack(track,true);return;}
        if(generation===this.generation)this.update({tracks:this.state.tracks.filter(t=>t.key!==key(track))});
      }));
      this.offs.push(handle.on('connectionChanged',state=>{
        if(generation!==this.generation)return;
        this.screen.setConnection(state==='connected');
        this.update(state==='connected'?{status:'connected',reason:this.state.reason==='restored'?'restored':undefined}:
          state==='disconnected'?{status:'error',reason:'connectionFailed'}:{status:'connecting'});
      }));
      for(const event of ['channelClosed','sessionLeft'] as const)this.offs.push(handle.on(event,()=>{
        if(generation===this.generation){
          ++this.generation;this.joinAbort?.abort();this.joinAbort=null;
          this.offs.splice(0).forEach(off=>off());this.handle=null;
          this.telemetry.stop();this.stopTracks();
          void this.screen.close();this.screen.setChannel(null);
          this.update({status:'error',reason:event==='channelClosed'?'channelClosed':'sessionEnded',tracks:[],activeSpeakerUsername:null,network:{}});
        }
      }));
      const snapshot=handle.getSnapshot();
      this.update({status:snapshot.media_state==='connected'?'connected':'connecting',reason:resumable?'restored':undefined});
    } catch (error) {
      if(generation===this.generation)this.telemetry.stop();
      const code = typeof error==='object' && error!==null && 'code' in error ? String(error.code) : '';
      const status = typeof error==='object' && error!==null && 'status' in error ? Number(error.status) : undefined;
      const details = typeof error==='object' && error!==null && 'details' in error ? error.details : undefined;
      const reasonCode = typeof error==='object' && error!==null && 'reason' in error ? error.reason
        : typeof details==='object' && details!==null && 'reason' in details ? details.reason : undefined;
      if(generation===this.generation)console.warn('[meeting RTC connection]',{code,status,reason:typeof error==='object'&&error!==null&&'reason' in error?error.reason:undefined});
      const reason = error instanceof MediaReleaseTimeout && this.state.reason==='sessionReleasing'?'sessionReleaseTimeout':
        code==='conflict' && reasonCode==='joined_on_other_device'?'joinedOnOtherDevice':code==='unsupported'?'unsupported':code==='unauthenticated'?'loginRequired':
        code==='forbidden'||status===403?'accessDenied':code==='permission_denied'?'permissionDenied':'connectionFailed';
      if(generation===this.generation)this.update({status:'error',reason,tracks:[]});
    }
  }
  private stopTracks() {for(const {track} of this.state.tracks)track.stop();}
  async setMicEnabled(on: boolean) {
    if(!this.handle){if(on)throw new Error('音视频尚未连接');return;}
    const handle=this.handle,generation=this.generation;
    if (on && this.microphoneId !== 'default') {
      if (typeof handle.setMicrophoneDevice !== 'function') throw new AudioDeviceError('sdkReloadRequired');
      await handle.setMicrophoneDevice(this.microphoneId);
    }
    await handle.setMicrophoneEnabled(on);
    if (on && generation === this.generation) this.update({ microphoneDeviceId: this.microphoneId });
    if(generation===this.generation && on && this.state.reason==='restored')this.update({reason:undefined});
    if(on&&generation!==this.generation)await handle.setMicrophoneEnabled(false).catch(()=>{});
  }
  async setCamEnabled(on: boolean) {
    if(!this.handle){if(on)throw new Error('音视频尚未连接');return;}
    const handle=this.handle,generation=this.generation;
    await handle.setCameraEnabled(on);
    if(generation===this.generation && on && this.state.reason==='restored')this.update({reason:undefined});
    if(on&&generation!==this.generation)await handle.setCameraEnabled(false).catch(()=>{});
  }
  async startScreenShare(): Promise<void> { await this.screen.start(); }
  async stopScreenShare() { await this.screen.stop(); }
  async setSpeakerEnabled(on: boolean) {this.update({speakerEnabled:on});}
  async setMicrophoneDevice(deviceId: string) {
    const handle = this.handle, generation = this.generation;
    if (!handle || this.state.status !== 'connected') throw new AudioDeviceError('mediaNotReady');
    if (deviceId === (this.state.microphoneDeviceId ?? 'default') && deviceId === this.microphoneId) return;
    if (typeof handle.setMicrophoneDevice !== 'function') throw new AudioDeviceError('sdkReloadRequired');
    await handle.setMicrophoneDevice(deviceId);
    if (generation !== this.generation) throw new AudioDeviceError('mediaNotReady');
    this.microphoneId = deviceId;
    this.update({ microphoneDeviceId: deviceId });
  }
  async setSpeakerDevice(deviceId: string) {
    const previous = this.state.speakerDeviceId ?? 'default';
    const elements = Array.from(document.querySelectorAll<HTMLAudioElement>('audio[data-media-track]'));
    // Validate even when no remote participant has published audio yet.
    const targets = elements.length ? elements : [document.createElement('audio')];
    const results = await Promise.allSettled(targets.map(element => routeAudio(element, deviceId)));
    const failure = results.find(result => result.status === 'rejected');
    if (failure?.status === 'rejected') {
      await Promise.allSettled(targets.map(element => routeAudio(element, previous)));
      throw failure.reason;
    }
    this.update({ speakerDeviceId: deviceId });
  }
  async leave(preserveScreenContext=false) {
    ++this.generation;
    if(preserveScreenContext)await this.screen.stop().catch(()=>{});else await this.screen.close();
    this.screen.setChannel(null);
    this.joinAbort?.abort();this.joinAbort=null;
    this.telemetry.stop();
    this.offs.splice(0).forEach(off=>off());
    this.stopTracks();
    const handle=this.handle;this.handle=null;
    const pending=this.pendingAttach;
    this.update({status:'idle',reason:undefined,releasingSessionId:undefined,tracks:[],activeSpeakerUsername:null,network:{}});
    // Repeated cleanup must still await the first close, including an SDK join
    // which settles after its AbortSignal. SDK handle.leave() is idempotent.
    this.releaseTask = this.releaseTask.then(async () => {
      if(handle) await handle.leave().catch(()=>{});
      if(pending) {
        const late = await pending.catch(()=>null);
        if(late) await late.leave().catch(()=>{});
      }
    });
    await this.releaseTask;
  }
}
