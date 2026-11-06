// Supplementary live SDK protocol probe. Not native Android acceptance.
import fs from 'node:fs';
import path from 'node:path';
import {createRequire} from 'node:module';
const root=path.resolve(import.meta.dirname,'../..'),front=path.join(root,'frontend'),out=path.join(root,'.artifacts/same-account-meeting-entry');
const require=createRequire(path.join(front,'package.json')),{build}=require('esbuild'),{chromium}=require('playwright');
const accounts=JSON.parse(fs.readFileSync(path.join(out,'accounts.private.json'))),room=JSON.parse(fs.readFileSync(path.join(out,'owned-room.json')));
const budget=JSON.parse(fs.readFileSync(path.join(out,'budget.json')));if(Date.now()-budget.started>budget.limitMs)throw Error('30 minute E2E budget exhausted');
for(const k of Object.keys(process.env))if(/^(https?|all)_proxy$/i.test(k))delete process.env[k];
const result={boundary:'Live IM web SDK and real RTC control/media in three isolated browser contexts; supplementary to native desktop evidence. No SDK/API/media fixtures.',steps:[],events:[]};
if(fs.existsSync(path.join(out,'sdk-probe.json')))fs.copyFileSync(path.join(out,'sdk-probe.json'),path.join(out,`sdk-probe-history-${Date.now()}.json`));
const save=()=>fs.writeFileSync(path.join(out,'sdk-probe.json'),JSON.stringify(result,null,2));
await build({stdin:{contents:"import {createDRClient} from '@deeprespond/im-web'; window.createProbeClient=createDRClient;",resolveDir:front},outfile:path.join(front,'public/same-account-probe.js'),bundle:true,format:'esm',target:'chrome100',logLevel:'silent'});
fs.writeFileSync(path.join(front,'public/same-account-probe.html'),'<html><head><script type="module" src="/same-account-probe.js"></script></head><body>Live SDK protocol diagnostic</body></html>');
async function api(token,method,route,body){const r=await fetch('http://127.0.0.1:39110/api/v1'+route,{method,headers:{authorization:'Bearer '+token,'content-type':'application/json'},body:body===undefined?undefined:JSON.stringify(body),signal:AbortSignal.timeout(20000)});return{status:r.status,body:await r.json()};}
const browser=await chromium.launch({headless:true}),pages=[];
try{
 for(let i=0;i<3;i++){
  const context=await browser.newContext(),p=await context.newPage();pages.push(p);
  p.on('response',async r=>{if(/\/rtc\//.test(r.url())){let body;try{body=await r.json()}catch{}result.events.push({client:i,path:new URL(r.url()).pathname,status:r.status(),code:body?.code,reason:body?.details?.reason,detail:body?.detail});save();}});
  await p.goto('http://localhost:3162/same-account-probe.html');await p.waitForFunction(()=>typeof window.createProbeClient==='function');
  const account=accounts[i===2?1:0],ticket=await api(account.token,'POST','/im/ticket',{});if(ticket.status!==200)throw Error('IM ticket '+ticket.status);
  const login=await p.evaluate(async c=>{try{window.probeClient=window.createProbeClient({appKey:c.app_key,apiUrl:c.api_url,platform:'web',logger:{level:'warn'}});await window.probeClient.auth.loginWithTicket({ticket:c.ticket});return{signedIn:!!window.probeClient.auth.currentUser};}catch(e){return{error:e.code,reason:e.reason,message:e.message}}},ticket.body);
  result.steps.push({operation:'login '+i,expected:'Live IM SDK authenticates',actual:login,pass:login.signedIn===true,screenshot:null});save();if(!login.signedIn)continue;
  const media=await api(account.token,'POST',`/rooms/${room.id}/media`,{});
  const joined=await p.evaluate(async({media})=>{const client=window.probeClient;try{const current=await client.channels.getCurrentSession();const before=current&&{status:current.status,channelId:current.channel_id};window.probeHandle=current&&['joining','joined'].includes(current.status)&&current.channel_id===media.channelId?await client.channels.resume({channel_id:current.channel_id,session_id:current.session_id}):await client.channels.join(media.channelId,{ticket:media.ticket,microphoneEnabled:false,cameraEnabled:false});return{before,snapshot:{status:window.probeHandle.getSnapshot().session.status,mediaState:window.probeHandle.getSnapshot().media_state}};}catch(e){return{error:e.code,status:e.status,reason:e.reason,message:e.message,details:e.details}}},{media:media.body});
  result.steps.push({operation:'join '+i,expected:i===1?'Record same-account second-device admission or explicit conflict':'Single account/different account media connect',actual:joined,pass:joined.snapshot?.mediaState==='connected',screenshot:null});save();console.log(JSON.stringify(result.steps.slice(-2)));
  if(i===1){result.firstDeviceAfterDuplicate=await pages[0].evaluate(async()=>{await window.probeHandle.refresh();const s=window.probeHandle.getSnapshot();return{status:s.session.status,mediaState:s.media_state}});save();}
 }
}catch(error){result.failure=String(error.stack||error);console.error(result.failure);process.exitCode=1;}finally{for(const p of pages)await p.evaluate(async()=>{await window.probeHandle?.leave().catch(()=>{});await window.probeClient?.destroy().catch(()=>{})}).catch(()=>{});save();await browser.close();}
