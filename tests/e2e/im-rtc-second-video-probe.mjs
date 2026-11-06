import { testPython } from './local-tools.cjs';
import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
import {fileURLToPath} from 'node:url';
import {mkdirSync,readFileSync,writeFileSync,existsSync,openSync} from 'node:fs';
import {spawn} from 'node:child_process';
import http from 'node:http';
import path from 'node:path';
import {installRtcCamera} from './fixtures/rtc-camera-capture.mjs';

const root=fileURLToPath(new URL('../../',import.meta.url)),out=path.resolve(process.env.IM_RTC_SCREEN_OUTPUT||path.join(root,'.artifacts/IM第二视频轨道共享'));
mkdirSync(path.join(out,'platform-screenshots'),{recursive:true});
const require=createRequire(path.join(root,'frontend/package.json')),{build}=require('esbuild'),{chromium}=require('playwright');
const result={started:new Date().toISOString(),scope:'Real deployed IM public channel SDK; two CAMERA-source videos, synthetic camera/screen input; no native desktop claim',steps:[],cleanup:{},conclusion:''};
const resultPath=path.join(out,'platform-acceptance.json');
if(existsSync(resultPath)){const old=JSON.parse(readFileSync(resultPath,'utf8'));result.history=[...(old.history||[]),{started:old.started,steps:old.steps,conclusion:old.conclusion}];}
const save=()=>writeFileSync(resultPath,JSON.stringify(result,null,2));
let budgetStarted;
async function step(operation,expected,fn){
  if(budgetStarted&&Date.now()-budgetStarted>1800000)throw Error('Shared 30 minute browser budget exhausted');
  const row={operation,expected,actual:'',pass:false,screenshot:null};result.steps.push(row);
  try{row.actual=await fn()??'Confirmed';row.pass=true;}catch(e){row.actual=String(e.message);throw e;}finally{console.log(JSON.stringify(row));save();}
}
const bundle=await build({stdin:{contents:"import {createDRClient} from '@deeprespond/im-web';window.createDRClient=createDRClient;",resolveDir:path.join(root,'frontend')},bundle:true,write:false,format:'iife',platform:'browser'});
const html='<html lang="zh"><meta charset="utf-8"><title>真实 IM 双视频轨道探测</title><style>body{font:16px system-ui;background:#101827;color:#eee;padding:24px}#videos{display:flex;flex-wrap:wrap;gap:18px}figure{margin:0;max-width:100%;width:450px}video{width:100%;background:#222;aspect-ratio:16/9}figcaption{overflow-wrap:anywhere;padding:8px 0}</style><h1>真实 IM：摄像头与第二视频轨道</h1><p>测试诊断页；合成采集 + 真实 SDK/平台媒体传输。蓝绿色为摄像头，紫色为共享。</p><div id="videos"></div><script src="/sdk.js"></script></html>';
const server=http.createServer((q,r)=>{r.setHeader('Content-Type',q.url==='/sdk.js'?'application/javascript':'text/html;charset=utf-8');r.end(q.url==='/sdk.js'?bundle.outputFiles[0].text:html);});
await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
const log=openSync(path.join(out,'platform-broker.log'),'a');
let broker,browser,peer;
const pages=[];
const brokerApi=(route,options)=>fetch('http://127.0.0.1:3177'+route,{...options,signal:AbortSignal.timeout(30000)});
async function login(alias){
  const response=await brokerApi('/config/'+alias);assert.equal(response.status,200);const config=await response.json();
  const context=await browser.newContext({permissions:['camera','microphone'],viewport:{width:1280,height:800}});await context.addInitScript(installRtcCamera);
  const page=await context.newPage();page.setDefaultTimeout(18000);pages.push(page);
  await page.goto(`http://127.0.0.1:${server.address().port}`);
  await step(alias+' real IM login','Temporary user authenticates through unmodified platform auth',()=>page.evaluate(async c=>{window.im=window.createDRClient({apiUrl:c.apiUrl,appKey:c.appKey,storage:'memory',tokenStorage:'memory',sessionScope:'tab'});await window.im.auth.loginWithTicket({ticket:c.loginTicket});await window.im.connection.waitUntilReady({timeoutMs:15000});},config));
  await step(alias+' real RTC join','Authorized role joins the isolated real platform video channel',()=>page.evaluate(async c=>{
    window.channel=await window.im.channels.join(c.channelId,{ticket:c.ticket,microphoneEnabled:false,cameraEnabled:false});
    if(window.channel.getSnapshot().media_state!=='connected')throw Error('RTC not connected');
    window.received=new Map();
    window.channel.on('track',t=>{if(t.local||t.kind!=='video')return;let item=window.received.get(t.track);if(item)return;const figure=document.createElement('figure'),video=document.createElement('video'),label=document.createElement('figcaption');video.autoplay=true;video.muted=true;video.playsInline=true;video.srcObject=new MediaStream([t.track]);label.textContent=`${t.source} / ${t.publicationName}`;figure.append(video,label);document.querySelector('#videos').append(figure);video.play().catch(()=>{});window.received.set(t.track,{track:t,video,figure});});
    window.channel.on('trackRemoved',t=>{const item=window.received.get(t.track);item?.figure.remove();window.received.delete(t.track);});
    return {role:c.role,connected:true};
  },config));
  return page;
}
async function publishScreen(page,name){return page.evaluate(async name=>{
  const canvas=document.createElement('canvas');canvas.width=960;canvas.height=540;const ctx=canvas.getContext('2d');let frame=0;
  const draw=()=>{ctx.fillStyle='#9333a8';ctx.fillRect(0,0,960,540);ctx.fillStyle='#fff';ctx.font='36px sans-serif';ctx.fillText(`SHARED SCREEN / ${++frame}`,40,150);};draw();
  const timer=setInterval(draw,80),stream=canvas.captureStream(12),native=stream.getVideoTracks()[0],stop=native.stop.bind(native);native.stop=()=>{clearInterval(timer);stop();};
  try{await window.channel.publishScreenTrack(native,{name});return {published:true,name};}catch(e){native.stop();throw Error(JSON.stringify({name:e.name,code:e.code,status:e.status,message:e.message}));}
},name);}
async function progress(page,source,name){
  const params={source,name};
  const sample=()=>page.evaluate(({source,name})=>{const item=[...window.received.values()].find(x=>x.track.source===source&&(!name||x.track.publicationName===name));if(!item)return null;const v=item.video;if(v.videoWidth<=0||v.currentTime<=0)return null;const canvas=document.createElement('canvas');canvas.width=1;canvas.height=1;const ctx=canvas.getContext('2d');ctx.drawImage(v,0,0,1,1);return {id:item.track.track.id,width:v.videoWidth,height:v.videoHeight,time:v.currentTime,pixel:[...ctx.getImageData(0,0,1,1).data]};},params);
  await page.waitForFunction(({source,name})=>[...window.received.values()].some(x=>x.track.source===source&&(!name||x.track.publicationName===name)&&x.video.videoWidth>0&&x.video.currentTime>0),params,{timeout:18000});
  // Reused WebRTC receivers may briefly retain the previous publication's frame.
  // Require the known input's actual pixels, not just a name and non-zero dimensions.
  const until=Date.now()+15000;let content;
  while(Date.now()<until){content=await sample();if(content){const [red,green,blue]=content.pixel;if(source==='screen'?red>green+35&&blue>100:green>red+25)break;}await new Promise(resolve=>setTimeout(resolve,100));}
  const matches=content&&(source==='screen'?content.pixel[0]>content.pixel[1]+35&&content.pixel[2]>100:content.pixel[1]>content.pixel[0]+25);
  assert.ok(matches,'Decoded pixels did not match '+source+': '+JSON.stringify(content));
  const before=await sample();await page.waitForFunction(({source,name,id,time})=>[...window.received.values()].some(x=>x.track.source===source&&(!name||x.track.publicationName===name)&&x.track.track.id===id&&x.video.currentTime>time+.2),{...params,...before},{timeout:10000});
  const after=await sample();assert.ok(after.time>before.time);
  assert.ok(after.width>=(source==='screen'?320:160)&&after.height>=(source==='screen'?180:90),'video did not decode a usable layer');
  assert.ok(Math.abs(after.width/after.height-16/9)<.05,'unexpected video aspect ratio');
  return after;
}
try{
  await step('Broker port preflight','No existing test service is replaced',async()=>{assert.equal(await brokerApi('/health').then(()=>true).catch(()=>false),false);});
  broker=spawn(process.env.OPENMEETING_TEST_PYTHON||testPython(),[path.join(root,'tests/e2e/fixtures/im-rtc-screen-server.py')],{cwd:root,env:{...process.env,OPENMEETING_RTC_TEST_ENV:process.env.OPENMEETING_RTC_TEST_ENV||path.join(root,'server/.env')},windowsHide:true,stdio:['ignore',log,log]});
  let ready=false;for(let i=0;i<100;i++){if(await brokerApi('/health').then(r=>r.ok).catch(()=>false)){ready=true;break;}if(broker.exitCode!==null)throw Error('Broker exited before ready');await new Promise(resolve=>setTimeout(resolve,100));}assert.ok(ready);
  const budgetFile=path.join(out,'budget.json');budgetStarted=existsSync(budgetFile)?JSON.parse(readFileSync(budgetFile,'utf8')).started:Date.now();if(!existsSync(budgetFile))writeFileSync(budgetFile,JSON.stringify({started:budgetStarted}));assert.ok(Date.now()-budgetStarted<1800000);
  browser=await chromium.launch({headless:true});const host=await login('host');peer=await login('peer');
  await step('Screen-first CAMERA source publication','Second-video screen publishes through current IM publisher grants',()=>publishScreen(host,'screen:platform-probe'));
  await step('Remote shared video decode','Peer decodes the purple shared input with advancing time; actual resolution recorded',()=>progress(peer,'screen','screen:platform-probe'));
  await step('Camera after screen','Camera can be enabled without replacing shared video',async()=>{await host.evaluate(()=>window.channel.setCameraEnabled(true));return {camera:await progress(peer,'camera'),screen:await progress(peer,'screen','screen:platform-probe')};});
  await step('Camera off does not stop shared video','Screen remains live when only actual camera is muted',async()=>{await host.evaluate(()=>window.channel.setCameraEnabled(false));return progress(peer,'screen','screen:platform-probe');});
  await step('Camera back on preserves both tracks','Both remotely decoded tracks continue after camera restart',async()=>{await host.evaluate(()=>window.channel.setCameraEnabled(true));return {camera:await progress(peer,'camera'),screen:await progress(peer,'screen','screen:platform-probe')};});
  await step('Stop screen preserves camera','Shared publication disappears while peer camera continues',async()=>{await host.evaluate(()=>window.channel.stopScreenShare());await peer.waitForFunction(()=>![...window.received.values()].some(x=>x.track.source==='screen'));return progress(peer,'camera');});
  await step('Publish screen alongside existing camera','Both tracks coexist when publication order is reversed',async()=>{await publishScreen(host,'screen:second-order');return {camera:await progress(peer,'camera'),screen:await progress(peer,'screen','screen:second-order')};});
  const late=await login('viewer');
  await step('Late subscriber receives both videos','New subscriber receives existing camera and shared track',async()=>({camera:await progress(late,'camera'),screen:await progress(late,'screen','screen:second-order')}));
  await step('Subscriber cannot publish shared video','SDK publisher-role enforcement still rejects subscriber',async()=>{const actual=await late.evaluate(async()=>{const canvas=document.createElement('canvas');canvas.width=640;canvas.height=360;const s=canvas.captureStream();try{await window.channel.publishScreenTrack(s.getVideoTracks()[0],{name:'screen:forbidden'});return {rejected:false};}catch(e){return {rejected:true,code:e.code,name:e.name};}finally{s.getTracks().forEach(t=>t.stop());}});assert.equal(actual.rejected,true);assert.ok(['permission_denied','forbidden','invalid_state'].includes(actual.code));return actual;});
  await step('Channel refresh preserves both videos','Refreshing authorization does not merge camera and shared tracks',async()=>{await host.evaluate(()=>window.channel.refresh());return {camera:await progress(peer,'camera'),screen:await progress(peer,'screen','screen:second-order')};});
  for(const [name,viewport] of [['desktop',{width:1280,height:800}],['narrow',{width:640,height:600}]]){await peer.setViewportSize(viewport);const file=`platform-screenshots/${name}-dual-video.png`;await peer.screenshot({path:path.join(out,file),fullPage:true});result.steps.push({operation:`Platform dual-video screenshot ${name}`,expected:'Actual remote camera and screen are visible',actual:{viewport},pass:true,screenshot:file});}
  result.conclusion='Real IM dual CAMERA-source publication and subscription passed; independent camera controls, screen stop, late subscriber and role denial verified.';
}catch(e){result.conclusion='Real IM second-video acceptance failed: '+e.message;process.exitCode=1;if(peer){const file=`platform-screenshots/failure-${Date.now()}.png`;await peer.screenshot({path:path.join(out,file),fullPage:true}).catch(()=>{});const row=result.steps.findLast(s=>!s.pass);if(row)row.screenshot=file;}}
finally{
  for(const page of pages)await page.evaluate(async()=>{await window.channel?.leave().catch(()=>{});await window.im?.destroy().catch(()=>{});}).catch(()=>{});
  await browser?.close();await new Promise(resolve=>server.close(resolve));result.cleanup.browser='closed';
  if(broker){result.cleanup.platform=await brokerApi('/cleanup',{method:'POST'}).then(r=>r.json()).catch(()=>({errors:['cleanup unavailable']}));await brokerApi('/shutdown',{method:'POST'}).catch(()=>{});await new Promise(resolve=>{if(broker.exitCode!==null||broker.signalCode!==null)return resolve();broker.once('exit',resolve);setTimeout(()=>{broker.kill();resolve();},8000);});result.cleanup.broker=broker.exitCode!==null||broker.signalCode!==null?'closed':'failed to close';}
  save();console.log(JSON.stringify({passed:result.steps.filter(s=>s.pass).length,failed:result.steps.filter(s=>!s.pass).length,conclusion:result.conclusion,cleanup:result.cleanup}));
}
