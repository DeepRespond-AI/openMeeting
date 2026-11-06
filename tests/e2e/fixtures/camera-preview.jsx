// Browser-only boundaries for the production RoomProvider, RoomScreen and SDK.
// No real accounts, business data or device permissions are consumed.
import React from 'react';
import {createRoot} from 'react-dom/client';
import {Toaster} from 'sonner';
import messages from '../../../frontend/src/i18n/messages/liveMeeting';
import {TOAST_DURATION_MS} from '../../../frontend/src/lib/toast';
import {livekitProvider} from '@deeprespond/im-web';
import {ImChannelMediaClient} from '../../../frontend/src/services/live-meeting/media/imChannel';
import {RoomProvider,useRoom} from '../../../frontend/src/components/live-meeting/room/RoomProvider';
import RoomScreen from '../../../frontend/src/components/live-meeting/room/RoomScreen';
import {MeetingEntryProvider,useMeetingEntry} from '../../../frontend/src/components/live-meeting/MeetingEntry';
import {installMeetingFixture} from './meeting-im-sdk.mjs';

export const JOIN_INTENT_KEY='camera-fixture-join';
const translate=(key,vars={})=>{
  let text=key.startsWith('liveMeeting.')?key.slice(12).split('.').reduce((value,k)=>value?.[k],messages['zh-CN']):({'common.actions.close':'关闭','meeting.page.loading':'加载中…','common.actions.back':'返回'})[key];
  if(typeof text!=='string')text=key;
  return text.replace(/\{(\w+)\}/g,(_,name)=>String(vars[name]??name));
};
export const useT=()=>translate;
export const useI18n=()=>({t:translate,locale:'zh-CN'});
// The integrated room grid also uses the non-hook translator for clipboard errors.
export const t=translate;
const router={push:()=>{}},search=new URLSearchParams('code=123456');
export const useRouter=()=>router,useSearchParams=()=>search;
export const usePathname=()=>'/room';
export const useServer=()=>({user:{id:'self',name:'测试主持人'},loggedIn:true});
const self={id:'self',userId:'self',name:'测试主持人',isSelf:true,isHost:true,micOn:false,camOn:false,handRaised:false,screenSharing:false,joinedAt:new Date().toISOString()};
const remote={...self,id:'remote',userId:'remote',name:'远端参会者（长名称响应式检查）',isSelf:false,isHost:false};
const room={id:'camera-fixture',code:'123456',title:'摄像头反复开关回归',hostId:'self',status:'active',participants:[self,remote],waiting:[],startedAt:null,pwdEnabled:false,waitRoom:false};
const config={transport:'dr-rtc',channelId:'fixture',ticket:'fixture',expiresAt:new Date(Date.now()+3600000).toISOString()};
let session;
const eventListeners=new Set();
const events=new Map();
const handle={
  leave:async()=>{await session?.disconnect?.();},getSnapshot:()=>({media_state:'connected'}),
  on:(event,fn)=>{if(!events.has(event))events.set(event,new Set());events.get(event).add(fn);return()=>events.get(event).delete(fn);},
  setCameraEnabled:on=>session.setCameraEnabled(on),setMicrophoneEnabled:async()=>{},
};
const emit=(event,item)=>events.get(event)?.forEach(fn=>fn(item));
const channels={supported:true,getCurrentSession:async()=>null,join:async()=>{
  session=await livekitProvider().connect({url:'wss://fixture',token:'fixture'},{media:'video'});
  for(const event of ['track','trackRemoved'])session.on(event,item=>emit(event,{...item,session_id:'local-session',username:'self'}));
  return handle;
}};
const client={channels,conversations:{},messages:{}};
installMeetingFixture(client,()=>window.cameraFixture);
client.auth.currentUser.username='self';
const im={client,status:'ready',relogin:()=>{}};
export const useIm=()=>im;
const media=new ImChannelMediaClient();
export const getMediaClient=()=>media,getLiveMeetingDataSource=()=> 'real';
export class LiveMeetingApiError extends Error {}
let finishJoin;
const joinGate=new Promise(resolve=>finishJoin=resolve);
const api={
  joinRoom:async()=>{await joinGate;return{state:'joined',room:structuredClone(room),self:structuredClone(self),media:config};},
  onRoomEvent:fn=>{eventListeners.add(fn);return()=>eventListeners.delete(fn);},
  listChat:async()=>({messages:[],hasMore:false}),
  getChatSession:async()=>({groupId:'camera-fixture-group'}),
  // Deliberately omit signalling echoes: HTTP success must update the tile too.
  updateSelf:async(_id,patch)=>{Object.assign(self,patch);window.cameraFixture.operations.push({action:'updateSelf',patch});},
  disconnectRoom:async()=>{},getRoomMedia:async()=>config,
  getRoom:async()=>structuredClone(room),
};
export const getLiveMeetingApi=()=>api;
window.cameraFixture={operations:[],deny:false,releaseJoin:()=>finishJoin(),snapshot:null};
let serial=0;
class Room{
  constructor(){
    this.events=new Map();
    const createCamera=async()=>{
      window.cameraFixture.operations.push({action:'capture',on:true});
      if(window.cameraFixture.deny)throw new DOMException('Permission denied','NotAllowedError');
      const canvas=document.createElement('canvas');canvas.width=640;canvas.height=360;
      const ctx=canvas.getContext('2d'),capture=++serial;let frame=0;
      const draw=()=>{ctx.fillStyle='#146c94';ctx.fillRect(0,0,640,360);ctx.fillStyle='#fff';ctx.font='26px sans-serif';ctx.fillText(`Camera ${capture} / frame ${++frame}`,32,160);};
      draw();const timer=setInterval(draw,50),track=canvas.captureStream(20).getVideoTracks()[0],stop=track.stop.bind(track);
      track.stop=()=>{clearInterval(timer);stop();};
      return {kind:'video',mediaStreamTrack:track,stop:()=>track.stop()};
    };
    this.localParticipant={identity:'self',videoTrackPublications:new Map(),
      createTracks:async()=>[await createCamera()],
      publishTrack:async(track,options)=>{
        const publication={kind:'video',source:options.source,trackName:options.name,track,
          mute:async()=>publication.track.stop(),
          unmute:async()=>{publication.track=await createCamera();}};
        this.localParticipant.videoTrackPublications.set(options.name,publication);
        this.events.get('published')?.(publication);return publication;
      },
      unpublishTrack:async track=>{track.stop();for(const [key,pub] of this.localParticipant.videoTrackPublications)if(pub.track===track)this.localParticipant.videoTrackPublications.delete(key);},
    };
  }
  on(name,fn){this.events.set(name,fn);return this;}
  async connect(){} async disconnect(){for(const pub of this.localParticipant.videoTrackPublications.values())pub.track.mediaStreamTrack.stop();}
}
window.LivekitClient={Room,RoomEvent:{LocalTrackPublished:'published'},Track:{Kind:{Video:'video'},Source:{Camera:'camera',ScreenShare:'screen_share'}},DisconnectReason:{}};
function Probe(){
  const value=useRoom();const {beginEntry,finishEntry}=useMeetingEntry();
  // The isolated room omits MeetingSession; bridge its global overlay to actual room readiness.
  React.useEffect(()=>{if(value.phase==='joining'||(value.phase==='joined'&&value.entryStatus==='loading'))beginEntry();else finishEntry();},[value.phase,value.entryStatus,beginEntry,finishEntry]);
  window.cameraFixture.snapshot={phase:value.phase,self:value.self,participants:value.room?.participants,tracks:value.mediaState.tracks.map(item=>({id:item.track.id,readyState:item.track.readyState,local:item.local})),mediaDeviceError:value.mediaDeviceError};return null;
}
createRoot(document.getElementById('root')).render(<MeetingEntryProvider><RoomProvider><Probe/><RoomScreen/><Toaster position="top-center" duration={TOAST_DURATION_MS} richColors closeButton toastOptions={{className:'rounded-xl font-sans'}}/></RoomProvider></MeetingEntryProvider>);
