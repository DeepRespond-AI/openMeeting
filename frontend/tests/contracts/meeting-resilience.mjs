import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import { mkdirSync, writeFileSync, readFileSync } from 'node:fs';
import vm from 'node:vm';

const require = createRequire(new URL('../../package.json', import.meta.url));
const { build } = require('esbuild');
const bundle = await build({
  stdin: {
    contents: `import {ImChannelMediaClient} from './src/services/live-meeting/media/imChannel';
      import {mapLiveError} from './src/services/live-meeting/real';
      globalThis.ImChannelMediaClient=ImChannelMediaClient; globalThis.mapLiveError=mapLiveError;`,
    resolveDir: fileURLToPath(new URL('../../', import.meta.url)), loader: 'ts',
  },
  bundle: true, write: false, format: 'iife', platform: 'browser',
  plugins: [{ name: 'explicit-contract-substitutes', setup(builder) {
    if(process.env.RTC_RELEASE_BASELINE) builder.onLoad({filter:/[\\/]imChannel\.ts$/},()=>({contents:readFileSync(process.env.RTC_RELEASE_BASELINE,'utf8'),loader:'ts'}));
    builder.onResolve({ filter: /^(\.\/screenShare|\.\/rtcTelemetry|@tauri-apps\/api\/(core|event))$/ }, args => ({ path: args.path, namespace: 'stub' }));
    builder.onLoad({ filter: /.*/, namespace: 'stub' }, () => ({ contents: `
      export class ScreenShareClient { async start(){} async stop(){} async close(){} setChannel(){} setConnection(){} acceptTrack(){} }
      export class RtcTelemetry { start(){} stop(){} }
      export const invoke=()=>{throw new Error('IPC must not be used by these tests')};
      export const listen=()=>{throw new Error('Events must not be used by these tests')};`, loader: 'js' }));
  } }],
});
const context = vm.createContext({ AbortController, crypto: globalThis.crypto, setTimeout, clearTimeout, console });
vm.runInContext(bundle.outputFiles[0].text, context);
const { ImChannelMediaClient, mapLiveError } = context;
const results = [];
async function test(name, fn) {
  try { await fn(); results.push({name, pass:true}); }
  catch (error) { results.push({name, pass:false, error:String(error.stack ?? error)}); }
}
const config = () => ({transport:'dr-rtc', channelId:'room-a', ticket:'fixture-ticket', expiresAt:new Date(Date.now()+60000).toISOString()});
function platform(existing=null) {
  const handlers = new Map(), calls = [], snapshot = {media_state:'connected'};
  const handle = {getSnapshot:()=>snapshot, on:(event, fn)=>{handlers.set(event,fn); return ()=>handlers.delete(event);},
    leave:async()=>calls.push('leave'), setMicrophoneEnabled:async on=>calls.push(['mic',on]), setCameraEnabled:async on=>calls.push(['cam',on])};
  const channels = {supported:true, getCurrentSession:async()=>existing,
    join:async(id,options)=>{calls.push(['join',id,options]); return handle;},
    resume:async options=>{calls.push(['resume',options]);return handle;}};
  const client = new ImChannelMediaClient(); let state; client.subscribe(value=>state=value);
  return {client, channels, calls, handlers, snapshot, state:()=>state};
}

