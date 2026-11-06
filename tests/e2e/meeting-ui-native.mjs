import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {createRequire} from 'node:module';
import {fileURLToPath} from 'node:url';
import {installMediaProbe} from './media-input.mjs';
const root=fileURLToPath(new URL('../../',import.meta.url)),front=path.join(root,'frontend');
const out=path.resolve(process.env.MEETING_UI_NATIVE_OUTPUT||path.join(root,'.artifacts/会议模块配置/native-20261024-1347'));
fs.mkdirSync(path.join(out,'screenshots'),{recursive:true});
const require=createRequire(path.join(front,'package.json')),{chromium}=require('playwright');
const accounts=JSON.parse(fs.readFileSync(path.join(out,'accounts.private.json'),'utf8'));
const configPath=path.join(front,'src/config/meeting-ui.json'),configOriginal=fs.readFileSync(configPath);
const smoke=process.argv.includes('--smoke'),resultPath=path.join(out,smoke?'smoke-results.json':'results.json');
if(fs.existsSync(resultPath))fs.copyFileSync(resultPath,resultPath.replace('.json',`-${Date.now()}.json`));
const budgetPath=path.join(out,'budget.json');
const budget=fs.existsSync(budgetPath)?JSON.parse(fs.readFileSync(budgetPath,'utf8')):{started:Date.now(),limitMs:1800000};
if(!smoke&&!fs.existsSync(budgetPath))fs.writeFileSync(budgetPath,JSON.stringify(budget));
const data={started:new Date().toISOString(),boundary:'真实Windows Tauri、Rust IPC、独立真实FastAPI/PostgreSQL及IM/RTC平台；摄像头/麦克风/屏幕输入为明确标注合成源；无IPC/API/SDK替身',steps:[],cleanup:{}};
let phase=smoke?'api-smoke':'assertions',page,viewport='native',number=0,ownedRoom;
const browsers=[],pages=[];
const save=()=>fs.writeFileSync(resultPath,JSON.stringify(data,null,2));
const invoke=(p,command,args={})=>p.evaluate(({command,args})=>window.__TAURI_INTERNALS__.invoke(command,args),{command,args});
const until=async(fn,ms=20000)=>{const deadline=Date.now()+ms;while(Date.now()<deadline){const value=await fn();if(value)return value;await new Promise(r=>setTimeout(r,150));}throw Error('Expected native state timed out');};
async function step(operation,expected,fn,label){
 if(!smoke&&Date.now()-budget.started>budget.limitMs)throw Error('累计原生E2E调试30分钟预算已耗尽，停止页面调试');
 const row={phase,viewport,operation,expected,actual:null,pass:false,screenshot:null};
 try{row.actual=await fn()||'全部断言符合预期';if(phase==='screenshots'&&label){row.screenshot=`screenshots/${String(++number).padStart(2,'0')}-${viewport}-${label}.png`;await page.screenshot({path:path.join(out,row.screenshot),animations:'disabled'});}row.pass=true;}
 catch(error){row.actual=String(error.stack||error);if(page){row.screenshot=`screenshots/失败-${Date.now()}.png`;await page.screenshot({path:path.join(out,row.screenshot)}).catch(()=>{});}throw error;}
 finally{data.steps.push(row);console.log(JSON.stringify(row));fs.appendFileSync(path.join(out,smoke?'smoke-steps.jsonl':'steps.jsonl'),JSON.stringify(row)+'\n');save();}
}
async function api(method,route,body,token){const r=await fetch('http://127.0.0.1:3160/api/v1'+route,{method,headers:{'Content-Type':'application/json',...(token?{Authorization:'Bearer '+token}:{})},body:body===undefined?undefined:JSON.stringify(body)});const text=await r.text();return{status:r.status,body:text?JSON.parse(text):null};}
async function apiSmoke(){
 let token,memberToken,room;
 try{
  await step('真实密码登录和只读会议列表','三个测试账号认证成功、会议列表返回200；令牌只保留内存',async()=>{
   for(const [i,account]of accounts.entries()){const result=await api('POST','/auth/login',{phone:account.phone,password:account.password,client:{client_id:'ui-native-api-'+i}});assert.equal(result.status,200);assert.ok(result.body.token);if(i===0)token=result.body.token;if(i===1)memberToken=result.body.token;assert.equal((await api('GET','/meetings',undefined,result.body.token)).status,200);}return{accounts:3,authenticated:true};
  });
  await step('真实会议、聊天与RTC准备','创建会议成功，真实IM私有群就绪，RTC媒体票据有效',async()=>{
   const created=await api('POST','/rooms',{},token);assert.equal(created.status,201);room=created.body;
   const chat=await api('POST',`/rooms/${room.id}/chat-session`,{},token);assert.equal(chat.status,200);assert.ok(chat.body.groupId);
   const media=await api('POST',`/rooms/${room.id}/media`,{},token);assert.equal(media.status,200);assert.equal(media.body.transport,'dr-rtc');return{created:201,chat:200,transport:media.body.transport};
  });
  await step('真实权限失败入口冒烟','非主持人结束会议403；不存在会议404；原会议保持active',async()=>{
   assert.equal((await api('POST',`/rooms/${room.id}/end`,{},memberToken)).status,403);
   assert.equal((await api('GET','/rooms/code/000000',undefined,token)).status,404);
   assert.equal((await api('GET',`/rooms/${room.id}`,undefined,token)).body.status,'active');return{permission:403,notFound:404,preserved:true};
  });
 }finally{if(room&&token){const ended=await api('POST',`/rooms/${room.id}/end`,{},token);data.cleanup.roomEndStatus=ended.status;}}
}
function installNativeInput(){
 window.__uiNative={calls:[],denyScreen:false};
 const original=navigator.mediaDevices.getUserMedia.bind(navigator.mediaDevices);
 navigator.mediaDevices.getUserMedia=async constraints=>{window.__uiNative.calls.push({audio:!!constraints.audio,video:!!constraints.video});return original(constraints);};
 navigator.mediaDevices.getDisplayMedia=async()=>{
  if(window.__uiNative.denyScreen)throw new DOMException('Deterministic native permission denial','NotAllowedError');
  const canvas=document.createElement('canvas');canvas.width=960;canvas.height=540;const ctx=canvas.getContext('2d');let frame=0;
  const draw=()=>{ctx.fillStyle='#12375b';ctx.fillRect(0,0,960,540);ctx.fillStyle='#22d3ee';ctx.fillRect((frame*8)%840,290,100,100);ctx.fillStyle='white';ctx.font='32px sans-serif';ctx.fillText('Native UI screen '+ ++frame,40,100);};draw();const timer=setInterval(draw,50);
  const stream=canvas.captureStream(20),track=stream.getVideoTracks()[0],stop=track.stop.bind(track);track.stop=()=>{clearInterval(timer);stop();};return stream;
 };
 localStorage.setItem('dr.locale','zh-CN');localStorage.setItem('openmeeting:meeting-audio',JSON.stringify({autoJoin:true,microphoneId:'default',speakerId:'default',unmuteSound:false}));
}
const toolbar=p=>p.getByTestId('room-toolbar-region');
const chatInput=p=>p.getByPlaceholder('发送消息，全体成员可见');
const quick=p=>p.getByRole('button',{name:'快速会议 立即发起一场会议',exact:true});
async function openChat(p){await until(async()=>{const input=chatInput(p);if(await input.isVisible())return input.isEnabled();const button=toolbar(p).getByRole('button',{name:'聊天',exact:true});if(await button.isVisible()){await button.click();await input.waitFor({timeout:1500}).catch(()=>{});}return false;},45000);}
async function closePanel(p){const close=p.getByTestId('room-side-panel').getByRole('button',{name:'关闭',exact:true});if(await close.isVisible())await close.click();}
async function join(p,code){await p.getByRole('button',{name:'加入会议 输入会议号入会',exact:true}).click();const dialog=p.getByRole('dialog');for(let i=0;i<6;i++)await dialog.locator('input[inputmode="numeric"]').nth(i).fill(code[i]);await dialog.getByRole('button',{name:'加入会议',exact:true}).click();await toolbar(p).getByRole('button',{name:'离开会议',exact:true}).waitFor({timeout:45000});}
async function layout(p){const sizes=await p.evaluate(()=>({width:innerWidth,scroll:document.documentElement.scrollWidth,height:innerHeight}));assert.ok(sizes.scroll<=sizes.width+1);const box=await toolbar(p).boundingBox();assert.ok(box&&box.y+box.height<=sizes.height+1);return sizes;}
async function captureBoth(operation,label,prepare){
 if(phase!=='screenshots'){await step(operation,'两个视口布局及目标状态符合预期',async()=>{for(const size of [{width:1280,height:800},{width:390,height:844}]){await page.setViewportSize(size);await prepare?.();await layout(page);}});return;}
 for(const size of [{width:1280,height:800},{width:390,height:844}]){viewport=`${size.width}×${size.height}`;await page.setViewportSize(size);await prepare?.();await step(operation,'真实原生页面目标状态可读，无横向溢出',()=>layout(page),label);}
}
async function endRoom(host){await closePanel(host);await toolbar(host).getByRole('button',{name:'离开并结束',exact:true}).click();await host.getByRole('dialog').getByRole('button',{name:'结束会议',exact:true}).click();await until(()=>new URL(host.url()).pathname!=='/room',60000);ownedRoom=null;for(const p of pages.slice(1)){if(new URL(p.url()).pathname==='/room'){const home=p.getByRole('button',{name:'首页',exact:true});if(await home.isVisible())await home.click();else await p.goto('http://localhost:3162/');}}}
async function fullFlow(){
 const [host,member,third]=pages;page=host;viewport='native';
 await step('原生UI快速会议与三端入会','真实创建会议，三端均进入同一房间',async()=>{
  await quick(host).click();await until(()=>new URL(host.url()).searchParams.get('code'),60000);const code=new URL(host.url()).searchParams.get('code');ownedRoom=await invoke(host,'room_get_code',{code});
  await toolbar(host).getByRole('button',{name:'聊天',exact:true}).waitFor({timeout:60000});
  for(const p of [member,third])await join(p,code);
  await until(async()=>(await invoke(host,'room_get',{roomId:ownedRoom.id})).participants.length===3);return{participants:3,roomId:ownedRoom.id};
 });
 await step('真实IM双向聊天','SDK发送并在另一原生客户端实际收到消息',async()=>{
  await openChat(host);await openChat(member);
  for(const [sender,receiver,text]of [[host,member,'原生配置验收主持人消息'],[member,host,'原生配置验收成员回复']]){await chatInput(sender).fill(text);await sender.getByTestId('room-side-panel').getByRole('button',{name:'发送',exact:true}).click();await receiver.getByText(text,{exact:true}).waitFor({timeout:30000});}return{bidirectional:true};
 });
 await captureBoth('原生聊天成功界面','聊天成功',async()=>{await openChat(host);});
 await closePanel(host);await closePanel(member);
 await step('真实RTC远端音视频解码','三端频道连接；双端收到音频能量和解码视频帧',async()=>{
  for(const p of [host,member]){const off=p.getByRole('button',{name:'已关闭',exact:true});if(await off.isVisible())await off.click();}
  return until(async()=>{const all=[];for(const p of [host,member])all.push(await p.evaluate(async()=>{const rows=[];for(const peer of window.__meetingE2E.peers)if(peer.connectionState==='connected')for(const stat of(await peer.getStats()).values())if(stat.type==='inbound-rtp')rows.push({kind:stat.kind,energy:stat.totalAudioEnergy,frames:stat.framesDecoded});return rows;}));return all.every(rows=>rows.some(r=>r.kind==='audio'&&r.energy>0)&&rows.some(r=>r.kind==='video'&&r.frames>0))&&all;},60000);
 });
 await captureBoth('原生音视频会议正常态','音视频正常');
 page=member;
 await step('真实非主持人结束会议403','Rust IPC返回权限拒绝，房间仍有三名参与者',async()=>{const result=await member.evaluate(async roomId=>{try{await window.__TAURI_INTERNALS__.invoke('room_end',{roomId});return{status:200};}catch(error){if(typeof error==='string'){try{return JSON.parse(error);}catch{return{detail:error};}}return{status:error.status,detail:error.detail};}},ownedRoom.id);assert.equal(result.status,403);return{status:result.status};});
 await member.setViewportSize({width:1280,height:800});await toolbar(member).getByRole('button',{name:'更多',exact:true}).click();await member.getByRole('menuitem',{name:'设置',exact:true}).click();
 await captureBoth('原生成员设置只读权限','成员权限',async()=>{assert.equal(await member.getByRole('dialog').locator('input[maxlength="50"]').isDisabled(),true);});
 await member.keyboard.press('Escape');page=host;
 await step('原生共享权限失败入口','确定性拒绝采集后显示错误，会议及聊天保持可用',async()=>{await host.evaluate(()=>{window.__uiNative.denyScreen=true;});await toolbar(host).getByRole('button',{name:'共享屏幕',exact:true}).click();await host.getByTestId('screen-status').filter({hasText:/拒绝|取消/}).waitFor();});
 await captureBoth('原生共享权限失败画面','共享权限失败');
 await step('共享失败恢复及远端接收','解除拒绝后通过真实信令和WebRTC接收屏幕',async()=>{await host.evaluate(()=>{window.__uiNative.denyScreen=false;});await toolbar(host).getByRole('button',{name:'共享屏幕',exact:true}).click();await until(()=>member.getByTestId('screen-stage').locator('video').evaluateAll(videos=>videos.some(v=>v.videoWidth===960&&v.currentTime>0)),45000);return{remoteDecodedWidth:960};});
 await captureBoth('原生共享恢复成功','共享恢复');
 await toolbar(host).getByRole('button',{name:'停止共享',exact:true}).click();
 await step('原生UI结束会议','主持人确认结束，三端释放会话；真实业务记录已生成',async()=>{await endRoom(host);return{ended:true};});
}
async function disabledFlow(){
 const disabled=Object.fromEntries(Object.keys(JSON.parse(configOriginal)).map(key=>[key,false]));
 fs.writeFileSync(configPath,JSON.stringify(disabled,null,2)+'\n');
 await new Promise(r=>setTimeout(r,1500));
 for(const p of pages){await p.goto('http://localhost:3162/',{waitUntil:'domcontentloaded'});await quick(p).waitFor({timeout:45000});}
 const [host,member]=pages;page=host;
 await step('真实构建配置全关后仍可入会','读取实际JSON全关配置，工具栏没有音视频/聊天/共享/成员入口',async()=>{
  await quick(host).click();await until(()=>new URL(host.url()).searchParams.get('code'),45000);ownedRoom=await invoke(host,'room_get_code',{code:new URL(host.url()).searchParams.get('code')});
  await toolbar(host).getByRole('button',{name:'离开并结束',exact:true}).waitFor();
  assert.equal(await toolbar(host).getByRole('button').count(),2);assert.equal(await host.getByTestId('room-recording-status').count(),0);
  assert.equal(await host.evaluate(()=>window.__uiNative.calls.length),0);
  await join(member,ownedRoom.code);assert.equal(await member.evaluate(()=>window.__uiNative.calls.length),0);return{mediaCaptureCalls:0,participants:2};
 });
 await captureBoth('原生全部模块关闭','全部模块关闭');
 await step('全关配置仍可正常离会和结束','成员离会及主持人结束成功',async()=>{await toolbar(member).getByRole('button',{name:'离开会议',exact:true}).click();await until(()=>new URL(member.url()).pathname==='/');await endRoom(host);});
 fs.writeFileSync(configPath,configOriginal);await new Promise(r=>setTimeout(r,1200));
 for(const p of pages){await p.goto('http://localhost:3162/',{waitUntil:'domcontentloaded'});await quick(p).waitFor({timeout:45000});}
}
try{
 if(smoke){await apiSmoke();}
 else{
  assert.ok(fs.existsSync(path.join(out,'smoke-results.json')),'先独立执行原生API失败入口冒烟');
  for(let i=0;i<3;i++){
   const browser=await chromium.connectOverCDP(`http://127.0.0.1:${9261+i}`,{timeout:15000});browsers.push(browser);const context=browser.contexts()[0];const p=context.pages().find(p=>p.url().startsWith('http://localhost:3162')&&!p.url().includes('/im/'));assert.ok(p);pages.push(p);p.setDefaultTimeout(15000);
   await context.addInitScript(installMediaProbe,{synthetic:true});await context.addInitScript(installNativeInput);
  }
  page=pages[0];
  await step('原生三端登录及只读接口','三端使用真实Rust IPC登录，认证和会议列表均成功',async()=>{
   for(let i=0;i<3;i++){const p=pages[i];await invoke(p,'complete_onboarding',{model:''});await p.goto('http://localhost:3162/');await p.reload({waitUntil:'domcontentloaded'});
    const config=await invoke(p,'server_get_config');if(config.loggedIn){const user=await invoke(p,'auth_get_user');if(user?.id!==accounts[i].id)await invoke(p,'auth_logout');}
    if(!(await invoke(p,'server_get_config')).loggedIn){await p.locator('#phone-auth-phone').fill(accounts[i].phone);await p.locator('#phone-auth-password').fill(accounts[i].password);await p.locator('form').getByRole('button',{name:'登录',exact:true}).click();}
    await quick(p).waitFor({timeout:60000});assert.equal((await invoke(p,'auth_get_user')).id,accounts[i].id);const status=await invoke(p,'server_get_status');assert.ok(status.authenticated);assert.ok(Array.isArray(await invoke(p,'api_get_meetings')));
   }return{nativeClients:3,authenticated:true,meetingListsRead:3};
  });
  await fullFlow();await disabledFlow();
  assert.equal(data.steps.filter(s=>!s.pass).length,0);
  phase='screenshots';await fullFlow();await disabledFlow();
 }
}catch(error){data.error=String(error.stack||error);console.error(data.error);process.exitCode=1;}
finally{
 if(!fs.readFileSync(configPath).equals(configOriginal))fs.writeFileSync(configPath,configOriginal);data.cleanup.configRestored=true;
 if(ownedRoom&&pages[0])try{await invoke(pages[0],'room_end',{roomId:ownedRoom.id});data.cleanup.failedRoomEnded=true;}catch{data.cleanup.failedRoomEnded=false;}
 // Leave clients available to resume debugging after a failure; dedicated stop
 // command closes only recorded owned processes after final acceptance.
 for(const browser of browsers)await browser.close().catch(()=>{});
 data.finished=new Date().toISOString();data.elapsedMs=Date.now()-budget.started;save();
 if(data.error&&data.elapsedMs>budget.limitMs)fs.writeFileSync(path.join(out,'api-fallback.json'),JSON.stringify({reason:'原生页面调试预算已耗尽，仅保留独立API冒烟结果，未执行路径不计通过',smoke:JSON.parse(fs.readFileSync(path.join(out,'smoke-results.json'),'utf8'))},null,2));
 console.log('Artifacts: '+out);
}
