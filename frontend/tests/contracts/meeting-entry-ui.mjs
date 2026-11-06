// Browser regression of the real entry components and RoomProvider, with controlled
// service/SDK boundaries. No native RTC or production backend is used here.
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import { mkdirSync, readFileSync } from 'node:fs';

const require = createRequire(new URL('../../package.json', import.meta.url));
const { build } = require('esbuild');
const { chromium } = require('playwright');
const root = fileURLToPath(new URL('../../', import.meta.url));
const out = fileURLToPath(new URL('../../../.artifacts/meeting-entry-loading/', import.meta.url));
mkdirSync(out, { recursive: true });

const fixture = `
import React,{useState} from 'react';
import home from './src/i18n/messages/home';
import liveMeeting from './src/i18n/messages/liveMeeting';
export const flags={audio:true,video:true,chat:true,recording:false,screenShare:false,members:true};
const f=window.fixture={calls:[],flags,mode:'real'};
const deferred=name=>new Promise((resolve,reject)=>{f[name]=resolve;f[name+'Fail']=reject;});
const self={id:'self',userId:'user',name:'Test',isHost:true,isSelf:true,micOn:false,camOn:false,handRaised:false};
const room={id:'room',code:'123456',title:'Entry test',participants:[self],waiting:[],status:'active'};
const config={transport:'dr-rtc',channelId:'channel',ticket:'ticket',expiresAt:'2099-01-01T00:00:00Z'};
let state={status:'idle',tracks:[],speakerEnabled:true},listeners=new Set();
f.media=patch=>{state={...state,...patch};listeners.forEach(fn=>fn(state));};
f.chat=status=>f.chatSnapshot?.({status,messages:[],unread:0,hasOlder:false,loadingOlder:false});
f.emit=e=>f.event?.(e);
export const api={
 createRoom:()=>{f.calls.push('create');return deferred('created');},
 checkRoomCode:()=>{f.calls.push('check');return deferred('checked');},
 joinRoom:args=>{f.calls.push(['join',args]);return deferred('joined');},
 onRoomEvent:fn=>{f.event=fn;return()=>{};},
 getChatSession:async()=>({groupId:'group'}),
 getRoomMedia:async()=>({...config}),
 updateSelf:async(_,patch)=>{f.calls.push(['update',patch]);return{...self,...patch};},
 leaveRoom:async()=>f.calls.push('leave'),disconnectRoom:async()=>{f.calls.push('disconnect');},
 endRoom:async()=>{f.calls.push('end');return{meetingId:'notes'};},
 listChat:async()=>({messages:[],hasMore:false}),
};
f.completeCreate=()=>f.created(room);
f.completeCheck=(pwdEnabled=false)=>f.checked({...room,pwdEnabled});
f.completeJoin=(state='joined',isHost=true)=>f.joined({room:{...room,participants:[{...self,isHost}]},self:{...self,isHost},media:config,state});
export const media={
 subscribe:fn=>{listeners.add(fn);fn(state);return()=>listeners.delete(fn);},
 connect:async()=>{f.calls.push('connect');f.media({status:'connecting'});await deferred('connected');},
 setSpeakerEnabled:async()=>{},
 setMicEnabled:async on=>{if(on){f.calls.push('mic');await deferred('microphone');}},
 setCamEnabled:async on=>{if(on){f.calls.push('camera');await deferred('camera');}},
 leave:async()=>{f.calls.push('mediaLeave');},
};
export class ImMeetingChat {
 constructor(_client,_room,_group,_user,_participants,callback){f.chatSnapshot=callback;}
 async connect(){f.calls.push('chat');} setViewing(){} dispose(){} async close(){}
}
const im={status:'ready',client:{channels:{},auth:{currentUser:{username:'user'}},on:()=>()=>{}},relogin:()=>{}};
export const useIm=()=>im;
const t=key=>key.split('.').reduce((obj,k)=>obj?.[k],{home:home['zh-CN'],liveMeeting:liveMeeting['zh-CN']})??key;
export const useT=()=>t,useI18n=()=>({t,locale:'zh-CN'});
export const useServer=()=>({user:{id:'user',name:'Test'}}),useSidebar=()=>({meetings:[]});
export const useOptionalServer=useServer;
export const getLiveMeetingApi=()=>api,getMediaClient=()=>media,getLiveMeetingDataSource=()=>f.mode,setLiveMeetingUser=()=>{};
export class LiveMeetingApiError extends Error { constructor(code){super(code);this.code=code;} }
export const useAudioLevels=()=>({});
export const useRouter=()=>router,usePathname=()=>f.pathname,useSearchParams=()=>f.search;
const router={push:url=>f.navigate(url),replace:url=>f.navigate(url)};
export function Navigation({children}) {
 const [url,setUrl]=useState(window.location.pathname+window.location.search);
 const parsed=new URL(url,window.location.origin);
 f.pathname=parsed.pathname;
 if(f.search?.toString()!==parsed.search.slice(1))f.search=new URLSearchParams(parsed.search);
 f.navigate=url=>{history.replaceState(null,'',url);setUrl(url);};
 return children(f.pathname);
}
export const toast=Object.assign(()=>{},{error:message=>f.calls.push(['error',message]),info:()=>{},success:()=>{}});
export default {trackPageView:()=>{}};
`;