await test('fresh join uses DeepRespond ticket and AbortSignal with capture disabled',async()=>{
  const p=platform(); await p.client.connect(config(),p.channels);
  assert.equal(p.state().status,'connected');
  assert.equal(p.calls[0][0],'join'); assert.equal(p.calls[0][2].microphoneEnabled,false);
  assert.equal(p.calls[0][2].cameraEnabled,false); assert.equal(p.calls[0][2].signal.aborted,false);
  await p.client.leave(); assert.equal(p.calls.at(-1),'leave');
});
await test('same valid session resumes without consuming expired ticket or opening capture',async()=>{
  const p=platform({channel_id:'room-a',session_id:'session-123',status:'joined'});
  await p.client.connect({...config(),expiresAt:'2000-01-01T00:00:00Z'},p.channels);
  assert.equal(p.calls.length,1); assert.equal(p.calls[0][0],'resume');
  assert.equal(p.calls[0][1].session_id,'session-123'); assert.equal(p.state().reason,'restored');
  await p.client.setMicEnabled(true); assert.equal(p.state().reason,undefined);
  await p.client.leave();
});
await test('different active channel does not reserve a new seat or terminate that session',async()=>{
  for(const session of [{channel_id:'room-b',session_id:'s',status:'joined'}]){
    const p=platform(session);await p.client.connect(config(),p.channels);
    assert.equal(p.state().reason,'sessionConflict');assert.equal(p.calls.length,0);await p.client.leave();
  }
});
await test('duplicate device conflict preserves its actionable reason without leaving another device',async()=>{
  for(const error of [
    {code:'conflict',status:409,reason:'joined_on_other_device'},
    {code:'conflict',status:409,details:{reason:'joined_on_other_device'}},
  ]){
    const p=platform();p.channels.join=async()=>{throw error;};
    await p.client.connect(config(),p.channels);
    assert.equal(p.state().status,'error');assert.equal(p.state().reason,'joinedOnOtherDevice');
    await p.client.leave();assert.equal(p.calls.length,0);
  }
  const p=platform();p.channels.join=async()=>{throw {code:'conflict',status:409,reason:'other_conflict'};};
  await p.client.connect(config(),p.channels);assert.equal(p.state().reason,'connectionFailed');await p.client.leave();
});
await test('overlapping leave and reconnect await the original SDK close',async()=>{
  const p=platform();await p.client.connect(config(),p.channels);
  let finish, lookups=0;
  p.channels.getCurrentSession=async()=>{lookups++;return null;};
  const handle=p.client.handle;
  handle.leave=()=>new Promise(resolve=>finish=resolve);
  const leaving=p.client.leave();const connecting=p.client.connect(config(),p.channels);
  await new Promise(resolve=>setTimeout(resolve,10));
  assert.equal(lookups,0,'new connection must not query or join before SDK close');
  finish();await leaving;await connecting;assert.equal(lookups,1);
  handle.leave=async()=>{};await p.client.leave();
});
await test('leaving session is polled until released then joins exactly once',async()=>{
  const p=platform();let lookups=0;
  p.channels.getCurrentSession=async()=>++lookups<3?{channel_id:'room-a',session_id:'s',status:'leaving'}:null;
  await p.client.connect(config(),p.channels);
  assert.equal(lookups,3);assert.equal(p.calls.filter(c=>c[0]==='join').length,1);
  assert.equal(p.state().status,'connected');assert.equal(p.state().releasingSessionId,undefined);await p.client.leave();
});
await test('release waiting is cancellable and cannot later start a join',async()=>{
  const p=platform({channel_id:'room-a',session_id:'s',status:'leaving'});
  const joining=p.client.connect(config(),p.channels);
  await new Promise(resolve=>setTimeout(resolve,10));assert.equal(p.state().reason,'sessionReleasing');
  assert.equal(p.state().releasingSessionId,'s');
  await p.client.leave();await joining;assert.equal(p.calls.length,0);assert.equal(p.state().status,'idle');
});
await test('a leaving session in a different room cannot expose self recovery for this room',async()=>{
  const p=platform({channel_id:'room-other',session_id:'s',status:'leaving'});
  let clock=Date.now();context.Date=class extends Date {static now(){return clock+=8000;}};
  try{await p.client.connect(config(),p.channels);assert.equal(p.state().reason,'sessionReleaseTimeout');assert.equal(p.state().releasingSessionId,undefined);assert.equal(p.calls.length,0);}
  finally{delete context.Date;await p.client.leave();}
});
await test('permanent leaving times out without consuming a ticket',async()=>{
  const p=platform({channel_id:'room-a',session_id:'s',status:'leaving'});
  let clock=Date.now();context.Date=class extends Date {static now(){return clock+=8000;}};
  try{await p.client.connect(config(),p.channels);assert.equal(p.state().reason,'sessionReleaseTimeout');assert.equal(p.calls.length,0);}
  finally{delete context.Date;await p.client.leave();}
});
await test('a stalled poll cannot extend release waiting or attach after a late response',async()=>{
  const p=platform();let finish,lookups=0,clock=Date.now();const start=clock;
  context.Date=class extends Date {static now(){return clock;}};
  p.channels.getCurrentSession=()=>{
    if(++lookups===1)return Promise.resolve({channel_id:'room-a',session_id:'stale',status:'leaving'});
    clock=start+14995;return new Promise(resolve=>finish=resolve);
  };
  try {
    await p.client.connect(config(),p.channels);
    assert.equal(p.state().reason,'sessionReleaseTimeout');assert.equal(p.state().releasingSessionId,'stale');
    finish(null);await new Promise(resolve=>setTimeout(resolve,0));assert.equal(p.calls.length,0);
  } finally {delete context.Date;await p.client.leave();}
});
await test('cancelled SDK attach must settle and close before next join',async()=>{
  const p=platform();let finish, attempts=0;
  const handle={...p.client.handle,getSnapshot:()=>({media_state:'connected'}),on:()=>()=>{},leave:async()=>{}};
  p.channels.join=async()=>{attempts++;if(attempts===1)return new Promise(resolve=>finish=()=>resolve(handle));return handle;};
  const first=p.client.connect(config(),p.channels);await new Promise(resolve=>setTimeout(resolve,0));
  const second=p.client.connect(config(),p.channels);await new Promise(resolve=>setTimeout(resolve,10));assert.equal(attempts,1);
  finish();await first;await second;assert.equal(attempts,2);assert.equal(p.state().status,'connected');await p.client.leave();
});
await test('SDK reconnect events never cause another join or resume',async()=>{
  const p=platform();await p.client.connect(config(),p.channels);
  p.handlers.get('connectionChanged')('reconnecting');assert.equal(p.state().status,'connecting');
  p.handlers.get('connectionChanged')('connected');assert.equal(p.state().status,'connected');
  assert.equal(p.calls.length,1);await p.client.leave();
});
await test('session terminal event clears tracks and listeners without retrying',async()=>{
  const p=platform();await p.client.connect(config(),p.channels);let stopped=0;
  p.handlers.get('track')({session_id:'s',kind:'audio',username:'u',local:true,track:{id:'t',stop:()=>stopped++}});
  p.handlers.get('sessionLeft')({status:'left'});
  assert.equal(stopped,1);assert.equal(p.state().tracks.length,0);
  assert.equal(p.state().reason,'sessionEnded');assert.equal(p.handlers.size,0);assert.equal(p.calls.length,1);
});
await test('leaving cancels pending SDK join and late results cannot reactivate media',async()=>{
  const p=platform();let requested;
  p.channels.join=async(id,options)=>{requested=options.signal;return new Promise((resolve,reject)=>{
    options.signal.addEventListener('abort',()=>reject(new Error('cancelled')),{once:true});
  });};
  const joining=p.client.connect(config(),p.channels);
  await new Promise(resolve=>setTimeout(resolve,0));assert.ok(requested);
  await p.client.leave();await joining;assert.equal(requested.aborted,true);assert.equal(p.state().status,'idle');
});
await test('leaving while session lookup is pending cannot start join afterwards',async()=>{
  const p=platform();let release;
  p.channels.getCurrentSession=()=>new Promise(resolve=>release=resolve);
  const joining=p.client.connect(config(),p.channels);
  await new Promise(resolve=>setTimeout(resolve,0));await p.client.leave();release(null);await joining;
  assert.equal(p.calls.length,0);assert.equal(p.state().status,'idle');
});
await test('SDK authorization rejection is distinct from device permission and never retried',async()=>{
  const p=platform();let attempts=0;
  p.channels.join=async()=>{attempts++;throw {code:'forbidden'};};
  await p.client.connect(config(),p.channels);assert.equal(attempts,1);assert.equal(p.state().reason,'accessDenied');
  await p.client.leave();
});
await test('ordinary 403/409 preserve detail and explicit join codes retain specific UX',async()=>{
  for(const status of [403,409]){
    const error=mapLiveError({status,detail:'actual permission or conflict'});
    assert.equal(error.name,'Error');assert.equal(error.message,'actual permission or conflict');
  }
  assert.equal(mapLiveError({status:403,code:'host_required',detail:'host only'}).message,'host only');
  assert.equal(mapLiveError({status:403,code:'wrong_pwd',detail:'bad password'}).code,'wrong_pwd');
  assert.equal(mapLiveError(JSON.stringify({status:409,code:'full',detail:'capacity'})).code,'full');
  assert.equal(mapLiveError({status:404,code:'not_started',detail:'Wait for host'}).code,'not_started');
  assert.equal(mapLiveError(JSON.stringify({status:404,code:'not_started',detail:'Wait for host'})).code,'not_started');
  assert.equal(mapLiveError({status:404,code:'not_found',detail:'Unknown code'}).code,'not_found');
  assert.equal(mapLiveError({status:404,code:'not_found',detail:'会议尚未开始'}).code,'not_started');
  assert.equal(mapLiveError({status:404,detail:'会议尚未开始'}).code,'not_started');
  assert.equal(mapLiveError({status:403,detail:'会议尚未开始'}).name,'Error');
});

const report={scope:'SDK public API substitutes and business error mapping only; no real media, IPC, SDK engine or platform E2E',results};
const output=new URL('../../../.artifacts/contracts/',import.meta.url);
mkdirSync(output,{recursive:true});
writeFileSync(new URL('meeting-resilience-results.json',output),JSON.stringify(report,null,2));
for(const row of results) console.log(`${row.pass?'PASS':'FAIL'} ${row.name}${row.error?'\n'+row.error:''}`);
if(results.some(row=>!row.pass))process.exitCode=1;
