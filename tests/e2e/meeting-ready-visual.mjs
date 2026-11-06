import {navigateWithinApp} from './app-navigation.mjs';
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
import {fileURLToPath} from 'node:url';
import {prepareNativeInput} from './meeting-ready-input.mjs';
const root=fileURLToPath(new URL('../../',import.meta.url)),out=path.resolve(root,process.env.MEETING_READY_OUTPUT||'.artifacts/meeting-ready-im-sync');
const native=JSON.parse(fs.readFileSync(path.join(out,'native-results.json'),'utf8'));
assert.ok(native.results.length>=10&&native.results.every(r=>r.pass),'Complete native assertions before visual capture');
const budgetPath=path.join(out,'budget.json'),budget=JSON.parse(fs.readFileSync(budgetPath,'utf8'));
assert.ok(Date.now()-budget.firstStartedAt<budget.limitMs,'E2E budget exhausted');
const require=createRequire(new URL('../../frontend/package.json',import.meta.url)),{chromium}=require('playwright');
const resultPath=path.join(out,'visual-results.json');
if(fs.existsSync(resultPath))fs.copyFileSync(resultPath,path.join(out,`visual-results-${Date.now()}.json`));
const rows=[],browsers=[],pages=[];
const state=JSON.parse(fs.readFileSync(path.join(out,'success-state.json'),'utf8'));
const save=()=>fs.writeFileSync(resultPath,JSON.stringify({rows},null,2));
const flags=v=>fs.writeFileSync(path.join(out,'faults.json'),JSON.stringify(v));
const invoke=(p,cmd,args={})=>p.evaluate(({cmd,args})=>window.__TAURI_INTERNALS__.invoke(cmd,args),{cmd,args});
const until=async(fn,ms=20000)=>{const end=Date.now()+ms;while(Date.now()<end){if(await fn())return;await new Promise(r=>setTimeout(r,100));}throw Error('Expected visual state timed out');};
async function step(operation,expected,fn){const row={operation,expected,actual:null,pass:false,screenshot:null};try{row.actual=await fn();row.pass=true;}catch(error){row.actual=error.message;throw error;}finally{rows.push(row);save();console.log(JSON.stringify(row));}}
async function close(p){const d=p.getByRole('dialog');if(await d.isVisible())try{await d.getByRole('button',{name:'关闭',exact:true}).click({force:true,timeout:2000});}catch(error){if(await d.isVisible())throw error;}}
const input=p=>p.getByPlaceholder('发送消息，全体成员可见');
const fileName=p=>p.getByRole('dialog').getByText(/native-screenshot.png/).first();
async function chat(p,ready=true){await until(async()=>{await close(p);return p.getByTestId('room-toolbar-region').getByRole('button',{name:'聊天',exact:true}).isVisible();});if(!await input(p).isVisible())await p.getByTestId('room-toolbar-region').getByRole('button',{name:'聊天',exact:true}).click();if(ready)await until(()=>input(p).isEnabled());}
async function preview(p,expectError=false){await p.getByTestId('im-meeting-message').filter({hasText:'native-screenshot.png'}).last().getByRole('button',{name:'预览 / 播放',exact:true}).click();const d=p.getByRole('dialog');await d.waitFor();if(expectError)await d.getByRole('alert').waitFor();else await until(()=>d.locator('img').evaluateAll(images=>images.some(i=>i.complete&&i.naturalWidth===640)));}
async function emptyPrivate(p){
 await p.getByRole('button',{name:'返回首页',exact:true}).click();await navigateWithinApp(p,'/chats');
 await p.getByRole('button',{name:'新建会话',exact:true}).click();const d=p.getByRole('dialog');
 const accounts=JSON.parse(fs.readFileSync(path.join(out,'accounts.private.json'),'utf8'));
 await d.getByLabel('用户 ID',{exact:true}).fill(accounts[2].id);await d.getByRole('button',{name:'创建',exact:true}).click();await p.getByPlaceholder('输入消息…').waitFor();
}
let sequence=0;
async function shot(p,label,size){const filename=`${String(++sequence).padStart(2,'0')}-${size.width}x${size.height}-${label}.png`;await p.screenshot({path:path.join(out,'screenshots',filename),animations:'disabled'});const row={operation:`capture ${label}`,expected:'review actual screenshot for overlap, clipping, layers and responsive layout',actual:{viewport:size},pass:true,screenshot:`screenshots/${filename}`,visualPass:null};rows.push(row);save();console.log(JSON.stringify(row));}
try{
 for(let i=0;i<3;i++){const b=await chromium.connectOverCDP(`http://127.0.0.1:${9261+i}`);browsers.push(b);await prepareNativeInput(b.contexts()[0]);pages.push(b.contexts()[0].pages().find(p=>!p.url().includes('/im/')));pages[i].setDefaultTimeout(12000);}
 const [host,member,third]=pages;
 // Cold-load the final code once; Fast Refresh can replay effect cleanup while
 // the implementation is edited, which is not a user navigation/reload flow.
 for(const page of pages){
  if(new URL(page.url()).pathname!=='/room')await page.goto(`http://localhost:3162/room?code=${state.room.code}`,{waitUntil:'domcontentloaded'});
  else await page.reload({waitUntil:'domcontentloaded'});
  await chat(page);
 }
 await step('assert long message and meeting file drawer','real IM text wraps; group file list includes uploaded image; open/scroll/close succeeds',async()=>{
  const text='会议长文本验证：'.repeat(20);await chat(host);await input(host).fill(text);await host.getByRole('button',{name:'发送',exact:true}).click();for(const p of pages)await p.getByText(text,{exact:true}).last().waitFor();
  await host.getByRole('button',{name:'会议文件',exact:true}).click();await fileName(host).waitFor();await host.getByRole('dialog').evaluate(el=>el.scrollTop=el.scrollHeight);await close(host);return{characters:text.length,fileList:'real IM',closed:true};
 });
 const pattern='http://drim-file.localhost/**';let intercepted=0;
 const broken=route=>{intercepted++;return route.abort('failed');};
 await step('smoke preview error fixture independently','native local image protocol request is deterministically intercepted and fails',async()=>{
  await host.context().route(pattern,broken);
  const actual=await host.evaluate(()=>new Promise(resolve=>{const image=new Image();image.onload=()=>resolve('loaded');image.onerror=()=>resolve('failed');image.src='http://drim-file.localhost/fixture-probe';}));
  assert.equal(actual,'failed');assert.equal(intercepted,1);return{intercepted,outcome:actual};
 });
 await step('assert preview decode failure and recovery','error is visible in image dialog; closing and retrying recovers',async()=>{
  try{await preview(host,true);assert.ok(intercepted>=2);await close(host);}finally{await host.context().unroute(pattern,broken);}
  await preview(host);await close(host);return{fault:'explicit local image-request fixture; not an IM outage',recovered:true};
 });
 await step('assert waiting member has no chat grant','wait room enforces business and IM membership boundary',async()=>{
  await invoke(host,'room_patch',{roomId:state.room.id,waitRoom:true});await invoke(third,'room_leave',{roomId:state.room.id});
  await third.goto(`http://localhost:3162/room?code=${state.room.code}`,{waitUntil:'domcontentloaded'});
  await third.getByText('您已进入等待室',{exact:true}).waitFor();
  let denied=false;try{await invoke(third,'room_chat_session',{roomId:state.room.id});}catch{denied=true;}assert.ok(denied);
  const snapshot=await invoke(host,'room_get',{roomId:state.room.id});const waiting=snapshot.waiting[0];assert.ok(waiting);
  await invoke(host,'room_admit',{roomId:state.room.id,participantId:waiting.participantId});await chat(third);await invoke(host,'room_patch',{roomId:state.room.id,waitRoom:false});return{chatDenied:true,admitted:true};
 });
 await step('assert empty private conversation','opening an unused peer preserves an empty SDK message list',async()=>{
  await emptyPrivate(member);assert.equal(await member.locator('section span.whitespace-pre-wrap').count(),0);await member.getByTestId('return-meeting').click();await chat(member);return{messages:0};
 });
 fs.mkdirSync(path.join(out,'screenshots'),{recursive:true});
 // Capture only after all assertions above and the native suite passed.
 for(const size of [{width:1280,height:800},{width:520,height:760}]){
  for(const p of pages)await p.setViewportSize(size);
  flags({delay:4});await member.reload({waitUntil:'domcontentloaded'});await member.getByText('正在加载会议…',{exact:true}).waitFor();await shot(member,'入会加载',size);flags({});await chat(member);
  await chat(host);await shot(host,'三端会议聊天',size);await shot(member,'接收端消息',size);
  await preview(host);await shot(host,'截图预览成功',size);await close(host);await shot(host,'预览关闭后',size);
  await host.getByRole('button',{name:'会议文件',exact:true}).click();await fileName(host).waitFor();await shot(host,'会议文件弹窗',size);await host.getByRole('dialog').evaluate(el=>el.scrollTop=el.scrollHeight);await close(host);
  await host.context().route(pattern,broken);try{await preview(host,true);await shot(host,'截图预览错误夹具',size);await close(host);}finally{await host.context().unroute(pattern,broken);}
  flags({chat:true,rtc:true});await member.reload({waitUntil:'domcontentloaded'});await chat(member,false);await member.getByRole('button',{name:'重试',exact:true}).waitFor();await member.getByRole('button',{name:'重试音视频',exact:true}).waitFor();await shot(member,'聊天音视频错误夹具',size);
  flags({});await member.getByRole('button',{name:'重试',exact:true}).click();await member.getByRole('button',{name:'重试音视频',exact:true}).click();await chat(member);await shot(member,'故障重试恢复',size);
  await invoke(host,'room_patch',{roomId:state.room.id,waitRoom:true});await invoke(third,'room_leave',{roomId:state.room.id});await third.goto(`http://localhost:3162/room?code=${state.room.code}`,{waitUntil:'domcontentloaded'});await third.getByText('您已进入等待室',{exact:true}).waitFor();await shot(third,'等候入会权限',size);
  const snapshot=await invoke(host,'room_get',{roomId:state.room.id});await invoke(host,'room_admit',{roomId:state.room.id,participantId:snapshot.waiting[0].participantId});await chat(third);await invoke(host,'room_patch',{roomId:state.room.id,waitRoom:false});
  await emptyPrivate(member);await shot(member,'空私聊',size);await member.getByTestId('return-meeting').click();await chat(member);
 }
}catch(error){console.error(error);process.exitCode=1;for(let i=0;i<pages.length;i++){const file=`visual-failure-${Date.now()}-${i}.png`;await pages[i].screenshot({path:path.join(out,file)}).catch(()=>{});rows.push({operation:'failure evidence',pass:false,screenshot:file});}}
finally{flags({});budget.usedMs=Date.now()-budget.firstStartedAt;fs.writeFileSync(budgetPath,JSON.stringify(budget,null,2));save();for(const b of browsers)await b.close();}
