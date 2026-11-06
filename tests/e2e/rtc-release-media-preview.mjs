import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {fileURLToPath} from 'node:url';
import {createRequire} from 'node:module';
import {execFileSync} from 'node:child_process';
import {prepareNativeInput} from './meeting-ready-input.mjs';
const root=fileURLToPath(new URL('../../',import.meta.url));
const out=path.resolve(root,process.env.MEETING_READY_OUTPUT||'.artifacts/rtc-release-media-preview');
fs.mkdirSync(out,{recursive:true});
const visual=process.argv.includes('--visual'),extra=process.argv.includes('--extra'),confirmed=process.argv.includes('--confirmed-video'),file=path.join(out,visual?'media-visual.json':extra?'media-extra.json':confirmed?'media-confirmed.json':'media-results.json');
const previous=fs.existsSync(file)?JSON.parse(fs.readFileSync(file,'utf8')).rows:[];
if(fs.existsSync(file))fs.copyFileSync(file,file.replace('.json',`-${Date.now()}.json`));
const rows=[],pages=[],browsers=[];const save=()=>fs.writeFileSync(file,JSON.stringify({rows},null,2));
const budgetPath=path.join(out,'budget.json'),budget=JSON.parse(fs.readFileSync(budgetPath,'utf8'));
assert.ok(Date.now()-budget.firstStartedAt<budget.limitMs,'Cumulative 30-minute E2E budget exhausted');
const watchdog=setTimeout(()=>{save();process.exit(2);},Math.max(1,budget.limitMs-(Date.now()-budget.firstStartedAt)));
const require=createRequire(new URL('../../frontend/package.json',import.meta.url)),{chromium}=require('playwright');
const state=JSON.parse(fs.readFileSync(path.join(out,'success-state.json'),'utf8'));
const accounts=JSON.parse(fs.readFileSync(path.join(out,'accounts.private.json'),'utf8'));
const input=p=>p.getByPlaceholder('发送消息，全体成员可见');
const until=async(fn,ms=25000)=>{const end=Date.now()+ms;while(Date.now()<end){const value=await fn();if(value)return value;await new Promise(r=>setTimeout(r,100));}throw Error('Expected desktop state timed out');};
async function step(operation,expected,fn){const row={operation,expected,actual:null,pass:false,screenshot:null};try{row.actual=await fn();row.pass=true;}catch(e){row.actual=String(e.stack||e);throw e;}finally{rows.push(row);save();console.log(JSON.stringify(row));}}
const invoke=(p,command,args={})=>p.evaluate(({command,args})=>window.__TAURI_INTERNALS__.invoke(command,args),{command,args});
async function sdk(p,action,data={}){return p.evaluate(async({action,data})=>{
 const el=[...document.querySelectorAll('*')].find(e=>Object.keys(e).some(k=>k.startsWith('__reactFiber')));if(!el)throw Error('React root missing');
 let f=el[Object.keys(el).find(k=>k.startsWith('__reactFiber'))];while(f.return)f=f.return;
 const todo=[f],seen=new Set();let client;
 while(todo.length){const n=todo.pop();if(!n||seen.has(n))continue;seen.add(n);const c=n.memoizedProps?.client||n.memoizedProps?.value?.client;if(c?.channels&&c?.messages){client=c;break;}todo.push(n.child,n.sibling);}
 if(!client)throw Error('Authenticated native SDK missing');
 if(action==='session'){const s=client.channels.current?.getSnapshot();return{status:s?.session?.status,media:s?.media_state};}
 if(action==='voice'){
  const bytes=Uint8Array.from(atob(data.base64),c=>c.charCodeAt(0));
  const sent=await client.messages.send({to_group:data.group},{type:'voice',file:new Blob([bytes],{type:'audio/wav'}),body:{duration_seconds:5}},{waitUntil:'sent'});
  return{type:sent.type,format:sent.body?.format,url:sent.body?.url,hasName:!!sent.body?.name};
 }
 if(action==='avatar'){
  const bytes=Uint8Array.from(atob(data.base64),c=>c.charCodeAt(0));
  const saved=await client.files.upload(new File([bytes],'sender-avatar.png',{type:'image/png'}),{purpose:'user_avatar',kind:'image'});
  await client.users.updateMe({avatar_url:saved.url});return{saved:true};
 }
 if(action==='refreshUsers'){await client.users.fetch(data.ids,{force:true});return true;}
 if(action==='nickname'){await client.users.updateMe({nickname:data.name});return true;}
 if(action==='avatarInfo')return{url:client.users.get(client.auth.currentUser.username)?.avatar_url};
 if(action==='cacheExists')return window.__TAURI_INTERNALS__.invoke('plugin:fs|exists',{path:data.path});
},{action,data});}
async function close(p){const d=p.getByRole('dialog');if(await d.isVisible())try{await d.getByRole('button',{name:'关闭',exact:true}).click({force:true,timeout:2000});}catch(e){if(await d.isVisible())throw e;}}
async function chat(p){await until(async()=>{await close(p);if(await input(p).isVisible())return input(p).isEnabled();const button=p.getByTestId('room-toolbar-region').getByRole('button',{name:'聊天',exact:true});if(await button.isVisible())try{await button.click({timeout:1000});await input(p).waitFor({timeout:2000});}catch(e){if(!await p.getByRole('dialog').isVisible())throw e;}return false;});}
async function mediaReady(p){let previous='';return until(async()=>{const s=await sdk(p,'session');const key=JSON.stringify(s);if(key!==previous){previous=key;fs.appendFileSync(path.join(out,'rtc-state-timeline.jsonl'),JSON.stringify({at:new Date().toISOString(),client:pages.indexOf(p),...s})+'\n');}return s.media==='connected'&&s.status==='joined'&&!await p.getByTestId('meeting-entry-loading').isVisible()&&!await p.getByRole('button',{name:'重试音视频',exact:true}).isVisible()?s:false;},45000).catch(e=>{throw Error(`${e.message}; last RTC state ${previous}`);});}
const message=(p,kind)=>p.getByTestId('im-meeting-message').filter({hasText:kind==='video'?'acceptance-video.mp4':'[语音]'}).filter({has:p.getByRole('button',{name:'回复',exact:true})}).last();
async function preview(p,kind,{play=true,error=false}={}){
 await close(p);
 await message(p,kind).getByRole('button',{name:'预览 / 播放',exact:true}).click();const d=p.getByRole('dialog');await d.waitFor();
 if(error){await d.getByRole('alert').waitFor();return{error:true};}
 const element=d.locator(kind==='video'?'video':'audio');await until(()=>element.evaluate(e=>e.readyState>=2&&Number.isFinite(e.duration)&&e.duration>=3&&(!e.videoWidth||e.videoWidth===640)));
 const result=await element.evaluate(async(e,play)=>{e.muted=true;if(play)await e.play();return{src:e.currentSrc,duration:e.duration,width:e.videoWidth??null,start:e.currentTime};},play);
 assert.match(result.src,/^http:\/\/drim-file.localhost\//);
 if(play){await until(()=>element.evaluate(e=>e.currentTime>0.7&&!e.paused));result.progress=await element.evaluate(e=>e.currentTime);await element.evaluate(e=>e.pause());}
 return result;
}
const protocol='http://drim-file.localhost/**';let intercepted=0;
const longName='IM Ready A · '+'跨部门会议发言人'.repeat(5);
const broken=route=>{intercepted++;return route.abort('failed');};
let sequence=0;
async function shot(p,label,size){const name=`${String(++sequence).padStart(2,'0')}-${size.width}x${size.height}-${label}.png`;await p.screenshot({path:path.join(out,'screenshots',name),animations:'disabled'});rows.push({operation:`capture ${label}`,expected:'actual visual review required',actual:{viewport:size},pass:true,screenshot:`screenshots/${name}`,visualPass:null});save();console.log(JSON.stringify(rows.at(-1)));}
try{
 for(let i=0;i<3;i++){const b=await chromium.connectOverCDP(`http://127.0.0.1:${9261+i}`);browsers.push(b);await prepareNativeInput(b.contexts()[0]);const p=b.contexts()[0].pages().find(p=>p.url().startsWith('http://localhost:3162')&&!p.url().includes('/im/'));assert.ok(p);pages.push(p);p.setDefaultTimeout(15000);p.on('console',async msg=>{if(msg.text().includes('[meeting RTC connection]')){const entry={client:i,at:new Date().toISOString(),diagnostic:await Promise.all(msg.args().map(a=>a.jsonValue().catch(()=>null)))};fs.appendFileSync(path.join(out,'rtc-diagnostics.jsonl'),JSON.stringify(entry)+'\n');console.log(JSON.stringify(entry));}});}
 const [host,member,third]=pages;
 if(confirmed){
  await step('all desktops preview confirmed server video rather than old failed outbox','every selected video message has sent actions and plays through native protocol',async()=>{const previews=[];for(const p of pages){await chat(p);assert.equal(await message(p,'video').getByRole('button',{name:'丢弃',exact:true}).count(),0);previews.push(await preview(p,'video'));await close(p);}return{confirmedMessages:3,previews};});
 }else if(extra){
  const base=JSON.parse(fs.readFileSync(path.join(out,'media-results.json'),'utf8'));assert.ok(base.rows.every(r=>r.pass));
  await step('closed video and voice previews release native cache files','all six native preview files recorded by real playback are absent after close',async()=>{const sources=base.rows.flatMap(r=>r.actual?.previews||[]).map(v=>decodeURIComponent(new URL(v.src).pathname.slice(1)));assert.equal(sources.length,6);for(const source of sources)await until(()=>!fs.existsSync(source));return{checked:6,removed:6};});
  await step('IM nickname updates and long sender names remain readable','all three clients display updated IM name; sender header fits viewport',async()=>{await sdk(host,'nickname',{name:longName});try{for(const p of pages){await chat(p);await sdk(p,'refreshUsers',{ids:[accounts[0].id]});const sender=p.getByTestId('message-sender-name').filter({hasText:longName}).first();await sender.waitFor();assert.ok(await sender.evaluate(e=>e.parentElement.scrollWidth<=e.parentElement.clientWidth+1));}}finally{await sdk(host,'nickname',{name:''});for(const p of pages)await sdk(p,'refreshUsers',{ids:[accounts[0].id]});}return{clients:3,characters:longName.length,restored:true};});
 }else if(!visual){
 if(process.argv.includes('--continue')){const row=previous.find(r=>r.operation==='cold load final native code and restore RTC on all clients'&&r.pass);assert.ok(row,'Continue requires preserved passed cold load evidence');rows.push({...row,reusedEvidence:true});for(const p of pages)await chat(p);}else{
 await step('cold load final native code and restore RTC on all clients','three real joined RTC sessions; no retry click',async()=>{for(const p of pages){if(new URL(p.url()).pathname!=='/room')await p.goto(`http://localhost:3162/room?code=${state.room.code}`,{waitUntil:'domcontentloaded'});else if(!process.argv.includes('--launched'))await p.reload({waitUntil:'domcontentloaded'});await chat(p);await mediaReady(p);}return{clients:3,retryClicks:0,freshlyLaunched:process.argv.includes('--launched')};});}
 await step('native sender avatar upload and profile display','real IM profile mapping; all sender names; avatar access failure has an initial fallback and is reported separately',async()=>{
  const image=fs.readFileSync(path.join(out,'native-screenshot.png')).toString('base64');await sdk(host,'avatar',{base64:image});
  const info=await until(async()=>{await sdk(host,'refreshUsers',{ids:[accounts[0].id]});const current=await sdk(host,'avatarInfo');return current.url?current:false;});
  const response=await fetch(info.url);const reachable=response.ok;const detail=reachable?'image accessible':(await response.text()).slice(0,900);
  const platform={operation:'real IM public avatar URL accessibility',expected:'uploaded avatar URL returns HTTP 200 image',actual:{status:response.status,detail},pass:reachable,screenshot:null};fs.writeFileSync(path.join(out,'platform-results.json'),JSON.stringify({rows:[platform]},null,2));
  for(const p of pages){await close(p);await sdk(p,'refreshUsers',{ids:accounts.map(a=>a.id)});for(let i=0;i<3;i++){
   const m=p.getByTestId('im-meeting-message').filter({hasText:`${state.marker}-${i}`}).last();await until(async()=>(await m.getByTestId('message-sender-name').innerText())===accounts[i].name);await close(p);await m.getByTestId('message-sender').getByRole('img').waitFor();
  }if(reachable)await until(()=>p.getByTestId('message-sender').locator('img').evaluateAll(imgs=>imgs.some(i=>i.complete&&i.naturalWidth>0)));else {await until(()=>p.getByTestId('message-sender').locator('img').count().then(n=>n===0));assert.ok((await p.getByTestId('message-sender').getByRole('img').first().innerText()).length>0);}}
  return{names:9,avatarDecodedClients:reachable?3:0,avatarHttpStatus:response.status,platformIssue:!reachable,fallback:'name initial verified; real avatar accessibility is a separate failed platform probe'};
 });
 await step('real meeting video upload and playback on three desktops','native IM/OSS upload; decoded 640x360 video advances time',async()=>{
  const video=path.join(out,'acceptance-video.mp4');
  if(!fs.existsSync(video))execFileSync(path.join(root,'frontend/src-tauri/binaries/ffmpeg-x86_64-pc-windows-msvc.exe'),['-hide_banner','-loglevel','error','-f','lavfi','-i','testsrc2=size=640x360:rate=24','-f','lavfi','-i','sine=frequency=440:sample_rate=48000','-t','5','-c:v','libx264','-pix_fmt','yuv420p','-c:a','aac','-movflags','+faststart',video],{windowsHide:true});
  await host.locator('input[type=file]').setInputFiles(video);
  const previews=[];for(const p of pages){await message(p,'video').waitFor({timeout:30000});previews.push(await preview(p,'video'));await close(p);}return{input:'synthetic FFmpeg test pattern and tone; no hardware capture',previews};
 });
 await step('real nameless WAV voice message and playback on three desktops','SDK uploads voice bytes; format wav retained and all audio timelines advance',async()=>{
  const samples=240000,wav=Buffer.alloc(44+samples*2);wav.write('RIFF');wav.writeUInt32LE(wav.length-8,4);wav.write('WAVEfmt ',8);wav.writeUInt32LE(16,16);wav.writeUInt16LE(1,20);wav.writeUInt16LE(1,22);wav.writeUInt32LE(48000,24);wav.writeUInt32LE(96000,28);wav.writeUInt16LE(2,32);wav.writeUInt16LE(16,34);wav.write('data',36);wav.writeUInt32LE(samples*2,40);for(let i=0;i<samples;i++)wav.writeInt16LE(Math.round(8000*Math.sin(2*Math.PI*550*i/48000)),44+i*2);
  const session=await invoke(host,'room_chat_session',{roomId:state.room.id});
  const sent=await sdk(host,'voice',{base64:wav.toString('base64'),group:session.groupId});assert.equal(sent.type,'voice');assert.equal(sent.format,'wav');assert.equal(sent.hasName,false);
  const previews=[];for(const p of pages){await message(p,'voice').waitFor({timeout:30000});const v=await preview(p,'voice');assert.match(v.src,/\.wav$/);previews.push(v);await close(p);}return{input:'synthetic PCM tone via public SDK send; meeting has no voice recording button',sent,previews};
 });
 await step('smoke media decode failure fixture separately','one explicitly intercepted local media request fails deterministically',async()=>{await host.context().route(protocol,broken);try{const v=await host.evaluate(()=>new Promise(resolve=>{const a=new Audio('http://drim-file.localhost/fixture-smoke.wav');a.onerror=()=>resolve('failed');a.oncanplay=()=>resolve('unexpected success');}));assert.equal(v,'failed');assert.equal(intercepted,1);return{intercepted,result:v};}finally{await host.context().unroute(protocol,broken);}});
 await step('video and voice decode errors recover after close and reopen','both show inline error; clearing fixture restores real playback',async()=>{for(const kind of ['video','voice']){await host.context().route(protocol,broken);try{await preview(host,kind,{error:true});await close(host);}finally{await host.context().unroute(protocol,broken);}await preview(host,kind);await close(host);}return{failedMediaRequests:intercepted-1,recovered:2,fault:'local protocol interception, not a real IM failure'};});
 await step('member leaves and immediately rejoins twice','same room reconnects each time with zero UI retry clicks',async()=>{const rounds=[];for(let i=0;i<2;i++){await member.getByTestId('room-toolbar-region').getByRole('button',{name:'离开会议',exact:true}).click();await member.getByRole('button',{name:'加入会议 输入会议号入会',exact:true}).waitFor();
   await member.getByRole('button',{name:'加入会议 输入会议号入会',exact:true}).click();const d=member.getByRole('dialog');for(let j=0;j<6;j++)await d.locator('input[inputmode="numeric"]').nth(j).fill(state.room.code[j]);for(const t of await d.getByRole('switch').all())if(await t.getAttribute('aria-checked')==='true')await t.click();const start=Date.now();await d.getByRole('button',{name:'加入会议',exact:true}).click();await chat(member);await mediaReady(member);rounds.push({elapsedMs:Date.now()-start,retryClicks:0});}return{rounds};});
 }else{
 const assertions=JSON.parse(fs.readFileSync(path.join(out,'media-results.json'),'utf8'));assert.ok(assertions.rows.length>=7&&assertions.rows.every(r=>r.pass),'Complete all assertion steps before screenshots');fs.mkdirSync(path.join(out,'screenshots'),{recursive:true});
 for(const size of [{width:1280,height:800},{width:520,height:760}]){
  for(const p of pages)await p.setViewportSize(size);
  await chat(host);await host.getByTestId('im-meeting-message').filter({hasText:`${state.marker}-0`}).last().scrollIntoViewIfNeeded();await shot(host,'聊天身份与附件',size);await chat(member);await member.getByTestId('im-meeting-message').filter({hasText:`${state.marker}-1`}).last().scrollIntoViewIfNeeded();await shot(member,'接收端身份',size);
  await sdk(host,'nickname',{name:longName});try{await sdk(host,'refreshUsers',{ids:[accounts[0].id]});const sender=host.getByTestId('message-sender-name').filter({hasText:longName}).last();await sender.waitFor();await sender.scrollIntoViewIfNeeded();await shot(host,'长姓名换行',size);}finally{await sdk(host,'nickname',{name:''});await sdk(host,'refreshUsers',{ids:[accounts[0].id]});}
  for(const kind of ['video','voice']){await preview(host,kind);await shot(host,kind==='video'?'视频播放成功':'语音播放成功',size);await close(host);await shot(host,kind==='video'?'视频关闭':'语音关闭',size);
   await host.context().route(protocol,broken);try{await preview(host,kind,{error:true});await shot(host,kind==='video'?'视频解码错误夹具':'语音解码错误夹具',size);await close(host);}finally{await host.context().unroute(protocol,broken);}
   await preview(host,kind);await shot(host,kind==='video'?'视频重试成功':'语音重试成功',size);await close(host);
  }
  await host.getByRole('button',{name:'会议文件',exact:true}).click();await host.getByRole('dialog').getByText(/acceptance-video.mp4/).first().waitFor();await shot(host,'文件弹窗打开',size);await host.getByRole('dialog').evaluate(e=>e.scrollTop=e.scrollHeight);await shot(host,'文件弹窗滚动',size);await close(host);
  await member.reload({waitUntil:'domcontentloaded'});await chat(member);
  try{await member.getByText('正在等待上一次音视频会话释放…',{exact:true}).waitFor({timeout:6000});await close(member);await shot(member,'RTC实际释放等待',size);}catch(error){if(!String(error).includes('Timeout'))throw error;rows.push({operation:'release wait capture availability',expected:'capture only when real service reports leaving',actual:'no visible leaving interval in this run; no simulated screenshot',pass:true,screenshot:null});save();}
  await mediaReady(member);
  fs.writeFileSync(path.join(out,'faults.json'),JSON.stringify({delay:3}));await member.reload({waitUntil:'domcontentloaded'});await member.getByText('正在加载会议…',{exact:true}).waitFor();await shot(member,'入会加载',size);fs.writeFileSync(path.join(out,'faults.json'),'{}');await chat(member);await mediaReady(member);await shot(member,'RTC恢复成功',size);
  fs.writeFileSync(path.join(out,'faults.json'),JSON.stringify({rtc:true}));await member.reload({waitUntil:'domcontentloaded'});await chat(member);await member.getByRole('button',{name:'重试音视频',exact:true}).waitFor();await shot(member,'RTC错误夹具',size);fs.writeFileSync(path.join(out,'faults.json'),'{}');await member.getByRole('button',{name:'重试音视频',exact:true}).click();await mediaReady(member);await shot(member,'RTC单次重试恢复',size);
 }
 }
}catch(e){console.error(e);process.exitCode=1;for(let i=0;i<pages.length;i++){const image=`media-failure-${Date.now()}-${i}.png`;await pages[i].screenshot({path:path.join(out,image)}).catch(()=>{});rows.push({operation:'failure evidence',pass:false,screenshot:image});}}
finally{fs.writeFileSync(path.join(out,'faults.json'),'{}');budget.usedMs=Date.now()-budget.firstStartedAt;fs.writeFileSync(budgetPath,JSON.stringify(budget,null,2));clearTimeout(watchdog);save();for(const b of browsers)await b.close();}
