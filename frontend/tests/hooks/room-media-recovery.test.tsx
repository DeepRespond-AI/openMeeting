import React from 'react';
import { afterEach, expect, mock, test } from 'bun:test';
import { act, create } from 'react-test-renderer';
import type { LiveRoom, Participant, RoomMediaConfig } from '../../src/services/live-meeting/types';
import type { MediaState } from '../../src/services/live-meeting/media/types';

const t = (key: string) => key;
const self: Participant = {id:'seat',userId:'me',name:'Me',isSelf:true,isHost:false,
  micOn:false,camOn:false,mutedByHost:false,handRaised:false,screenSharing:false,joinedAt:'2026-10-30T00:00:00Z'};
const room: LiveRoom = {id:'room-original',code:'123456',title:'Room',hostId:'host',status:'active',
  scheduledMeetingId:null,pwdEnabled:false,waitRoom:false,startedAt:null,endedAt:null,
  meetingId:null,participants:[self],waiting:[]};
const config: RoomMediaConfig = {transport:'dr-rtc',channelId:room.id,ticket:'fixture',expiresAt:'2030-01-01T00:00:00Z'};
let events: string[] = [], chatOpens=0, chatDisposes=0, joins=0;
let release!: (result:{released:boolean}) => void;
let failRelease=false;
let emit: (state:MediaState) => void = () => {};
const imClient = {
  auth:{currentUser:{username:'me'}},config:{},on:()=>()=>{},channels:{},
  conversations:{refresh:async()=>({conversation_id:'chat',conversation_key:'chat'}),get:async()=>({unread_count:0})},
  messages:{open:()=>{chatOpens++;return{
    getSnapshot:()=>({items:[],loading:'none',hasOlder:false}),subscribe:()=>()=>{},
    setViewing:()=>{},markRead:()=>{},dispose:()=>{chatDisposes++;},
  };}},
};
const api = {
  joinRoom:async()=>{joins++;return {room:structuredClone(room),self:{...self},state:'joined',media:config};},
  onRoomEvent:()=>()=>{},getRoom:async()=>structuredClone(room),leaveRoom:async()=>{},updateSelf:async()=>{},
  getChatSession:async()=>({transport:'dr-im-group',groupId:'chat'}),
  recoverRoomMedia:async(roomId:string,sessionId:string)=>{
    events.push(`release:${roomId}:${sessionId}`);
    if(failRelease) throw new Error('Platform rejected release');
    return new Promise<{released:boolean}>(resolve=>{release=resolve;});
  },
  getRoomMedia:async(roomId:string)=>{events.push(`ticket:${roomId}`);return {...config,ticket:'replacement'};},
};
const media = {
  subscribe:(fn:(state:MediaState)=>void)=>{emit=fn;return()=>{};},
  connect:async(value:RoomMediaConfig)=>{events.push(`connect:${value.transport==='dr-rtc'?value.channelId:''}`);emit({status:'connected',tracks:[],speakerEnabled:true});},
  leave:async()=>{events.push('local-leave');emit({status:'idle',tracks:[],speakerEnabled:true});},
  setMicEnabled:async()=>{},setCamEnabled:async()=>{},setSpeakerEnabled:async()=>{},
};
const im = {client:imClient,status:'ready',relogin:()=>{}};
const router={push:()=>{},replace:()=>{}};
const search = new URLSearchParams('code=123456');
mock.module('next/navigation',()=>({useRouter:()=>router,useSearchParams:()=>search}));
mock.module('../../src/i18n',()=>({useT:()=>t}));
mock.module('sonner',()=>({toast:Object.assign(()=>{},{error:()=>{},success:()=>{}})}));
mock.module('../../src/contexts/ServerContext',()=>({useServer:()=>({user:{id:'me'}})}));
mock.module('../../src/contexts/IMContext',()=>({useIm:()=>im}));
mock.module('../../src/hooks/useAudioLevels',()=>({useAudioLevels:()=>({})}));
mock.module('../../src/components/live-meeting/JoinDialog',()=>({JOIN_INTENT_KEY:'join'}));
mock.module('../../src/services/live-meeting/recording',()=>({RoomRecorder:class{}}));
mock.module('../../src/services/live-meeting',()=>({getLiveMeetingApi:()=>api,getMediaClient:()=>media,
  getLiveMeetingDataSource:()=> 'real',LiveMeetingApiError:class extends Error{}}));
const {RoomProvider,useRoom}=await import('../../src/components/live-meeting/room/RoomProvider');
let root:ReturnType<typeof create>|undefined, current!:ReturnType<typeof useRoom>;
function Probe(){current=useRoom();return null;}
afterEach(async()=>{await act(async()=>root?.unmount());root=undefined;});
async function mount(){
  events=[];chatOpens=chatDisposes=joins=0;failRelease=false;
  await act(async()=>{root=create(<RoomProvider><Probe/></RoomProvider>);});
  await act(async()=>{emit({status:'error',reason:'sessionReleaseTimeout',releasingSessionId:'stale',tracks:[],speakerEnabled:true});});
  events=[];
}

test('explicit recovery rejoins the same RTC channel without recreating membership or chat',async()=>{
  await mount();
  let first!:Promise<void>;
  await act(async()=>{first=current.retryMedia();});
  expect(current.mediaRecovering).toBe(true);
  expect(events.filter(e=>e.startsWith('release:'))).toEqual(['release:room-original:stale']);
  expect(events.some(e=>e.startsWith('ticket:'))).toBe(false);
  await act(async()=>{await current.retryMedia();});
  expect(events.filter(e=>e.startsWith('release:')).length).toBe(1);
  await act(async()=>{release({released:true});await first;});
  expect(events.filter(e=>!e.startsWith('local-'))).toEqual(['release:room-original:stale','ticket:room-original','connect:room-original']);
  expect(current.mediaRecovering).toBe(false);
  expect(joins).toBe(1);expect(chatOpens).toBe(1);expect(chatDisposes).toBe(0);
  expect(current.room!.code).toBe('123456');
});

test('a platform refusal retains an actionable error and does not fetch a ticket',async()=>{
  await mount();failRelease=true;
  await act(async()=>{await current.retryMedia();});
  expect(current.mediaRecoveryError).toBe('Platform rejected release');
  expect(current.mediaState.releasingSessionId).toBe('stale');
  expect(current.mediaRecovering).toBe(false);
  expect(events.some(e=>e.startsWith('ticket:')||e.startsWith('connect:'))).toBe(false);
  expect(chatDisposes).toBe(0);
});

test('leaving during recovery cancels it and ignores late platform success',async()=>{
  await mount();let pending!:Promise<void>;
  await act(async()=>{pending=current.retryMedia();});
  await act(async()=>{await current.leave();await pending;});
  await act(async()=>{release({released:true});});
  expect(current.phase).toBe('ended');
  expect(events.some(e=>e.startsWith('ticket:')||e.startsWith('connect:'))).toBe(false);
});

test('an ordinary media failure uses ordinary retry without platform removal',async()=>{
  await mount();
  await act(async()=>{emit({status:'error',reason:'connectionFailed',tracks:[],speakerEnabled:true});});
  await act(async()=>{await current.retryMedia();});
  expect(events.some(e=>e.startsWith('release:'))).toBe(false);
  expect(events).toContain('ticket:room-original');
});
