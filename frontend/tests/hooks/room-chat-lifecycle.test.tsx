import React from 'react';
import { afterEach, expect, mock, test } from 'bun:test';
import { act, create } from 'react-test-renderer';
import type { LiveRoom, Participant } from '../../src/services/live-meeting/types';

// Keep RoomProvider and ImMeetingChat real. Only business/SDK/media boundaries
// are fixtures; no chat panel is mounted to establish the subscription.
const t = (key: string) => key;
const participant: Participant = {id:'mobile-seat', userId:'mobile', name:'Member',
  isSelf:true, isHost:false, micOn:false, camOn:false, mutedByHost:false,
  handRaised:false, screenSharing:false, joinedAt:'2026-10-30T00:00:00Z'};
const room: LiveRoom = {id:'room-chat', code:'123456', title:'Room', hostId:'host',
  status:'active', scheduledMeetingId:null, pwdEnabled:false, waitRoom:false,
  startedAt:null, endedAt:null, meetingId:null, participants:[participant], waiting:[]};
let chatRequests = 0, opens = 0, active = 0, markReads = 0;
const items: any[] = [], listeners = new Set<() => void>(), viewing: boolean[] = [];
const imClient: any = {
  auth:{currentUser:{username:'mobile'}}, config:{}, on:()=>()=>{},
  conversations:{
    refresh:async()=>({conversation_id:'group-chat', conversation_key:'group-chat', unread_count:items.length}),
    get:async()=>({unread_count:items.length}), remove:async()=>{},
  },
  messages:{open:()=>{
    opens++; active++;
    return {
      getSnapshot:()=>({items:[...items],loading:'none',hasOlder:false}),
      subscribe:(fn:()=>void)=>{listeners.add(fn);return()=>{listeners.delete(fn);};},
      dispose:()=>{active--;}, setViewing:({visible}:{visible:boolean})=>{viewing.push(visible);},
      markRead:()=>{markReads++;},
    };
  }},
};
const api = {
  joinRoom:async()=>({room:structuredClone(room), self:{...participant}, state:'joined', media:{transport:'unavailable'}}),
  onRoomEvent:()=>()=>{}, getRoom:async()=>structuredClone(room), leaveRoom:async()=>{},
  getChatSession:async()=>{chatRequests++;return{transport:'dr-im-group', groupId:'group-chat'};},
  updateSelf:async()=>{},
};
const media = {subscribe:()=>()=>{},leave:async()=>{}, setMicEnabled:async()=>{},
  setCamEnabled:async()=>{},setSpeakerEnabled:async()=>{}};
const search = new URLSearchParams('code=123456');
mock.module('next/navigation',()=>({useRouter:()=>({push:()=>{}}),useSearchParams:()=>search}));
mock.module('../../src/i18n',()=>({useT:()=>t}));
mock.module('sonner',()=>({toast:Object.assign(()=>{},{error:()=>{},success:()=>{}})}));
mock.module('../../src/contexts/ServerContext',()=>({useServer:()=>({user:{id:'mobile'}})}));
mock.module('../../src/contexts/IMContext',()=>({useIm:()=>({client:imClient,status:'connected',relogin:()=>{}})}));
mock.module('../../src/hooks/useAudioLevels',()=>({useAudioLevels:()=>({})}));
mock.module('../../src/components/live-meeting/JoinDialog',()=>({JOIN_INTENT_KEY:'join'}));
mock.module('../../src/services/live-meeting/recording',()=>({RoomRecorder:class{}}));
mock.module('../../src/services/live-meeting',()=>({
  getLiveMeetingApi:()=>api,getMediaClient:()=>media,getLiveMeetingDataSource:()=> 'real',
  LiveMeetingApiError:class extends Error{},
}));
const {RoomProvider,useRoom}=await import('../../src/components/live-meeting/room/RoomProvider');
let root:ReturnType<typeof create>|undefined, current!:ReturnType<typeof useRoom>;
function Probe(){current=useRoom();return null;}
afterEach(async()=>{await act(async()=>root?.unmount());root=undefined;});
async function mount(){await act(async()=>{root=create(<RoomProvider><Probe/></RoomProvider>);});}
async function receive(seq:number){await act(async()=>{
  items.push({seq, message_id:`m${seq}`,sender:'desktop',type:'text',body:{text:`desktop-${seq}`}});
  listeners.forEach(fn=>fn());
});}
function reset(){items.length=0;viewing.length=0;chatRequests=opens=active=markReads=0;}

test('joining subscribes while the chat panel is closed; opening and closing preserve first messages',async()=>{
  reset();await mount();
  expect(current.phase).toBe('joined');expect(current.panelTab).not.toBe('chat');
  expect(chatRequests).toBe(1);expect(opens).toBe(1);expect(active).toBe(1);
  expect(viewing[0]).toBe(false);expect(markReads).toBe(0);
  await receive(1);
  expect(current.messages.map(m=>m.text)).toEqual(['desktop-1']);
  await act(async()=>current.setPanelTab('chat'));
  expect(current.messages[0].text).toBe('desktop-1');
  await act(async()=>current.setPanelTab(null));
  await receive(2);
  expect(current.messages.map(m=>m.text)).toEqual(['desktop-1','desktop-2']);
  expect(opens).toBe(1);expect(active).toBe(1);
});

test('returning to the same room subscribes again before opening chat',async()=>{
  reset();await mount();await receive(1);
  await act(async()=>root!.unmount());root=undefined;
  expect(active).toBe(0);expect(listeners.size).toBe(0);
  await mount();
  expect(current.panelTab).not.toBe('chat');expect(chatRequests).toBe(2);expect(active).toBe(1);
  expect(current.messages.map(m=>m.text)).toEqual(['desktop-1']);
  await receive(2);
  expect(current.messages.map(m=>m.text)).toEqual(['desktop-1','desktop-2']);
});