const bundle = await build({
  stdin: { contents: `import React from 'react';import {createRoot} from 'react-dom/client';
    import {Navigation} from 'fixture';
    import MeetingSession from './src/components/live-meeting/MeetingSession';
    import Home from './src/app/page';
    import {useRoom} from './src/components/live-meeting/room/RoomProvider';
    function App(){return <Navigation>{path=><MeetingSession>{path==='/'?<Home/>:null}</MeetingSession>}</Navigation>}
    createRoot(document.getElementById('root')).render(<App/>);`, resolveDir: root, loader: 'tsx' },
  bundle: true, write: false, format: 'iife', platform: 'browser', jsx: 'automatic',
  plugins: [{ name: 'entry-service-boundaries', setup(b) {
    b.onResolve({filter:/^(fixture|next\/navigation|sonner|@\/i18n|@\/contexts\/(ServerContext|IMContext)|@\/components\/sidebar\/SidebarProvider|@\/services\/live-meeting(\/chat)?|@\/lib\/analytics|@\/hooks\/useAudioLevels)$/},()=>({path:'fixture',namespace:'fixture'}));
    b.onLoad({filter:/.*/,namespace:'fixture'},()=>({contents:fixture,resolveDir:root,loader:'tsx'}));
    b.onResolve({filter:/^@\/config\/meeting-ui$/},()=>({path:'flags',namespace:'flags'}));
    b.onLoad({filter:/.*/,namespace:'flags'},()=>({contents:"export {flags as meetingUi} from 'fixture';",loader:'js'}));
    b.onResolve({filter:/(^\.\/|live-meeting\/)(RoomHeader|VideoGrid|Toolbar|SidePanel|RecordingBanner|ImInvite|ScheduleDialog|TodayPanel)$/},a=>({path:a.path.split('/').at(-1),namespace:'ui'}));
    b.onLoad({filter:/.*/,namespace:'ui'},({path})=>({contents:`import React from 'react';export default ()=> <div data-testid="fixture-${path}">${path}</div>;`,loader:'tsx',resolveDir:root}));
  }}],
});
const postcss = require('postcss'), tailwindcss = require('tailwindcss');
const config = require('./tailwind.config.js');
const sources=['MeetingEntry.tsx','room/RoomScreen.tsx'].map(name=>readFileSync(`${root}/src/components/live-meeting/${name}`,'utf8')).join('\n')
  + ['src/app/page.tsx','src/components/live-meeting/JoinDialog.tsx','src/components/ui/dialog.tsx','src/components/ui/switch.tsx'].map(name=>readFileSync(`${root}/${name}`,'utf8')).join('\n');
