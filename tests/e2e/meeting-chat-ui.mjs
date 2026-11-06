import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {createRequire} from 'node:module';
import {fileURLToPath} from 'node:url';
import {spawn} from 'node:child_process';
import {startLayoutBackend,installLayoutBridge} from './fixtures/desktop-layout-backend.mjs';
import {installMeetingFixture} from './fixtures/meeting-im-sdk.mjs';
import {inlineMediaFlow} from './fixtures/chat-inline-media-flow.mjs';
const root=fileURLToPath(new URL('../../',import.meta.url)),front=path.join(root,'frontend');
const out=path.join(path.resolve(root,process.env.MEETING_CHAT_OUTPUT||'.artifacts/会议聊天生命周期与界面'),'browser');fs.mkdirSync(path.join(out,'screenshots'),{recursive:true});
const require=createRequire(path.join(front,'package.json')),{chromium}=require('playwright');
const videoFile=process.env.MEETING_CHAT_VIDEO||path.join(root,'.artifacts/rtc-release-media-preview/acceptance-video.mp4');
const saveFile=(name,data)=>fs.writeFileSync(path.join(out,name),JSON.stringify(data,null,2));
if(process.argv.includes('--smoke')){
 const rows=[],state={},client={conversations:{},messages:{}},f=installMeetingFixture(client,()=>state);
 for(const [operation,action] of [
  ['发送失败',async()=>{f.control({sendError:true});await assert.rejects(client.messages.send({to_group:'g'},{type:'text',body:{text:'x'}}));}],
  ['附件权限失败',async()=>{f.control({previewDenied:true});await assert.rejects(client.desktop.download({}),/权限不足/);}],
  ['预览加载与取消',async()=>{f.control({previewDenied:false,pausePreview:true});const abort=new AbortController(),task=client.desktop.download({},{signal:abort.signal});abort.abort();await assert.rejects(task,/取消/);f.control({pausePreview:false});}],
  ['不同会议隔离',async()=>{await client.conversations.refresh('one');f.control({messages:[{type:'text',body:{text:'old'}}]});await client.conversations.refresh('two');assert.equal(client.messages.open().getSnapshot().items.length,0);}],
 ]){await action();const row={operation,expected:'独立冒烟稳定触发指定状态',actual:'已验证',pass:true,screenshot:null};rows.push(row);console.log(JSON.stringify(row));}
 const backend=await startLayoutBackend();try{await fetch(backend.base+'/control',{method:'POST',body:JSON.stringify({patch:{chatError:true}})});const r=await fetch(backend.base+'/invoke',{method:'POST',body:JSON.stringify({command:'room_chat_session'})});assert.equal(r.status,503);rows.push({operation:'连接失败入口',expected:'503',actual:r.status,pass:true});}finally{await backend.close();}
 saveFile('smoke.json',rows);process.exit(0);
}
assert.ok(fs.existsSync(path.join(out,'smoke.json')),'先单独运行 --smoke');
const file=path.join(out,'results.json');if(fs.existsSync(file))fs.copyFileSync(file,path.join(out,`attempt-${Date.now()}.json`));
const budgetPath=path.join(out,'budget.json'),budget=fs.existsSync(budgetPath)?JSON.parse(fs.readFileSync(budgetPath)): {started:Date.now(),limitMs:1800000};saveFile('budget.json',budget);
const data={started:new Date().toISOString(),boundary:'完整真实页面；显式 IPC/IM/RTC 夹具，不等同于原生验收',probe:[],steps:[],cleanup:{},startup:'node tests/e2e/meeting-chat-ui.mjs --smoke; node tests/e2e/meeting-chat-ui.mjs; 独立 Next :3144'};
const save=()=>saveFile('results.json',data);
let next,browser,context,page,session,phase='assertions',number=0;
const backend=await startLayoutBackend(),ui='http://localhost:3144';
const config=path.join(front,'tsconfig.json'),before=fs.readFileSync(config);
const control=patch=>fetch(backend.base+'/control',{method:'POST',body:JSON.stringify({session,patch})});
const sdk=patch=>page.evaluate(p=>window.__meetingFixture.control(p),patch);
const panel=()=>page.getByTestId('room-side-panel'),input=()=>page.getByPlaceholder('发送消息，全体成员可见'),dialog=()=>page.getByRole('dialog');
async function close(){await dialog().getByRole('button',{name:'关闭',exact:true}).click();await dialog().waitFor({state:'hidden'});}
const article=name=>page.getByTestId('im-meeting-message').filter({hasText:name}).last();
async function preview(name){await article(name).getByRole('button',{name:'预览 / 播放',exact:true}).click();await dialog().waitFor();}
async function step(operation,expected,action,shot){
 if(Date.now()-budget.started>budget.limitMs)throw Error('30分钟 E2E 调试预算耗尽，须降级 API 验证');
 const size=page.viewportSize(),row={phase,viewport:`${size.width}x${size.height}`,operation,expected,actual:'',pass:false,screenshot:null};data.steps.push(row);
 try{row.actual=await action()||'全部断言符合预期';
  assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth+2),false,'页面横向溢出');
  row.pass=true;
  if(phase==='screenshots'&&shot){await page.locator('button[data-close-button]').evaluateAll(bs=>bs.forEach(b=>b.click()));await page.waitForTimeout(200);row.screenshot=`screenshots/${String(++number).padStart(2,'0')}-${row.viewport}-${shot}.png`;await page.screenshot({path:path.join(out,row.screenshot),animations:'disabled'});}
 }catch(e){row.actual=String(e.message);row.screenshot=`screenshots/failure-${Date.now()}.png`;await page.screenshot({path:path.join(out,row.screenshot)}).catch(()=>{});throw e;}
 finally{save();console.log(JSON.stringify(row));}
}
async function flow(viewport){
 session=`${phase}-${viewport.width}`;await control({loggedIn:false,chatLifecycle:true});
 context=await browser.newContext({viewport,locale:'zh-CN'});await context.addInitScript(installLayoutBridge,{base:backend.base,session});page=await context.newPage();page.setDefaultTimeout(12000);
 await context.tracing.start({screenshots:true,snapshots:true});
 await step('登录并发起会议','登录→快速会议→聊天空态可输入',async()=>{await page.goto(ui,{waitUntil:'domcontentloaded'});await page.locator('#phone-auth-phone').fill('13800138000');await page.locator('#phone-auth-password').fill('LayoutTest123!');await page.locator('button[type=submit]').click();await page.getByRole('button',{name:/快速会议.*立即/}).click();await page.getByRole('button',{name:'聊天',exact:true}).click();await input().waitFor();assert.equal(await input().isEnabled(),true);assert.equal(await page.getByTestId('im-meeting-message').count(),0);},'聊天空态');
 await step('系统事件与发消息','无 System [tip] 卡片，自己消息右侧显示，动作收起',async()=>{await sdk({messages:[{type:'tip',sender_type:'system',body:{kind:'group_member_added'}}]});assert.equal(await page.getByTestId('im-meeting-message').count(),0);await input().fill('本次会议的第一条消息');await input().press('Enter');await article('本次会议的第一条消息').waitFor();assert.equal(await panel().getByRole('button',{name:'回复',exact:true}).count(),0);},'消息发送成功');
 await step('消息操作菜单打开','只显示复制、删除、撤回',async()=>{await article('本次会议的第一条消息').getByRole('button',{name:'消息操作',exact:true}).click();await page.getByRole('menuitem',{name:'复制',exact:true}).waitFor();assert.deepEqual(await page.getByRole('menuitem').allTextContents(),['复制','删除','撤回']);},'消息操作菜单');
 await step('删除确认并取消','取消后保留消息，不产生空白气泡',async()=>{await page.getByRole('menuitem',{name:'删除',exact:true}).click();await page.getByRole('dialog').filter({hasText:'是否删除该消息？'}).waitFor();await page.getByRole('button',{name:'取消',exact:true}).click();await page.getByRole('dialog').waitFor({state:'hidden'});assert.equal(await article('本次会议的第一条消息').count(),1);},'取消删除');
 await step('成员气泡、连续消息和长文本滚动','左右气泡，无空卡片和横向溢出',async()=>{await sdk({messages:[{sender:'member-1',type:'text',body:{text:'参会成员发来的消息'}},{sender:'member-1',type:'text',body:{text:'连续消息使用紧凑分组'}},{sender:'layout-self',type:'text',body:{text:'LongTextWithoutSpaces0123456789'.repeat(22)}}]});await article('连续消息使用紧凑分组').waitFor();await article('LongTextWithoutSpaces').scrollIntoViewIfNeeded();},'长文本滚动');
 await step('上传并预览文本文件','鉴权预览文本，HTML按普通文字显示',async()=>{await page.locator('input[type=file]').setInputFiles({name:'会议笔记.txt',mimeType:'text/plain',buffer:Buffer.from('会议笔记')});await preview('会议笔记.txt');await dialog().locator('pre').filter({hasText:'<script>'}).waitFor();assert.equal(await dialog().locator('script').count(),0);},'文本附件预览');await close();
 await inlineMediaFlow({page,step,sdk,panel,input,dialog,article,videoFile});
 await step('会议文件抽屉打开并滚动','文件长名换行、分页，关闭回到聊天',async()=>{await panel().getByRole('button',{name:'会议文件',exact:true}).click();await dialog().locator('li').filter({hasText:/^0-会议文件-/}).waitFor();await dialog().getByRole('button',{name:'加载更多文件',exact:true}).scrollIntoViewIfNeeded();await dialog().getByRole('button',{name:'加载更多文件',exact:true}).click();await dialog().locator('li').filter({hasText:/^15-会议文件-/}).scrollIntoViewIfNeeded();},'文件抽屉滚动');await close();
 await control({chatError:true});await page.evaluate(()=>sessionStorage.setItem('liveMeeting.joinIntent',JSON.stringify({code:'654321',name:'聊天测试',micOn:false,camOn:false})));await page.reload({waitUntil:'domcontentloaded'});
 await step('聊天连接失败','入会连接错误和重试可见，聊天输入尚未挂载',async()=>{await page.getByTestId('meeting-entry-error').waitFor();await page.getByRole('button',{name:'重试',exact:true}).waitFor();assert.equal(await input().count(),0);},'连接失败');
 await control({chatError:false});
 await step('连接重试成功','重新完成入会后聊天输入恢复，可继续发送',async()=>{await page.getByRole('button',{name:'重试',exact:true}).click();await page.getByRole('button',{name:'聊天',exact:true}).click();await input().waitFor();await page.waitForFunction(()=>!document.querySelector('input[placeholder="发送消息，全体成员可见"]')?.disabled);await input().fill('结束前的消息，不应出现在下一场');await input().press('Enter');await article('结束前的消息，不应出现在下一场').waitFor();},'连接恢复');
 await step('结束会议并进入下一场','结束确认→首页→新会议无上次消息',async()=>{await panel().getByRole('button',{name:'关闭',exact:true}).click();await page.getByRole('button',{name:'离开并结束',exact:true}).click();await dialog().getByRole('button',{name:'结束会议',exact:true}).click();await page.waitForURL(new URL('/',ui).href,{timeout:60000});await page.getByRole('button',{name:/快速会议.*立即/}).click();await page.getByRole('button',{name:'聊天',exact:true}).click();await input().waitFor();await page.waitForFunction(()=>!document.querySelector('input[placeholder="发送消息，全体成员可见"]')?.disabled);assert.equal(await page.getByTestId('im-meeting-message').count(),0);},'下一场会议空态');
 await context.tracing.stop({path:path.join(out,`trace-${phase}-${viewport.width}.zip`)});await context.close();context=null;
}
try{
 for(const port of [3118,39110,3144]){const exists=await fetch(`http://127.0.0.1:${port}`,{signal:AbortSignal.timeout(1000)}).then(r=>({port,status:r.status,existing:true})).catch(()=>({port,existing:false}));data.probe.push(exists);}
 assert.equal(data.probe.at(-1).existing,false,'保留已有服务');
 next=spawn(process.execPath,[path.join(front,'node_modules/next/dist/bin/next'),'dev','-p','3144'],{cwd:front,windowsHide:true,env:{...process.env,OPENMEETING_NEXT_DIST_DIR:'.next-chat-ui',OPENMEETING_E2E_DESKTOP_LAYOUT:'1',NEXT_PUBLIC_LIVE_MEETING_DATA_SOURCE:'real'},stdio:['ignore','pipe','pipe']});
 for(const stream of [next.stdout,next.stderr])stream.on('data',d=>fs.appendFileSync(path.join(out,'next.log'),d));
 const deadline=Date.now()+90000;while(!await fetch(ui).then(r=>r.ok).catch(()=>false)){if(Date.now()>deadline)throw Error('Next readiness timeout');await new Promise(r=>setTimeout(r,400));}
 await fetch(ui+'/meeting-details');browser=await chromium.launch({headless:true});
 for(const mode of ['assertions','screenshots']){phase=mode;for(const viewport of [{width:1440,height:900},{width:390,height:844}])await flow(viewport);}
}catch(e){data.error=String(e.stack);process.exitCode=1;if(page&&!page.isClosed()){await page.screenshot({path:path.join(out,'failure-page.png')}).catch(()=>{});data.failurePage=await page.locator('body').innerText().catch(()=>'unavailable');}if(context)await context.tracing.stop({path:path.join(out,'failure-trace.zip')}).catch(()=>{});}
finally{await browser?.close();if(next){await new Promise(resolve=>{const p=spawn('taskkill.exe',['/PID',String(next.pid),'/T','/F'],{windowsHide:true,stdio:'ignore'});p.on('exit',code=>{data.cleanup.nextClosed=code===0;resolve();});});}await backend.close();data.cleanup.fixtureClosed=true;fs.writeFileSync(config,before);save();}
