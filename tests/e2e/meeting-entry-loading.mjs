import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {spawn,spawnSync} from 'node:child_process';
import {createRequire} from 'node:module';
import {fileURLToPath} from 'node:url';
import net from 'node:net';
import {startLayoutBackend,installLayoutBridge} from './fixtures/desktop-layout-backend.mjs';

// Production Next pages and entry state machine; explicit HTTP/IPC/IM/RTC fixtures.
// Does not validate native permissions, physical devices or production RTC.
const root=fileURLToPath(new URL('../../',import.meta.url)),front=path.join(root,'frontend');
const out=path.resolve(root,process.env.MEETING_ENTRY_OUTPUT||'.artifacts/meeting-entry-loading');
fs.mkdirSync(path.join(out,'screenshots'),{recursive:true});
const read=(name,fallback)=>fs.existsSync(path.join(out,name))?JSON.parse(fs.readFileSync(path.join(out,name),'utf8')):fallback;
const write=(name,value)=>fs.writeFileSync(path.join(out,name),JSON.stringify(value,null,2));
async function listening(port){return new Promise(resolve=>{const socket=net.connect({host:'127.0.0.1',port});const finish=value=>{socket.destroy();resolve(value);};socket.setTimeout(1500,()=>finish(false));socket.once('connect',()=>finish(true));socket.once('error',()=>finish(false));});}
function report(){
 const r=read('results.json',{rows:[]}),smoke=read('smoke.json',[]),checks=read('checks.json',[]),contracts=read('contract-results.json',[]),contractSmoke=read('contract-smoke.json',[]),reviews=read('visual-reviews.json',{});
 const assertions=r.rows.filter(s=>s.phase==='assertions'),shots=r.rows.filter(s=>s.screenshot),all=[...smoke,...contractSmoke,...checks,...contracts,...assertions];
 const historyDir=path.join(out,'history'),history=fs.existsSync(historyDir)?fs.readdirSync(historyDir).flatMap(name=>{const file=path.join(historyDir,name,'results.json');if(!fs.existsSync(file))return[];const past=JSON.parse(fs.readFileSync(file,'utf8'));return past.rows.filter(s=>!s.pass).map(s=>({run:name,...s}));}):[];
 const lines=['# 入会加载合并验证报告','','分级：入会状态机及跨路由 UI 改动，执行完整受影响流程：快速创建、加入、聊天、跨页返回，以及聊天失败恢复和入会失败。真实 Next 开发页面使用项目已有显式 HTTP/IPC/IM/RTC 夹具；组件契约进一步覆盖设备初始化、超时、晚到请求、等候室、密码和模块禁用。未执行真实原生设备或平台 RTC 验收。','',
 `断言/检查：${all.filter(s=>s.pass).length} 通过、${all.filter(s=>!s.pass).length} 失败。截图阶段：${r.rows.filter(s=>s.phase==='screenshots'&&s.pass).length} 通过、${r.rows.filter(s=>s.phase==='screenshots'&&!s.pass).length} 失败；${shots.length} 张截图中 ${shots.filter(s=>reviews[s.screenshot]?.pass).length} 张已实际查看并通过。`,
 ...(r.error?['','执行错误：'+r.error]:[]),'',
 '启动：先读取项目启动/测试规则，探测并保留 3118、39110 和既有登录态；单独运行 --smoke 验证确定性 503/404 及恢复入口；再启动隔离 Next :3198，OPENMEETING_NEXT_DIST_DIR=.next-entry-merge、OPENMEETING_E2E_DESKTOP_LAYOUT=1、NEXT_PUBLIC_LIVE_MEETING_DATA_SOURCE=real。无 in-app browser，使用 Playwright 无头 Chromium。页面累计调试预算 30 分钟，不随重跑重置。','',
 '页面断言全部通过后统一重跑截图阶段，视口 1280×800 / 390×844；覆盖首页、弹窗打开/关闭、连续加载、成功入会、聊天抽屉滚动与关闭、跨页返回、连接错误与重试、加入失败。此功能没有新增表格；加载阶段为空房间的交互组件尚未挂载。权限拒绝仅在组件契约注入，不代表系统权限验收。','',
 '| 阶段 | 操作 | 预期 | 实际 | 结果 | 截图 |','|---|---|---|---|---|---|',
 ...[...smoke,...contractSmoke,...checks,...contracts,...r.rows].map(s=>`| ${s.phase||'检查'} | ${s.operation} | ${s.expected} | ${String(s.actual).replaceAll('|','/').replaceAll('\n',' ')} | ${s.pass?'通过':'失败'} | ${s.screenshot?'[截图]('+s.screenshot+')':'—'} |`),'',
 '| 截图 | 视口 | 实际视觉检查 |','|---|---|---|',
 ...shots.map(s=>`| [${path.basename(s.screenshot)}](${s.screenshot}) | ${s.viewport.width}×${s.viewport.height} | ${reviews[s.screenshot]?`${reviews[s.screenshot].pass?'通过':'未通过'}：${reviews[s.screenshot].notes}`:'未实际查看'} |`),'',
 '探测：'+JSON.stringify(r.probe)+'。清理：'+JSON.stringify(r.cleanup)+'。','',
 '原始证据：[页面逐步结果](results.json)、[失败夹具冒烟](smoke.json)、[组件契约](contract-results.json)、[代码检查](checks.json)、[视觉检查](visual-reviews.json)、[开发日志](next.log)。','',
 ...(fs.existsSync(path.join(out,'history'))?[`历史调试失败 ${history.length} 次，保留在 [history](history/)，未计作通过。`,'',...history.map(s=>`- [${s.run}](history/${s.run}/results.json)：${s.operation}；${String(s.actual).split('\n')[0]}`),'']:[]),
 '剩余风险：本轮未重跑真实 IM/RTC、系统设备权限及 Tauri 原生三端；当前验证确认前端加载和恢复逻辑，不推断摄像头画面或音视频传输质量。',''];
 fs.writeFileSync(path.join(out,'测试报告.md'),lines.join('\n'));
 console.log(JSON.stringify({passed:all.filter(s=>s.pass).length,failed:all.filter(s=>!s.pass).length,screenshots:shots.length,reviewed:shots.filter(s=>reviews[s.screenshot]?.pass).length,out}));
}
if(process.argv.includes('--report')){report();process.exit(0);}
const backend=await startLayoutBackend();
async function control(session,patch){const q=await fetch(backend.base+'/control',{method:'POST',body:JSON.stringify({session,patch})});assert.ok(q.ok);}
async function rpc(session,command,args={}){const q=await fetch(backend.base+'/invoke',{method:'POST',body:JSON.stringify({session,command,args})});return{status:q.status,body:await q.json()};}
if(process.argv.includes('--smoke')){
 try{const rows=[];for(const [patch,command,expected]of [[{chatError:true},'room_chat_session',503],[{chatError:false},'room_chat_session',200],[{joinError:true},'room_join',404],[{joinError:false},'room_join',200]]){await control('smoke',patch);const q=await rpc('smoke',command);assert.equal(q.status,expected);const row={operation:`独立故障夹具 ${command} ${JSON.stringify(patch)}`,expected,actual:q.status,pass:true,screenshot:null};rows.push(row);console.log(JSON.stringify(row));}write('smoke.json',rows);}finally{await backend.close();}process.exit(0);
}
assert.ok(read('smoke.json',[]).length===4&&read('smoke.json').every(s=>s.pass),'Run --smoke before browser E2E');
const budget=read('budget.json',{started:Date.now(),limitMs:1800000});write('budget.json',budget);
const r={rows:[],probe:[],cleanup:{}},save=()=>write('results.json',r);
const require=createRequire(path.join(front,'package.json')),{chromium}=require('playwright');
const ui='http://localhost:3198',configFile=path.join(front,'tsconfig.json'),configBefore=fs.readFileSync(configFile);
let browser,next,page,phase='assertions',sequence=0;
async function step(operation,expected,fn,label){
 if(Date.now()-budget.started>budget.limitMs)throw Error('30 minute E2E budget exhausted');
 const row={phase,operation,expected,actual:null,pass:false,viewport:page.viewportSize(),screenshot:null};
 try{row.actual=await fn();row.pass=true;if(phase==='screenshots'&&label){assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth+1),false,'No horizontal overflow');row.screenshot=`screenshots/${String(++sequence).padStart(2,'0')}-${row.viewport.width}x${row.viewport.height}-${label}.png`;await page.screenshot({path:path.join(out,row.screenshot),animations:'disabled'});}}
 catch(e){row.pass=false;row.actual=String(e.stack||e);row.screenshot=`screenshots/failure-${Date.now()}.png`;await page.screenshot({path:path.join(out,row.screenshot)}).catch(()=>{});throw e;}
 finally{r.rows.push(row);save();console.log(JSON.stringify(row));}
}
async function boot(size,patch={}){
 const session=`${phase}-${size.width}-${Math.random().toString(36).slice(2)}`;
 await control(session,{loggedIn:true,chatLifecycle:true,...patch});
 const context=await browser.newContext({viewport:size,locale:'zh-CN'});
 await context.addInitScript(installLayoutBridge,{base:backend.base,session});
 await context.addInitScript(()=>{
  const invoke=window.__TAURI_INTERNALS__.invoke;window.__entryCalls=[];
  window.__TAURI_INTERNALS__.invoke=async(command,args)=>{
   window.__entryCalls.push(command);
   if(command==='room_create'||command==='room_join')await new Promise(resolve=>{(window.__entryResume??={})[command]=resolve;});
   return invoke(command,args);
  };
 });
 page=await context.newPage();page.setDefaultTimeout(12000);await page.goto(ui,{waitUntil:'domcontentloaded'});
 await page.getByRole('button',{name:/快速会议.*立即/}).waitFor();
 const close=page.locator('[data-sonner-toast] [data-close-button]');if(await close.count())await close.first().click();
 await page.locator('[data-sonner-toast]').waitFor({state:'hidden'});
 return{context,session};
}
async function resume(command){await page.waitForFunction(command=>typeof window.__entryResume?.[command]==='function',command);await page.evaluate(command=>window.__entryResume[command](),command);}
async function ready(){await page.getByTestId('meeting-entry-loading').waitFor({state:'detached'});await page.getByTestId('room-toolbar-region').waitFor();}
async function start(){await page.getByRole('button',{name:/快速会议.*立即/}).click();await resume('room_create');await page.waitForURL('**/room?code=654321');await resume('room_join');}
async function flow(size){
 let app=await boot(size);try{
  await step('首页正常','首页可操作，加载遮罩不存在',async()=>{assert.equal(await page.getByTestId('meeting-entry-loading').count(),0);return'首页快捷入口可见';},'首页');
  await step('加入弹窗打开','弹窗可输入，无溢出',async()=>{await page.getByRole('button',{name:/加入会议.*输入/}).click();const dialog=page.getByRole('dialog');await dialog.waitFor();for(let i=0;i<6;i++)await dialog.locator('input[inputmode=numeric]').nth(i).fill('654321'[i]);return'6 位会议号已输入，设备开关可见';},'加入弹窗');
  await step('加入弹窗关闭','Escape 关闭后首页继续可用',async()=>{await page.keyboard.press('Escape');await page.getByRole('dialog').waitFor({state:'hidden'});return'弹窗关闭';},'弹窗关闭');
  await step('快速创建加载','创建尚未完成时只有一个全屏加载层',async()=>{await page.getByRole('button',{name:/快速会议.*立即/}).click();await page.getByTestId('meeting-entry-loading').waitFor();assert.equal(await page.getByTestId('room-toolbar-region').count(),0);await page.evaluate(()=>window.__entryNode=document.querySelector('[data-testid=meeting-entry-loading]'));return'创建请求等待；交互房间未挂载';},'创建加载');
  await step('路由切换后继续加载','入会等待时复用同一个加载节点',async()=>{await resume('room_create');await page.waitForURL('**/room?code=654321');await page.waitForFunction(()=>!!window.__entryResume?.room_join);assert.ok(await page.evaluate(()=>window.__entryNode===document.querySelector('[data-testid=meeting-entry-loading]')));assert.equal(await page.getByTestId('room-toolbar-region').count(),0);return'同一 DOM 加载层跨路由保留';},'入会加载');
  await step('成功入会','聊天和媒体准备后才展示房间',async()=>{await resume('room_join');await ready();assert.equal(await page.evaluate(()=>window.__entryCalls.filter(c=>c==='room_join').length),1);return'房间已显示，加入只执行一次';},'成功入会');
  await step('聊天抽屉打开滚动','发送消息成功，长消息换行并发生实际滚动',async()=>{
   await page.evaluate(()=>window.__meetingFixture.control({seed:true}));
   await page.getByRole('button',{name:'聊天',exact:true}).click();const input=page.getByPlaceholder('发送消息，全体成员可见');await input.fill('入会加载合并后的聊天成功冒烟');await input.press('Enter');
   await page.getByTestId('im-meeting-message').filter({hasText:'入会加载合并后的聊天成功冒烟'}).waitFor();
   const list=page.getByTestId('room-side-panel').locator('.overflow-y-auto');
   await list.evaluate(el=>el.scrollTop=el.scrollHeight);const before=await list.evaluate(el=>({top:el.scrollTop,height:el.scrollHeight,client:el.clientHeight}));assert.ok(before.height>before.client&&before.top>0,'Fixture must overflow');
   await step('聊天长文本','无空格长消息在抽屉内换行，无横向溢出',async()=>{const dimensions=await list.evaluate(el=>({scroll:el.scrollWidth,client:el.clientWidth}));assert.ok(dimensions.scroll<=dimensions.client+1);await page.getByTestId('im-meeting-message').filter({hasText:'LongText0123456789'}).waitFor();return JSON.stringify(dimensions);},'聊天长文本');
   await page.getByTestId('im-meeting-message').first().scrollIntoViewIfNeeded();const after=await list.evaluate(el=>el.scrollTop);assert.ok(after<before.top,'Chat must actually scroll');
   return JSON.stringify({messages:await page.getByTestId('im-meeting-message').count(),before,after});
  },'聊天抽屉滚动');
  await step('聊天抽屉关闭','关闭入口可用，侧栏关闭',async()=>{await page.getByTestId('room-side-panel').getByRole('button',{name:'关闭',exact:true}).click();await page.getByPlaceholder('发送消息，全体成员可见').waitFor({state:'hidden'});return'侧栏关闭';},'聊天抽屉关闭');
  await step('跨页返回会议','返回首页再入会不重复初始加载',async()=>{await page.getByRole('button',{name:'返回首页',exact:true}).click();await page.getByTestId('return-meeting').click();await ready();assert.equal(await page.evaluate(()=>window.__entryCalls.filter(c=>c==='room_join').length),1);return'原会议保留，未重复加入';},'跨页返回');
 }finally{await app.context.close();}
 app=await boot(size,{chatError:true});try{
  await step('初始聊天连接失败','全屏错误提供重试和离开，半就绪房间不可操作',async()=>{await start();await page.getByTestId('meeting-entry-error').waitFor();assert.equal(await page.getByTestId('meeting-entry-loading').count(),0);assert.equal(await page.getByTestId('room-toolbar-region').count(),0);return'连接失败提示和两个恢复按钮可见';},'连接错误');
  await step('连接失败后重试','恢复后入会，无额外创建或加入',async()=>{await control(app.session,{chatError:false});await page.getByRole('button',{name:'重试',exact:true}).click();await ready();assert.equal(await page.evaluate(()=>window.__entryCalls.filter(c=>c==='room_join').length),1);return'聊天重试成功，原会议已就绪';},'重试成功');
 }finally{await app.context.close();}
 app=await boot(size,{joinError:true});try{
  await step('入会失败','加入失败释放加载，展示返回入口',async()=>{await start();await page.getByTestId('meeting-entry-loading').waitFor({state:'detached'});await page.getByText('加入会议失败', {exact:true}).waitFor();return'加入失败提示可见（现有 IPC 夹具抛出纯文本，走通用失败文案）';},'入会失败');
  await step('失败后返回','返回首页可重新发起会议',async()=>{await page.getByRole('button',{name:'返回',exact:true}).click();await page.getByRole('button',{name:/快速会议.*立即/}).waitFor();assert.equal(await page.getByTestId('meeting-entry-loading').count(),0);return'首页已恢复';},'失败返回');
 }finally{await app.context.close();}
}
try{
 for(const port of [3118,39110,3198]){const tcp=await listening(port);const p=await fetch(`http://127.0.0.1:${port}/`,{signal:AbortSignal.timeout(2000)}).then(async q=>{await q.body?.cancel();return{port,listening:tcp,status:q.status};}).catch(()=>({port,listening:tcp,httpResponded:false}));r.probe.push(p);}assert.equal(r.probe.at(-1).listening,false,'Preserve existing 3198 service');
 const fd=fs.openSync(path.join(out,'next.log'),'a');next=spawn(process.execPath,[path.join(front,'node_modules/next/dist/bin/next'),'dev','-p','3198'],{cwd:front,env:{...process.env,OPENMEETING_NEXT_DIST_DIR:'.next-entry-merge',OPENMEETING_E2E_DESKTOP_LAYOUT:'1',NEXT_PUBLIC_LIVE_MEETING_DATA_SOURCE:'real'},windowsHide:true,stdio:['ignore',fd,fd]});fs.closeSync(fd);
 const end=Date.now()+90000;while(!await fetch(ui).then(async q=>{await q.body?.cancel();return q.ok;}).catch(()=>false)){if(Date.now()>end)throw Error('Next startup timeout');await new Promise(resolve=>setTimeout(resolve,500));}
 browser=await chromium.launch({headless:true});for(const mode of ['assertions','screenshots']){phase=mode;for(const size of [{width:1280,height:800},{width:390,height:844}])await flow(size);}
}catch(e){r.error=String(e.stack||e);process.exitCode=1;console.error(e);}
finally{
 await browser?.close();r.cleanup.browserClosed=true;
 if(next){const q=spawnSync('taskkill.exe',['/PID',String(next.pid),'/T','/F'],{windowsHide:true});r.cleanup.nextStopped=q.status===0;}
 await backend.close();r.cleanup.fixtureClosed=true;r.cleanup.nextPortClosed=await fetch(ui,{signal:AbortSignal.timeout(1000)}).then(()=>false).catch(()=>true);
 if(!next||r.cleanup.nextPortClosed){fs.writeFileSync(configFile,configBefore);r.cleanup.tsconfigRestored=fs.readFileSync(configFile).equals(configBefore);}
 r.cleanup.daily3118Listening=await fetch('http://127.0.0.1:3118/',{signal:AbortSignal.timeout(2000)}).then(async q=>{await q.body?.cancel();return true;}).catch(()=>false);
 budget.usedMs=Date.now()-budget.started;write('budget.json',budget);save();report();
}
