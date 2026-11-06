import type {ChannelHandle, ChannelTrack} from '@deeprespond/im-web';
import type {LiveMeetingApi} from '../api';
import type {LiveRoom, Participant} from '../types';
import type {MediaTrack} from './types';

export type ScreenReason = 'denied'|'unsupported'|'network'|'replaced'|'publishDenied';
export interface ScreenState {
  status: 'idle'|'choosing'|'sharing'|'connecting'|'viewing'|'error';
  tracks: MediaTrack[];
  reason?: ScreenReason;
  ownerName?: string;
  viewers: number;
}

/** Business ownership and capture only; the authenticated IM SDK owns media transport. */
export class ScreenShareClient {
  private state:ScreenState={status:'idle',tracks:[],viewers:0};
  private listeners=new Set<(state:ScreenState)=>void>();
  private context:{api:LiveMeetingApi;roomId:string;selfId:string}|null=null;
  private channel:ChannelHandle|null=null;
  private connected=false;
  private owner:Participant|undefined;
  private stream:MediaStream|null=null;
  private session:string|null=null;
  private generation=0;
  private ownershipRevision=0;
  private tracks=new Map<MediaStreamTrack,ChannelTrack>();
  private stopping:Promise<void>=Promise.resolve();
  private timer:ReturnType<typeof setTimeout>|null=null;
  subscribe(fn:(state:ScreenState)=>void){this.listeners.add(fn);fn(this.state);return()=>{this.listeners.delete(fn);};}
  private update(patch:Partial<ScreenState>){this.state={...this.state,...patch};for(const fn of this.listeners)fn(this.state);}
  bind(api:LiveMeetingApi,roomId:string,selfId:string){
    if(this.context?.roomId===roomId&&this.context.selfId===selfId)return;
    if(this.context)void this.stop().catch(()=>{});
    this.context={api,roomId,selfId};this.owner=undefined;
  }
  setChannel(channel:ChannelHandle|null,connected=false){
    if(this.channel!==channel)this.tracks.clear();
    this.channel=channel;this.setConnection(connected);
  }
  setConnection(connected:boolean){this.connected=connected;this.render();}
  acceptTrack(track:ChannelTrack,removed=false){
    if(track.source!=='screen')return;
    if(removed)this.tracks.delete(track.track);else this.tracks.set(track.track,track);
    this.render();
  }
  sync(room:LiveRoom){
    if(room.id!==this.context?.roomId)return;
    const previous=this.owner;
    this.owner=room.participants.find(p=>p.screenSharing&&p.screenShareId);
    if(previous?.screenShareId!==this.owner?.screenShareId)++this.ownershipRevision;
    if(this.session&&this.owner?.screenShareId!==this.session){
      ++this.generation;this.session=null;this.stopLocal();
      this.update({status:'idle',tracks:[],reason:this.owner?'replaced':undefined,viewers:0});
    }
    if(previous?.screenShareId!==this.owner?.screenShareId)this.clearTimer();
    this.render();
  }
  private clearTimer(){if(this.timer)clearTimeout(this.timer);this.timer=null;}
  private render(){
    const c=this.context,owner=this.owner;
    if(!c||this.state.status==='choosing')return;
    if(this.session){
      this.clearTimer();
      this.update({status:this.connected?'sharing':'connecting',reason:this.connected?undefined:'network',ownerName:owner?.name});return;
    }
    if(!owner||owner.id===c.selfId){
      this.clearTimer();
      if(this.state.status==='viewing'||this.state.status==='connecting'||this.state.ownerName)this.update({status:'idle',tracks:[],ownerName:undefined,reason:undefined});
      return;
    }
    const item=[...this.tracks.values()].find(t=>!t.local&&t.username===(owner.userId||owner.id)&&t.publicationName===`screen:${owner.screenShareId}`&&t.track.readyState==='live');
    const tracks:MediaTrack[]=item?[{key:`screen:${owner.screenShareId}:${item.track.id}`,username:item.username,kind:'video',track:item.track,local:false,source:'screen'}]:[];
    if(item&&this.connected){this.clearTimer();this.update({status:'viewing',tracks,ownerName:owner.name,reason:undefined});}
    else {
      this.update({status:this.state.status==='error'?'error':'connecting',tracks:[],ownerName:owner.name});
      if(!this.timer)this.timer=setTimeout(()=>{this.timer=null;if(this.owner?.screenShareId===owner.screenShareId&&this.owner?.id===owner.id)this.update({status:'error',tracks:[],ownerName:owner.name,reason:'network'});},12000);
    }
  }
  async retry(){
    const c=this.context,handle=this.channel;if(!c||!handle)return;
    this.clearTimer();this.update({status:'connecting',reason:undefined,tracks:[]});
    try{await handle.refresh();const room=await c.api.getRoom(c.roomId);if(this.context===c)this.sync(room);}
    catch{if(this.context===c)this.update({status:'error',reason:'network'});}
  }
  async start(){
    const c=this.context,handle=this.channel;
    if(!c||!c.api.startScreenShare)return;
    if(this.state.status==='choosing'||this.session)return;
    if(!handle||!this.connected){this.update({status:'error',reason:'network'});return;}
    if(typeof handle.publishScreenTrack!=='function'||typeof handle.stopScreenShare!=='function'||!navigator.mediaDevices?.getDisplayMedia){this.update({status:'error',reason:'unsupported'});return;}
    const generation=++this.generation;
    this.update({status:'choosing',reason:undefined,tracks:[]});
    let stream:MediaStream|null=null,claimed:string|null=null;
    const current=()=>generation===this.generation&&c===this.context&&handle===this.channel;
    try{
      // Capture must start in the click's user activation, before network awaits.
      stream=await navigator.mediaDevices.getDisplayMedia({video:{frameRate:15,width:{ideal:1920},height:{ideal:1080}},audio:false});
      await this.stopping;
      if(!current()){stream.getTracks().forEach(t=>t.stop());return;}
      const track=stream.getVideoTracks()[0];if(!track||track.readyState==='ended')throw Error('Capture ended');
      this.stream=stream;
      track.addEventListener('ended',()=>{if(current())void this.stop().catch(()=>{});},{once:true});
      claimed=(await c.api.startScreenShare(c.roomId)).sessionId;
      const revision=this.ownershipRevision;
      const room=await c.api.getRoom(c.roomId),owner=room.participants.find(p=>p.screenSharing);
      if(!current()||owner?.id!==c.selfId||owner.screenShareId!==claimed||(revision!==this.ownershipRevision&&this.owner?.screenShareId!==claimed)||(track as MediaStreamTrack).readyState==='ended'){
        stream.getTracks().forEach(t=>t.stop());await c.api.stopScreenShare?.(c.roomId,claimed);
        if(current())this.update({status:'idle',reason:'replaced',tracks:[]});return;
      }
      this.owner=owner;this.session=claimed;
      await handle.publishScreenTrack(track,{name:`screen:${claimed}`});
      if(!current())return;
      if(track.readyState!=='live')throw Error('Capture ended');
      this.clearTimer();this.update({status:'sharing',reason:undefined,ownerName:owner.name,tracks:[{key:`screen:${claimed}`,username:owner.userId||owner.id,kind:'video',track,local:true,source:'screen'}],viewers:0});
    }catch(error){
      stream?.getTracks().forEach(t=>t.stop());
      if(current()){
        const failure=error as {code?:string;name?:string;status?:number};
        this.session=null;this.stopLocal();
        this.update({status:'error',tracks:[],ownerName:undefined,reason:error instanceof DOMException&&['NotAllowedError','AbortError','SecurityError'].includes(error.name)?'denied':failure?.name==='PublishTrackError'&&failure.status===403||failure?.code==='permission_denied'?'publishDenied':failure?.code==='unsupported'?'unsupported':'network'});
        if(!claimed){const reason=this.state.reason;this.render();if(this.state.status==='viewing')this.update({reason});}
      }
      if(claimed)await c.api.stopScreenShare?.(c.roomId,claimed).catch(()=>{});
    }
  }
  private stopLocal(){
    this.stream?.getTracks().forEach(t=>t.stop());this.stream=null;
    const channel=this.channel;
    this.stopping=channel?.stopScreenShare?.().catch(()=>{})||Promise.resolve();
  }
  async stop(){
    const generation=++this.generation,c=this.context,session=this.session;this.session=null;
    this.clearTimer();this.stopLocal();this.update({status:'idle',tracks:[],reason:undefined,ownerName:undefined,viewers:0});
    await this.stopping;
    if(!session)this.render();
    if(c&&session){try{await c.api.stopScreenShare?.(c.roomId,session);}catch{if(generation===this.generation&&c===this.context)this.update({status:'error',reason:'network'});throw Error('Could not synchronize screen sharing stop');}}
  }
  async close(){const stopping=this.stop();this.context=null;this.owner=undefined;this.tracks.clear();await stopping.catch(()=>{});}
}
