import { testPython } from './local-tools.cjs';
import {navigateWithinApp} from './app-navigation.mjs';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {createRequire} from 'node:module';
import {fileURLToPath} from 'node:url';
import {execFileSync} from 'node:child_process';
import {prepareNativeInput} from './meeting-ready-input.mjs';
const root=fileURLToPath(new URL('../../',import.meta.url)),out=path.resolve(root,process.env.MEETING_READY_OUTPUT||'.artifacts/meeting-ready-im-sync');
fs.mkdirSync(out,{recursive:true});
const flags=value=>fs.writeFileSync(path.join(out,'faults.json'),JSON.stringify(value));
const results=[],browsers=[],pages=[];
const resultPath=path.join(out,process.argv.includes('--smoke')?'smoke-results.json':'native-results.json');
const previousResults=fs.existsSync(resultPath)?JSON.parse(fs.readFileSync(resultPath,'utf8')).results:[];
if(fs.existsSync(resultPath))fs.copyFileSync(resultPath,path.join(out,`${path.basename(resultPath,'.json')}-${Date.now()}.json`));
const save=()=>fs.writeFileSync(path.join(out,process.argv.includes('--smoke')?'smoke-results.json':'native-results.json'),JSON.stringify({results},null,2));
async function step(operation,expected,fn){const row={operation,expected,actual:null,pass:false,screenshot:null};try{row.actual=await fn();row.pass=true;}catch(e){row.actual=String(e.message);throw e;}finally{results.push(row);save();console.log(JSON.stringify(row));}}
async function api(method,route,body,token){const r=await fetch('http://127.0.0.1:3160/api/v1'+route,{method,headers:{'content-type':'application/json',...(token?{authorization:'Bearer '+token}:{})},body:body===undefined?undefined:JSON.stringify(body)});const text=await r.text();return{status:r.status,body:text?JSON.parse(text):null};}
if(process.argv.includes('--smoke')){
 let token,room;
 try{
  const account=JSON.parse(fs.readFileSync(path.join(out,'accounts.private.json'),'utf8'))[0];
  await step('fault fixture real password login','200 with session',async()=>{
   const r=await api('POST','/auth/login',{phone:account.phone,password:account.password,client:{client_id:'im-ready-smoke'}});assert.equal(r.status,200);token=r.body.token;assert.ok(token);return{status:r.status};
  });
  await step('fault fixture channel and chat outage','201 retains business room; chat endpoint returns 503',async()=>{
   flags({chat:true,rtc:true});const r=await api('POST','/rooms',{},token);assert.equal(r.status,201);room=r.body;
   const chat=await api('POST',`/rooms/${room.id}/chat-session`,{},token);assert.equal(chat.status,503);
   const media=await api('POST',`/rooms/${room.id}/media`,{},token);assert.equal(media.status,200);assert.equal(media.body.unavailableReason,'rtc_unavailable');
   return{roomCreated:true,chatStatus:chat.status,media:media.body.transport};
  });
  await step('fault fixture recovers without creating another room','same room grants IM and RTC after fault removal',async()=>{
   flags({});const chat=await api('POST',`/rooms/${room.id}/chat-session`,{},token);assert.equal(chat.status,200);
   const media=await api('POST',`/rooms/${room.id}/media`,{},token);assert.equal(media.status,200);assert.equal(media.body.transport,'dr-rtc');return{chatStatus:chat.status,transport:media.body.transport};
  });
 }finally{flags({});if(token&&room)await api('POST',`/rooms/${room.id}/end`,{},token);save();}
 process.exit(0);
}
const require=createRequire(new URL('../../frontend/package.json',import.meta.url));
const {chromium}=require('playwright');
for(const key of ['HTTP_PROXY','HTTPS_PROXY','ALL_PROXY','http_proxy','https_proxy','all_proxy'])delete process.env[key];
const budgetPath=path.join(out,'budget.json');
const budget=fs.existsSync(budgetPath)?JSON.parse(fs.readFileSync(budgetPath,'utf8')):{usedMs:0,limitMs:1800000};
budget.firstStartedAt ??= fs.existsSync(budgetPath)?fs.statSync(budgetPath).birthtimeMs:Date.now();
budget.usedMs=Math.max(budget.usedMs,Date.now()-budget.firstStartedAt);
const started=Date.now();assert.ok(budget.usedMs<budget.limitMs,'E2E debug budget exhausted');
const watchdog=setTimeout(()=>{save();process.exit(2);},budget.limitMs-budget.usedMs);
const invoke=(page,command,args={})=>page.evaluate(({command,args})=>window.__TAURI_INTERNALS__.invoke(command,args),{command,args});
const until=async(fn,timeout=20000)=>{const end=Date.now()+timeout;while(Date.now()<end){const v=await fn();if(v)return v;await new Promise(r=>setTimeout(r,100));}throw Error('Expected native state timed out');};
const quick=page=>page.getByRole('button',{name:'快速会议 立即发起一场会议',exact:true});
const textInput=page=>page.getByPlaceholder('发送消息，全体成员可见');
function roomCount(user){
 const source="import asyncio,asyncpg,sys\nasync def main():\n c=await asyncpg.connect('postgresql://openmeeting:openmeeting@127.0.0.1:55439/meeting_ready_meeting')\n print(await c.fetchval('SELECT count(*) FROM live_rooms WHERE host_user_id=$1',sys.argv[1]))\n await c.close()\nasyncio.run(main())";
 return Number(execFileSync(process.env.OPENMEETING_TEST_PYTHON||testPython(),['-c',source,user],{encoding:'utf8',windowsHide:true}).trim());
}
async function revealChat(page){const button=page.getByTestId('room-toolbar-region').getByRole('button',{name:'聊天',exact:true});await until(async()=>{if(await page.getByRole('dialog').isVisible())await closeDialog(page);return button.isVisible();});if(!await textInput(page).isVisible())await button.click();}
async function openChat(page){await revealChat(page);await until(()=>textInput(page).isEnabled());}
async function recoverMedia(page){
 const retry=page.getByRole('button',{name:'重试音视频',exact:true});let retries=0,last=0;
 await until(async()=>{
  if(await retry.isVisible()&&retries<3&&Date.now()-last>5000){await retry.click();retries++;last=Date.now();}
  return !await retry.isVisible()&&!await page.getByTestId('meeting-entry-loading').isVisible();
 },45000);
 if(process.env.RTC_SINGLE_RETRY==='1')assert.ok(retries<=1,`RTC required ${retries} UI retries`);
 return retries;
}
async function preview(page){await page.getByRole('button',{name:'预览 / 播放',exact:true}).last().click();const dialog=page.getByRole('dialog');await dialog.waitFor();await until(()=>dialog.locator('img').evaluateAll(images=>images.some(img=>img.complete&&img.naturalWidth===640&&img.naturalHeight===360)));return dialog;}
async function closeDialog(page){const dialog=page.getByRole('dialog');try{await dialog.getByRole('button',{name:'关闭',exact:true}).click({force:true,timeout:2000});}catch(error){if(await dialog.isVisible())throw error;}}
async function openSingle(page,id){await page.getByRole('button',{name:'新建会话',exact:true}).click();const d=page.getByRole('dialog');await d.getByLabel('用户 ID',{exact:true}).fill(id);await d.getByRole('button',{name:'创建',exact:true}).click();await page.getByPlaceholder('输入消息…').waitFor();}
async function permissionStep(host,third,room){await step('non-host cannot end meeting','real native IPC receives permission denial',async()=>{
 const result=await third.evaluate(async roomId=>{try{await window.__TAURI_INTERNALS__.invoke('room_end',{roomId});return{status:200};}catch(error){return{status:error.status,detail:error.detail};}},room.id);
 assert.equal(result.status,403);assert.equal((await invoke(host,'room_get',{roomId:room.id})).participants.length,3);return result;
});}
try{
 await step('connect three isolated native clients','native IPC, three engine windows and three UI windows',async()=>{
  for(let i=0;i<3;i++){
   const b=await chromium.connectOverCDP(`http://127.0.0.1:${9261+i}`);browsers.push(b);
   const context=b.contexts()[0];await prepareNativeInput(context);const page=context.pages().find(p=>p.url().startsWith('http://localhost:3162')&&!p.url().includes('/im/'));
   assert.ok(page);pages.push(page);page.setDefaultTimeout(20000);
   await context.addInitScript(()=>document.addEventListener('DOMContentLoaded',()=>{const style=document.createElement('style');style.textContent='*,*::before,*::after{animation-duration:0s!important;transition-duration:0s!important}';document.head.appendChild(style);}));
   assert.ok(await page.evaluate(()=>!!window.__TAURI_INTERNALS__));
  }
  return{clients:pages.length,targets:browsers.map(b=>b.contexts()[0].pages().map(p=>p.url()))};
 });
 if(process.argv.includes('--probe')){
  for(let i=0;i<pages.length;i++)console.log(JSON.stringify({client:i,body:(await pages[i].locator('body').innerText()).slice(0,1200)}));
 }else if(process.argv.includes('--permissions-only')){
  for(const row of previousResults.filter(r=>r.pass&&r.operation!=='connect three isolated native clients'))results.push({...row,reusedEvidence:true});
  await permissionStep(pages[0],pages[2],JSON.parse(fs.readFileSync(path.join(out,'room.json'),'utf8')));
 }else{
  const accounts=JSON.parse(fs.readFileSync(path.join(out,'accounts.private.json'),'utf8'));
  const [host,member,third]=pages;
  let room;
  if(!process.argv.includes('--resume')){
  await step('three native accounts sign in','real Rust IPC password authentication; Chinese UI ready',async()=>{
   for(let i=0;i<3;i++){
    const page=pages[i];await invoke(page,'complete_onboarding',{model:''});
    // Settle SDK resources from an interrupted prior test before hard navigation.
    await page.evaluate(async()=>{
     const element=[...document.querySelectorAll('*')].find(el=>Object.keys(el).some(k=>k.startsWith('__reactFiber')));
     if(!element)return;let fiber=element[Object.keys(element).find(k=>k.startsWith('__reactFiber'))];while(fiber.return)fiber=fiber.return;
     const queue=[fiber],seen=new Set();while(queue.length){const f=queue.pop();if(!f||seen.has(f))continue;seen.add(f);const props=f.memoizedProps,c=props?.client||props?.value?.client;
      if(c?.channels&&c?.messages){await c.channels.current?.leave();return;}queue.push(f.child,f.sibling);
     }
    });
    if(i===0&&fs.existsSync(path.join(out,'room.json'))){
     const prior=JSON.parse(fs.readFileSync(path.join(out,'room.json'),'utf8'));
     await invoke(page,'room_end',{roomId:prior.id}).catch(()=>{});
    }
    if(new URL(page.url()).pathname==='/room'){
     try{const previous=await invoke(page,'room_get_code',{code:new URL(page.url()).searchParams.get('code')});
      const currentUser=await invoke(page,'auth_get_user');
      if(previous.participants.some(p=>p.userId===currentUser?.id&&p.isHost))await invoke(page,'room_end',{roomId:previous.id});
      else await invoke(page,'room_leave',{roomId:previous.id});
     }catch{} // prior test room can already be ended
    }
    const currentUser=await invoke(page,'auth_get_user');
    if(currentUser&&currentUser.id!==accounts[i].id)await invoke(page,'auth_logout');
    if(new URL(page.url()).pathname!=='/')await page.goto('http://localhost:3162/',{waitUntil:'domcontentloaded'});
    await page.evaluate(()=>localStorage.setItem('dr.locale','zh-CN'));await page.reload({waitUntil:'domcontentloaded'});
    if(!(await invoke(page,'server_get_config')).loggedIn){
     await page.locator('#phone-auth-phone').fill(accounts[i].phone);
     await page.locator('#phone-auth-password').fill(accounts[i].password);
     await page.locator('form').getByRole('button',{name:'登录',exact:true}).click();
    }
    await quick(page).waitFor({timeout:60000});
    assert.equal((await invoke(page,'auth_get_user')).id,accounts[i].id);
   }
   return{clients:3,auth:'native IPC / real gateway / isolated user DB'};
  });
  await step('quick meeting prepares once immediately','visible preparing state; duplicate clicks create one room',async()=>{
   flags({delay:3});
   const before=roomCount(accounts[0].id);
   await quick(host).evaluate(button=>{button.click();button.click();});await host.getByTestId('meeting-entry-loading').waitFor();
   await until(()=>new URL(host.url()).searchParams.get('code'),45000);flags({});
   room=await invoke(host,'room_get_code',{code:new URL(host.url()).searchParams.get('code')});
   assert.equal(roomCount(accounts[0].id),before+1);
   await openChat(host);return{roomId:room.id,createCalls:1};
  });
  fs.writeFileSync(path.join(out,'room.json'),JSON.stringify(room,null,2));
  }else{
   room=JSON.parse(fs.readFileSync(path.join(out,'room.json'),'utf8'));
   for(const operation of ['three native accounts sign in','quick meeting prepares once immediately']){
    const row=previousResults.find(r=>r.operation===operation&&r.pass);assert.ok(row,'Resume requires prior passed preparation');results.push({...row,reusedEvidence:true});
   }
   for(const page of pages)await openChat(page);
  }
  await step('two members join same native meeting','all three see chat and real RTC connects',async()=>{
   for(const page of [member,third]){
    if(new URL(page.url()).searchParams.get('code')===room.code){await openChat(page);continue;}
    await page.getByRole('button',{name:'加入会议 输入会议号入会',exact:true}).click();const d=page.getByRole('dialog');
    for(let i=0;i<6;i++)await d.locator('input[inputmode="numeric"]').nth(i).fill(room.code[i]);
    for(const toggle of await d.getByRole('switch').all())if(await toggle.getAttribute('aria-checked')==='true')await toggle.click();
    await d.getByRole('button',{name:'加入会议',exact:true}).click();await openChat(page);
   }
   await until(async()=>(await invoke(host,'room_get',{roomId:room.id})).participants.length===3);
   for(const page of pages)await recoverMedia(page);
   return{participants:3,rtc:'connected in three native WebViews',chat:'ready'};
  });
  const marker=`native-${Date.now()}`;
  await step('three-way live messages stay visible after acknowledgement','each user sends; all users see each text without refresh or disappearing',async()=>{
   for(let i=0;i<3;i++){
    const text=`${marker}-${i}`;const page=pages[i];
    await textInput(page).fill(text);await page.getByRole('button',{name:'发送',exact:true}).click();
    for(const other of pages)await other.getByText(text,{exact:true}).waitFor({timeout:10000});
    await page.evaluate(text=>{window.__continuity={missing:0,samples:0};window.__continuityTimer=setInterval(()=>{window.__continuity.samples++;if(![...document.querySelectorAll('[data-testid="im-meeting-message"]')].some(el=>el.textContent.includes(text)))window.__continuity.missing++;},30);},text);
    await new Promise(r=>setTimeout(r,2000));
    const continuity=await page.evaluate(()=>{clearInterval(window.__continuityTimer);return window.__continuity;});assert.equal(continuity.missing,0);assert.ok(continuity.samples>10);
   }
   return{messages:3,deliveries:9,ackContinuity:'3 × 2 seconds, 30ms samples'};
  });
  const image=await host.evaluate(()=>{const c=document.createElement('canvas');c.width=640;c.height=360;const x=c.getContext('2d');x.fillStyle='#1365d6';x.fillRect(0,0,640,360);x.fillStyle='#ffffff';x.font='32px sans-serif';x.fillText('Native IM screenshot preview',45,120);x.fillStyle='#15b8a6';x.fillRect(45,175,550,120);return c.toDataURL('image/png').split(',')[1];});
  const imagePath=path.join(out,'native-screenshot.png');fs.writeFileSync(imagePath,Buffer.from(image,'base64'));
  await step('native image upload and preview on all three clients','real IM/OSS upload; native cached image decodes 640 × 360',async()=>{
   await host.locator('input[type=file]').setInputFiles(imagePath);
   for(const page of pages){await page.getByText(/native-screenshot.png/).first().waitFor({timeout:30000});const d=await preview(page);assert.match(await d.locator('img').getAttribute('src'),/^http:\/\/drim-file.localhost\//);await closeDialog(page);}
   return{upload:'Rust SDK -> real OSS',previews:3,width:640,height:360};
  });
  await step('direct conversation rename retains first message','new private chat sends and reply appears in both native clients',async()=>{
   const peer=third;
   for(const page of [host,peer]){await page.getByRole('button',{name:'返回首页',exact:true}).click();await navigateWithinApp(page,'/chats');await page.getByRole('button',{name:'新建会话',exact:true}).waitFor({timeout:30000});}
   await openSingle(host,accounts[2].id);await openSingle(peer,accounts[0].id);
   for(const [sender,receiver,text]of[[host,peer,`${marker}-private-first`],[peer,host,`${marker}-private-reply`]]){
    await sender.getByPlaceholder('输入消息…').fill(text);await sender.getByRole('button',{name:'发送',exact:true}).click();
    await receiver.getByText(text,{exact:true}).last().waitFor({timeout:10000});await sender.getByText(text,{exact:true}).last().waitFor();
    await new Promise(r=>setTimeout(r,1500));assert.ok(await sender.getByText(text,{exact:true}).last().isVisible());
   }
   for(const page of [host,peer]){await page.getByTestId('return-meeting').click();await openChat(page);}
   return{privateMessages:2,persistentMeeting:'survived navigation on both clients'};
  });
  await step('history restores after native UI reload','third client reloads and sees all group texts and image',async()=>{
   await third.reload({waitUntil:'domcontentloaded'});await openChat(third);
   for(let i=0;i<3;i++)await third.getByText(`${marker}-${i}`,{exact:true}).waitFor();await preview(third);await closeDialog(third);
   return{historyMessages:3,imagePreview:true};
  });
  fs.writeFileSync(path.join(out,'success-state.json'),JSON.stringify({room,marker},null,2));
  await step('native chat and RTC failure then retry','same meeting shows explicit errors; both recover through UI buttons',async()=>{
   flags({chat:true,rtc:true});await member.reload({waitUntil:'domcontentloaded'});
   await revealChat(member);
   await member.getByRole('button',{name:'重试',exact:true}).waitFor();await member.getByRole('button',{name:'重试音视频',exact:true}).waitFor();
   assert.equal(await textInput(member).isEnabled(),false);
   flags({});await member.getByRole('button',{name:'重试',exact:true}).click();
   await until(()=>textInput(member).isEnabled());const rtcRetries=await recoverMedia(member);
   await member.getByText(`${marker}-0`,{exact:true}).waitFor();
   return{fault:'isolated server fixture, not a live outage',roomId:room.id,chatRecovered:true,rtcRecovered:true,rtcRetries};
  });
  await permissionStep(host,third,room);
 }
}catch(error){console.error(error);process.exitCode=1;for(let i=0;i<pages.length;i++){const file=`failure-${Date.now()}-${i}.png`;await pages[i].screenshot({path:path.join(out,file)}).catch(()=>{});results.push({operation:'failure evidence',pass:false,screenshot:file});}}
finally{flags({});clearTimeout(watchdog);budget.usedMs+=Date.now()-started;fs.writeFileSync(budgetPath,JSON.stringify(budget,null,2));save();for(const b of browsers)await b.close();}