const css=await postcss([tailwindcss({...config,content:[{raw:sources,extension:'tsx'}]})]).process(readFileSync(`${root}/src/app/globals.css`,'utf8'),{from:undefined});
const browser=await chromium.launch({headless:true});
const errors=[];
let page;
async function boot(path='/',options={}) {
  await page?.close();
  page=await browser.newPage({viewport:{width:1000,height:720}});
  page.setDefaultTimeout(10000);
  page.on('pageerror',e=>errors.push(String(e)));
  await page.route('http://127.0.0.1:3197/**',route=>route.fulfill({contentType:'text/html',body:`<html><head><meta charset="utf-8"><style>${css.css}</style></head><body><div id="root"></div></body></html>`}));
  await page.goto('http://127.0.0.1:3197'+path);
  await page.evaluate(() => {
    localStorage.setItem('openmeeting:meeting-audio',JSON.stringify({autoJoin:true}));
    const original=setTimeout;
    window.setTimeout=(fn,ms,...args)=>ms===45000?(window.expireEntry=fn,987654):original(fn,ms,...args);
  });
  await page.addScriptTag({content:bundle.outputFiles[0].text});
  if(Object.keys(options).length)await page.evaluate(options=>Object.assign(window.fixture.flags,options),options);
}
const loader=()=>page.getByTestId('meeting-entry-loading');
const toolbar=()=>page.getByTestId('fixture-Toolbar');
async function call(name,...args){
  const prerequisite={completeJoin:'joined',completeCreate:'created',completeCheck:'checked',chat:'chatSnapshot'}[name]??name;
  await page.waitForFunction(name=>typeof window.fixture[name]==='function',prerequisite);
  await page.evaluate(([name,args])=>window.fixture[name](...args),[name,args]);
}
async function pending(){await loader().waitFor();assert.equal(await toolbar().count(),0);}
async function identity(){await page.evaluate(()=>{window.entryNode=document.querySelector('[data-testid="meeting-entry-loading"]');window.entrySpinner=window.entryNode.querySelector('svg');});}
async function sameLoader(){assert.ok(await page.evaluate(()=>window.entryNode===document.querySelector('[data-testid="meeting-entry-loading"]')&&window.entrySpinner===window.entryNode.querySelector('svg')));}
async function ready(){await loader().waitFor({state:'detached'});await toolbar().waitFor();assert.equal(await page.getByTestId('meeting-connecting').count(),0);}
async function mediaConnected(){await call('media',{status:'connected'});await call('connected');}
async function step(name,fn){await fn();console.log(JSON.stringify({name,pass:true}));}
try {
  await step('quick meeting keeps the exact same spinner across create, join, chat, RTC and microphone initialization',async()=>{
    await boot();
    await page.getByRole('button',{name:'快速会议 立即发起一场会议',exact:true}).click();
    await pending();await identity();
    await page.setViewportSize({width:390,height:844});await page.screenshot({path:out+'/loading-narrow.png'});await page.setViewportSize({width:1000,height:720});
    await call('completeCreate');await page.waitForURL('**/room?code=123456');await pending();await sameLoader();
    await call('completeJoin');await call('chat','ready');await pending();await sameLoader();
    await mediaConnected();await page.waitForFunction(()=>window.fixture.calls.includes('mic'));await pending();await sameLoader();
    await page.screenshot({path:out+'/loading-wide.png'});
    await call('microphone');await ready();
    assert.equal(await page.evaluate(()=>window.fixture.calls.filter(c=>c==='create').length),1);
    await page.screenshot({path:out+'/ready-wide.png'});
  });
  await step('in-meeting reconnect and return home do not restart initial loading',async()=>{
    await call('media',{status:'connecting'});await toolbar().waitFor();assert.equal(await loader().count(),0);
    await call('media',{status:'connected'});
    await call('navigate','/');await page.getByTestId('return-meeting').click();await ready();
  });
  await step('join code check, navigation, media and slower chat use one continuous loading page',async()=>{
    await boot();await page.getByRole('button',{name:'加入会议 输入会议号入会',exact:true}).click();
    const dialog=page.getByRole('dialog');
    for(let i=0;i<6;i++)await dialog.locator('input[inputmode="numeric"]').nth(i).fill('123456'[i]);
    for(const button of await dialog.getByRole('switch').all())if(await button.getAttribute('aria-checked')==='true')await button.click();
    await dialog.getByRole('button',{name:'加入会议',exact:true}).click();await pending();await identity();
    await call('completeCheck');await page.waitForURL('**/room?code=123456');await sameLoader();
    await call('completeJoin');await mediaConnected();await pending();await sameLoader();
    await call('chat','ready');await ready();
    assert.ok(!await page.evaluate(()=>window.fixture.calls.includes('mic')||window.fixture.calls.includes('camera')));
  });
  await step('direct entry waits for the default microphone initialization',async()=>{
    await boot('/room?code=123456');await pending();
    // Direct entry requests only the microphone by default.
    await call('completeJoin');await call('chat','ready');await mediaConnected();await call('microphone');await ready();
  });
  await step('join with microphone and camera enabled waits until both devices settle',async()=>{
    await boot();await page.getByRole('button',{name:'加入会议 输入会议号入会',exact:true}).click();
    const dialog=page.getByRole('dialog');
    for(let i=0;i<6;i++)await dialog.locator('input[inputmode="numeric"]').nth(i).fill('123456'[i]);
    await dialog.getByRole('button',{name:'加入会议',exact:true}).click();
    await call('completeCheck');await call('completeJoin');await call('chat','ready');await mediaConnected();
    await call('microphone');await page.waitForFunction(()=>window.fixture.calls.includes('camera'));await pending();
    await call('camera');await ready();
  });
  await step('password entry returns to its form and then resumes preparation',async()=>{
    await boot();await page.getByRole('button',{name:'加入会议 输入会议号入会',exact:true}).click();
    const dialog=page.getByRole('dialog');
    for(let i=0;i<6;i++)await dialog.locator('input[inputmode="numeric"]').nth(i).fill('123456'[i]);
    await dialog.getByRole('button',{name:'加入会议',exact:true}).click();await call('completeCheck',true);
    await loader().waitFor({state:'detached'});await dialog.locator('input').fill('654321');
    await dialog.getByRole('button',{name:'加入会议',exact:true}).click();await pending();
    await call('completeCheck',true);await call('completeJoin');await call('chat','ready');await mediaConnected();await call('microphone');await call('camera');await ready();
  });
  await step('disabled modules do not block initial entry',async()=>{
    await boot('/room?code=123456',{audio:false,video:false,chat:false});await call('completeJoin');await ready();
    assert.ok(!await page.evaluate(()=>window.fixture.calls.includes('connect')||window.fixture.calls.includes('chat')));
  });
  await step('chat-only entry does not wait for unavailable media',async()=>{
    await boot('/room?code=123456',{audio:false,video:false});await call('completeJoin');await pending();await call('chat','ready');await ready();
    assert.ok(!await page.evaluate(()=>window.fixture.calls.includes('connect')));
  });
  await step('connection failure shows retry, then completes without creating or joining twice',async()=>{
    await boot('/room?code=123456');await call('completeJoin');await call('chat','ready');
    await call('media',{status:'error',reason:'connectionFailed'});await page.getByTestId('meeting-entry-error').waitFor();assert.equal(await loader().count(),0);
    await page.getByRole('button',{name:'重试',exact:true}).click();await pending();
    await page.waitForFunction(()=>window.fixture.calls.filter(c=>c==='connect').length===2);
    await mediaConnected();await call('microphone');await ready();
    assert.equal(await page.evaluate(()=>window.fixture.calls.filter(c=>Array.isArray(c)&&c[0]==='join').length),1);
  });
  await step('chat failure is retried without reconnecting successful media',async()=>{
    await boot('/room?code=123456');await call('completeJoin');await mediaConnected();await call('microphone');await call('chat','error');
    await page.getByTestId('meeting-entry-error').waitFor();await page.getByRole('button',{name:'重试',exact:true}).click();await pending();
    await page.waitForFunction(()=>window.fixture.calls.filter(c=>c==='chat').length===2);
    await call('chat','ready');await ready();assert.equal(await page.evaluate(()=>window.fixture.calls.filter(c=>c==='connect').length),1);
  });
  await step('late device initialization from a timed-out attempt cannot finish a new attempt',async()=>{
    await boot('/room?code=123456');await call('completeJoin');await call('chat','ready');await mediaConnected();
    await page.waitForFunction(()=>typeof window.fixture.microphone==='function');
    await page.evaluate(()=>{window.fixture.staleMicrophone=window.fixture.microphone;window.expireEntry();});
    await page.getByTestId('meeting-entry-error').waitFor();await page.getByRole('button',{name:'重试',exact:true}).click();
    await page.waitForFunction(()=>window.fixture.calls.filter(c=>c==='connect').length===2);await mediaConnected();
    await page.waitForFunction(()=>window.fixture.microphone!==window.fixture.staleMicrophone);
    await call('staleMicrophone');await pending();await call('microphone');await ready();
  });
  await step('microphone permission failure settles entry with capture disabled and a device warning',async()=>{
    await boot('/room?code=123456');await call('completeJoin');await call('chat','ready');await mediaConnected();
    await call('microphoneFail',new Error('Permission denied'));await ready();
    await page.getByTestId('media-status').waitFor();
    assert.ok(await page.evaluate(()=>window.fixture.calls.some(c=>Array.isArray(c)&&c[0]==='update'&&c[1].micOn===false)));
  });
  await step('stalled initial connections leave the spinner and offer retry or leave',async()=>{
    await boot('/room?code=123456');await call('completeJoin');await pending();
    await page.evaluate(()=>window.expireEntry());await page.getByTestId('meeting-entry-error').waitFor();
    await page.setViewportSize({width:390,height:844});await page.screenshot({path:out+'/error-narrow.png'});
    await page.getByRole('button',{name:'取消入会，返回首页',exact:true}).click();await page.waitForURL('http://127.0.0.1:3197/');assert.equal(await loader().count(),0);
    assert.ok(!await page.evaluate(()=>window.fixture.calls.includes('leave')||window.fixture.calls.includes('end')));
  });
  for(const isHost of [true,false])await step(`other-device conflict cancellation preserves ${isHost?'host':'member'} membership and permits a fresh join`,async()=>{
    await boot('/room?code=123456');await call('completeJoin','joined',isHost);await call('chat','ready');
    await call('media',{status:'error',reason:'joinedOnOtherDevice'});
    await page.getByText('该账号已在另一台设备参会。',{exact:true}).waitFor();
    await page.getByText('请先在另一设备退出会议，再点击重试。连接释放可能需要一些时间。在此取消入会不会结束另一设备上的会议。',{exact:true}).waitFor();
    await page.getByRole('button',{name:'取消入会，返回首页',exact:true}).click();
    await page.waitForURL('http://127.0.0.1:3197/');assert.equal(await loader().count(),0);assert.equal(await page.getByTestId('return-meeting').count(),0);
    const calls=await page.evaluate(()=>window.fixture.calls);
    assert.ok(calls.includes('disconnect'));assert.ok(calls.includes('mediaLeave'));assert.ok(!calls.includes('leave'));assert.ok(!calls.includes('end'));
    await page.getByRole('button',{name:'加入会议 输入会议号入会',exact:true}).click();
    const dialog=page.getByRole('dialog');for(let i=0;i<6;i++)await dialog.locator('input[inputmode="numeric"]').nth(i).fill('123456'[i]);
    for(const control of await dialog.getByRole('switch').all())if(await control.getAttribute('aria-checked')==='true')await control.click();
    await dialog.getByRole('button',{name:'加入会议',exact:true}).click();await call('completeCheck');
    await page.waitForFunction(()=>window.fixture.calls.filter(c=>Array.isArray(c)&&c[0]==='join').length===2);
    await call('completeJoin','joined',isHost);await call('chat','ready');
    await page.waitForFunction(()=>window.fixture.calls.filter(c=>c==='connect').length===2);await mediaConnected();await ready();
    assert.equal(await page.evaluate(()=>window.fixture.calls.filter(c=>Array.isArray(c)&&c[0]==='join').length),2);
  });
  await step('cancelling timed-out device initialization ignores its late completion',async()=>{
    await boot('/room?code=123456');await call('completeJoin');await call('chat','ready');await mediaConnected();
    await page.waitForFunction(()=>typeof window.fixture.microphone==='function');
    await page.evaluate(()=>{window.fixture.staleMicrophone=window.fixture.microphone;window.expireEntry();});
    await page.getByRole('button',{name:'取消入会，返回首页',exact:true}).click();await page.waitForURL('http://127.0.0.1:3197/');
    await call('staleMicrophone');await call('media',{status:'connected'});
    assert.equal(await page.getByTestId('persistent-meeting').count(),0);assert.equal(await loader().count(),0);
    assert.ok(!await page.evaluate(()=>window.fixture.calls.includes('leave')||window.fixture.calls.includes('end')));
  });
  await step('waiting room has no spinner and admission starts one preparation screen',async()=>{
    await boot('/room?code=123456');await call('completeJoin','waiting');await loader().waitFor({state:'detached'});
    await call('emit',{type:'waiting_resolved',data:{participantId:'self',admitted:true}});await pending();
    await call('chat','ready');await mediaConnected();await call('microphone');await ready();
  });
  await step('failed creation releases loading and can be started again',async()=>{
    await boot();const quick=page.getByRole('button',{name:'快速会议 立即发起一场会议',exact:true});await quick.click();await pending();
    await call('createdFail','fixture failure');await loader().waitFor({state:'detached'});await quick.click();await pending();
    assert.equal(await page.evaluate(()=>window.fixture.calls.filter(c=>c==='create').length),2);
  });
  await step('failed code lookup releases loading and leaves the form usable',async()=>{
    await boot();await page.getByRole('button',{name:'加入会议 输入会议号入会',exact:true}).click();
    const dialog=page.getByRole('dialog');for(let i=0;i<6;i++)await dialog.locator('input[inputmode="numeric"]').nth(i).fill('123456'[i]);
    await dialog.getByRole('button',{name:'加入会议',exact:true}).click();await pending();await call('checkedFail','fixture failure');
    await loader().waitFor({state:'detached'});assert.ok(await dialog.getByRole('button',{name:'加入会议',exact:true}).isEnabled());
  });
  assert.deepEqual(errors,[]);
} catch (error) {
  console.error({errors,body:await page?.locator('body').innerText()});
  await page?.screenshot({path:out+'/failure.png'});
  throw error;
} finally { await browser.close(); }
