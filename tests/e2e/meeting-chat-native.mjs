import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {createRequire} from 'node:module';
import {fileURLToPath} from 'node:url';
import {prepareNativeInput} from './meeting-ready-input.mjs';
const root=fileURLToPath(new URL('../../',import.meta.url)),out=path.join(path.resolve(root,process.env.MEETING_CHAT_OUTPUT||'.artifacts/会议聊天生命周期与界面'),'native');
fs.mkdirSync(path.join(out,'screenshots'),{recursive:true});
const require=createRequire(path.join(root,'frontend/package.json')),{chromium}=require('playwright');
const file=path.join(out,'chat-results.json');if(fs.existsSync(file))fs.copyFileSync(file,path.join(out,`chat-attempt-${Date.now()}.json`));
const budgetPath=path.join(path.dirname(out),'browser/budget.json'),budget=JSON.parse(fs.readFileSync(budgetPath));
const data={started:new Date().toISOString(),boundary:'真实 Windows Tauri/Rust IPC、独立 FastAPI/PostgreSQL、真实 IM/对象存储；设备输入为合成源；没有替换 SDK、IPC 或 API',steps:[],cleanup:{}};
const accounts=JSON.parse(fs.readFileSync(path.join(out,'accounts.private.json'))),pages=[],browsers=[];
let page,room,phase='assertions',number=0;
const save=()=>fs.writeFileSync(file,JSON.stringify(data,null,2));
const invoke=(p,command,args={})=>p.evaluate(({command,args})=>window.__TAURI_INTERNALS__.invoke(command,args),{command,args});
const until=async(fn,timeout=25000)=>{const end=Date.now()+timeout;while(Date.now()<end){const value=await fn();if(value)return value;await new Promise(r=>setTimeout(r,100));}throw Error('目标原生状态超时');};
const toolbar=p=>p.getByTestId('room-toolbar-region'),input=p=>p.getByPlaceholder('发送消息，全体成员可见');
const quick=p=>p.getByRole('button',{name:'快速会议 立即发起一场会议',exact:true});
const article=(p,text)=>p.getByTestId('im-meeting-message').filter({hasText:text}).last();
async function chat(p){await until(async()=>{if(await input(p).isVisible())return input(p).isEnabled();const b=toolbar(p).getByRole('button',{name:'聊天',exact:true});if(await b.isVisible())await b.click();return false;},45000);}
async function close(p){await p.getByRole('dialog').getByRole('button',{name:'关闭',exact:true}).click();await p.getByRole('dialog').waitFor({state:'hidden'});}
async function preview(p,name){await article(p,name).getByRole('button',{name:'预览 / 播放',exact:true}).click();await p.getByRole('dialog').waitFor();}
async function step(operation,expected,action,label){
 if(Date.now()-budget.started>budget.limitMs)throw Error('30分钟 E2E 调试预算耗尽');
 const row={phase,operation,expected,actual:'',pass:false,viewport:page?await page.evaluate(()=>`${innerWidth}x${innerHeight}`):'native',screenshot:null};data.steps.push(row);
 try{row.actual=await action()||'全部断言符合预期';row.pass=true;if(phase==='screenshots'&&label){await page.locator('button[data-close-button]').evaluateAll(bs=>bs.forEach(b=>b.click()));row.screenshot=`screenshots/${String(++number).padStart(2,'0')}-${row.viewport}-${label}.png`;await page.screenshot({path:path.join(out,row.screenshot),animations:'disabled'});}}
 catch(e){row.actual=String(e.message);if(page){row.screenshot=`screenshots/failure-${Date.now()}.png`;await page.screenshot({path:path.join(out,row.screenshot)}).catch(()=>{});}throw e;}
 finally{save();console.log(JSON.stringify(row));}
}
async function captureBoth(label){if(phase!=='screenshots')return;for(const size of [{width:1440,height:900},{width:390,height:844}]){await page.setViewportSize(size);await step(label,'真实原生目标状态可读，待逐张视觉检查',async()=>{assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1));},label);}}
async function end(){const host=pages[0];const panel=host.getByTestId('room-side-panel');if(await panel.isVisible())await panel.getByRole('button',{name:'关闭',exact:true}).click();await toolbar(host).getByRole('button',{name:'离开并结束',exact:true}).click();await host.getByRole('dialog').getByRole('button',{name:'结束会议',exact:true}).click();await until(()=>new URL(host.url()).pathname!=='/room',60000);room=null;for(const p of pages)if(new URL(p.url()).pathname!=='/')await p.goto('http://localhost:3162/',{waitUntil:'domcontentloaded'});}
async function flow(){
 const [host,member]=pages;page=host;const marker=`会议隔离-${Date.now()}`;
 await step('真实页面创建会议并由另一端入会','两个原生客户端加入同一房间，聊天就绪',async()=>{await quick(host).click();await until(()=>new URL(host.url()).searchParams.get('code'),60000);room=await invoke(host,'room_get_code',{code:new URL(host.url()).searchParams.get('code')});await chat(host);await member.getByRole('button',{name:'加入会议 输入会议号入会',exact:true}).click();const d=member.getByRole('dialog');for(let i=0;i<6;i++)await d.locator('input[inputmode="numeric"]').nth(i).fill(room.code[i]);for(const sw of await d.getByRole('switch').all())if(await sw.getAttribute('aria-checked')==='true')await sw.click();await d.getByRole('button',{name:'加入会议',exact:true}).click();await chat(member);return{roomId:room.id,participants:(await invoke(host,'room_get',{roomId:room.id})).participants.length};});
 await step('真实 IM 双向聊天','两端发送，各自实时收到对方消息；无 tip 卡片',async()=>{for(const [sender,receiver,text] of [[host,member,marker],[member,host,'成员回复：本次聊天仅属于本场会议']]){await input(sender).fill(text);await input(sender).press('Enter');await article(receiver,text).waitFor({timeout:30000});}assert.equal(await host.getByText('[tip]',{exact:true}).count(),0);});await captureBoth('原生聊天成功');
 await step('真实文本文件上传和预览','接收端通过鉴权原生下载展示文本，HTML不执行',async()=>{await host.locator('input[type=file]').setInputFiles({name:'会议笔记.txt',mimeType:'text/plain',buffer:Buffer.from('真实会议附件预览\n<script>window.__unsafePreview=true</script>\n确认文本内容完整。')});await article(member,'会议笔记.txt').waitFor({timeout:30000});await preview(member,'会议笔记.txt');await member.getByRole('dialog').locator('pre').filter({hasText:'确认文本内容完整。'}).waitFor();assert.equal(await member.evaluate(()=>window.__unsafePreview),undefined);});page=member;await captureBoth('原生文本预览');await close(member);
 const video=process.env.MEETING_CHAT_VIDEO||path.join(root,'.artifacts/rtc-release-media-preview/acceptance-video.mp4');
 await step('真实视频上传并在接收端播放','原生协议解码 640×360，播放时间推进',async()=>{await host.locator('input[type=file]').setInputFiles(video);await article(member,'acceptance-video.mp4').waitFor({timeout:30000});await preview(member,'acceptance-video.mp4');const v=member.getByRole('dialog').locator('video');await until(()=>v.evaluate(e=>e.readyState>=2&&e.videoWidth===640),30000);await v.evaluate(async e=>{e.muted=true;await e.play();});await until(()=>v.evaluate(e=>e.currentTime>0.3));const actual=await v.evaluate(e=>({src:e.currentSrc,duration:e.duration,width:e.videoWidth,currentTime:e.currentTime}));assert.ok(actual.src.includes('drim-file.localhost'));return actual;});await captureBoth('原生视频播放');await close(member);
 await step('非主持人结束失败','原生 IPC 得到 403，会议保持可用',async()=>{const response=await member.evaluate(async roomId=>{try{await window.__TAURI_INTERNALS__.invoke('room_end',{roomId});return{status:200};}catch(error){try{return typeof error==='string'?JSON.parse(error):error;}catch{return{error:String(error)};}}},room.id);assert.equal(response.status,403);assert.equal((await invoke(host,'room_get',{roomId:room.id})).participants.length,2);return{status:response.status};});
 const previous=room;
 await step('结束会议并拒绝旧房间聊天授权','结束后所有端离开聊天，旧 chat-session 返回拒绝',async()=>{await end();const denied=await host.evaluate(async roomId=>{try{await window.__TAURI_INTERNALS__.invoke('room_chat_session',{roomId});return false;}catch{return true;}},previous.id);assert.equal(denied,true);for(const p of pages)assert.equal(await p.getByTestId('im-meeting-message').count(),0);});
 page=host;
 await step('下一场会议聊天为空','新 room/group 与旧场不同，无上场文本和附件',async()=>{await quick(host).click();await until(()=>new URL(host.url()).searchParams.get('code'),60000);room=await invoke(host,'room_get_code',{code:new URL(host.url()).searchParams.get('code')});assert.notEqual(room.id,previous.id);await chat(host);const session=await invoke(host,'room_chat_session',{roomId:room.id});assert.ok(session.groupId);assert.equal(await host.getByTestId('im-meeting-message').count(),0);return{newRoomId:room.id,oldRoomId:previous.id,empty:true};});await captureBoth('原生下一场空态');await end();
}
try{
 assert.equal(JSON.parse(fs.readFileSync(path.join(out,'smoke-results.json'))).results.every(r=>r.pass),true,'先通过真实 API 故障夹具冒烟');
 for(let i=0;i<2;i++){const b=await chromium.connectOverCDP(`http://127.0.0.1:${9261+i}`);browsers.push(b);const ctx=b.contexts()[0];await prepareNativeInput(ctx);const p=ctx.pages().find(p=>p.url().startsWith('http://localhost:3162')&&!p.url().includes('/im/'));assert.ok(p);p.setDefaultTimeout(20000);pages.push(p);}
 page=pages[0];await step('复用独立原生实例并登录','保留日常服务，使用独立账号及真实 Rust 认证',async()=>{for(let i=0;i<pages.length;i++){const p=pages[i];await invoke(p,'complete_onboarding',{model:''});const user=await invoke(p,'auth_get_user');assert.ok(!user||user.id===accounts[i].id,'不替换未知登录态');await p.evaluate(()=>localStorage.setItem('dr.locale','zh-CN'));await p.goto('http://localhost:3162/',{waitUntil:'domcontentloaded'});if(!user){await p.locator('#phone-auth-phone').fill(accounts[i].phone);await p.locator('#phone-auth-password').fill(accounts[i].password);await p.locator('form').getByRole('button',{name:'登录',exact:true}).click();}await quick(p).waitFor({timeout:60000});assert.equal((await invoke(p,'auth_get_user')).id,accounts[i].id);}return{clients:2};});
 await flow();phase='screenshots';await flow();
}catch(e){data.error=String(e.stack);process.exitCode=1;}
finally{if(room&&pages[0]){try{await invoke(pages[0],'room_end',{roomId:room.id});data.cleanup.activeRoomEnded=true;}catch(e){data.cleanup.roomError=String(e);}}for(const b of browsers)await b.close();save();}
