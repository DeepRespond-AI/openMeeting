import {livekitProvider} from '../../../frontend/node_modules/@deeprespond/im-web/dist/index.js';
import {ImChannelMediaClient as ProductionMedia} from '../../../frontend/src/services/live-meeting/media/imChannel';
import {withScreenFailures} from './im-rtc-screen-failures.mjs';

/** Explicit local SFU fixture: real patched SDK media provider, substituted IM control plane. */
export class ImChannelMediaClient extends ProductionMedia {
  async connect() {
    const f=(window as any).__shareFixture;
    const media=await fetch(`${(window as any).__rtcBackend}/local-rtc?session=${f.session}`).then(r=>r.json());
    const channels:any={supported:true,getCurrentSession:async()=>null,join:async()=>{
      const session=await livekitProvider().connect(media,{media:'video'});
      const handle:any={session_id:f.session,channel_id:'local-screen-test',getSnapshot:()=>({media_state:'connected'}),refresh:async()=>{},leave:()=>session.disconnect(),setMicrophoneDevice:(id:string)=>session.setMicrophoneDevice!(id),setMicrophoneEnabled:(on:boolean)=>session.setMicrophoneEnabled(on),setCameraEnabled:(on:boolean)=>session.setCameraEnabled(on),publishScreenTrack:(track:MediaStreamTrack,options:{name:string})=>session.publishScreenTrack!(track,options),stopScreenShare:()=>session.stopScreenShare!(),on:(event:string,listener:any)=>{
        if(event==='track'||event==='trackRemoved')return session.on(event,p=>listener({...p,session_id:p.identity,username:p.identity?.replace('rtcchs_','')}));
        if(event==='connectionChanged')return session.on('state',listener);
        return ()=>{};
      }};
      const camera=handle.setCameraEnabled;
      handle.setCameraEnabled=async(on:boolean)=>{try{await camera(on);}catch(error){const e=error as Error;f.cameraError={name:e.name,message:e.message,stack:e.stack};throw error;}};
      return withScreenFailures(handle,f);
    }};
    f.media=this;this.subscribe(s=>f.mediaState={status:s.status,reason:s.reason});
    await super.connect({transport:'dr-rtc',channelId:'local-screen-test',ticket:'local-fixture',expiresAt:'2099-01-01T00:00:00Z'},channels);
  }
}
