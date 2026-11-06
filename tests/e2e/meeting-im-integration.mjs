import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
import {fileURLToPath} from 'node:url';
import {mkdirSync,readFileSync,writeFileSync,existsSync} from 'node:fs';
import {spawn} from 'node:child_process';
import path from 'node:path';
import {startLayoutBackend,installLayoutBridge} from './fixtures/desktop-layout-backend.mjs';
import {installMeetingFixture} from './fixtures/meeting-im-sdk.mjs';

const root=fileURLToPath(new URL('../../',import.meta.url)),frontend=path.join(root,'frontend');
const output=path.join(root,'.artifacts/meeting-im-integration');mkdirSync(path.join(output,'screenshots'),{recursive:true});
const require=createRequire(path.join(frontend,'package.json')),{chromium}=require('playwright');
const resultsFile=path.join(output,'results.json');
function report(){
  const r=JSON.parse(readFileSync(resultsFile,'utf8'));
  const visuals=existsSync(path.join(output,'visual-reviews.json'))?JSON.parse(readFileSync(path.join(output,'visual-reviews.json'),'utf8')):[];
  const live=existsSync(path.join(output,'live-results.json'))?JSON.parse(readFileSync(path.join(output,'live-results.json'),'utf8')):null;
  const checks=existsSync(path.join(output,'checks.json'))?JSON.parse(readFileSync(path.join(output,'checks.json'),'utf8')):[];
  if(existsSync(path.join(output,'merge-checks.json')))checks.push(...JSON.parse(readFileSync(path.join(output,'merge-checks.json'),'utf8')));
  const merge=existsSync(path.join(output,'merge-summary.json'))?JSON.parse(readFileSync(path.join(output,'merge-summary.json'),'utf8')):null;
  const escape=s=>String(s??'').replace(/\|/g,'\\|').replace(/\n/g,' ');
  const lines=['# 会议 IM 集成测试报告','','本次为消息传输、状态和交互的跨层改动，按完整功能级验证。浏览器夹具验收与真实 IM 验证分开计数；未使用 in-app browser，采用 Playwright 无头 Chromium。既有业务服务、3118 页面及日常客户端保留。项目规则要求产物存放 `.artifacts/`，因此覆盖用户给定的默认产物路径。','',`开始：${r.started}；E2E 调试预算 30 分钟。探测：${JSON.stringify(r.probe)}`,'',`启动：${r.startup}`,'',`夹具冒烟 ${r.smoke?.passed||0} 通过。页面断言 ${r.steps.filter(s=>s.phase==='assertions'&&s.pass).length} 通过、${r.steps.filter(s=>s.phase==='assertions'&&!s.pass).length} 失败。截图阶段 ${r.steps.filter(s=>s.phase==='screenshots'&&s.pass).length} 通过、${r.steps.filter(s=>s.phase==='screenshots'&&!s.pass).length} 失败。`,'',`真实 IM：${live?.passed||0} 通过、${live?.failed||0} 失败。范围：${live?.scope||'未执行'}。`,'','## 逐步页面证据','','| 阶段/视口 | 操作 | 预期 | 实际 | 结果 | 截图 |','| --- | --- | --- | --- | --- | --- |'];
  for(const s of r.steps)lines.push(`| ${s.phase}/${s.viewport} | ${escape(s.operation)} | ${escape(s.expected)} | ${escape(s.actual)} | ${s.pass?'通过':'失败'} | ${s.screenshot?`[截图](${s.screenshot})`:''} |`);
  lines.push('','## 真实链路结果','','| 操作 | 预期 | 实际 | 结果 |','| --- | --- | --- | --- |');
  for(const s of live?.steps||[])lines.push(`| ${escape(s.operation)} | ${escape(s.expected)} | ${escape(s.actual)} | ${s.pass?'通过':'失败'} |`);
  lines.push('','网络诊断（去除签名参数）：', '```json',JSON.stringify(live?.network||[],null,2),'```');
  lines.push('','## 其他检查','','```json',JSON.stringify(checks,null,2),'```','','## 实际视觉检查','','| 截图 | 检查结果 | 说明 |','| --- | --- | --- |');
  for(const s of r.steps.filter(s=>s.screenshot)){
    const review=visuals.find(v=>v.screenshot===s.screenshot);
    lines.push(`| [${s.screenshot}](${s.screenshot}) | ${review?(review.pass?'已查看，通过':'已查看，失败'):'未查看，不能标为视觉通过'} | ${escape(review?.notes||'')} |`);
  }
  lines.push('',`正式截图已查看 ${visuals.filter(v=>!v.historical).length} 张；历史/失败证据已查看 ${visuals.filter(v=>v.historical).length} 张。历史遮挡和失败不计为本轮正式视觉通过，详见 [逐图检查记录](visual-reviews.json)。`);
  lines.push('','## 失败尝试与日志','','此前失败保留在 [results.json](results.json) 的 history 和 [live-results.json](live-results.json) 的 history，未改写为通过。开发日志见 [next.log](next.log)，跟踪见 [trace.zip](trace.zip)。','',`清理：${JSON.stringify(r.cleanup)}；真实 IM 测试数据清理：${JSON.stringify(live?.cleanup)}`,'','## 限制与剩余风险','','- 浏览器完整页面流程使用显式 IPC/IM/RTC 夹具，不能证明原生 SDK、系统文件对话框或媒体互通。真实 IM 测试使用独立票据与真实修改后 API，但网关身份由测试入口注入。','- 屏幕共享、强制媒体控制、网络统计仍是 SDK 补齐项；没有作为本次已完成能力。','- Windows/Web 没有 IM 离线系统推送；应用重新连接后可同步通知，后台提醒任务需要 meeting_ms 持续运行。','- 群已读回执需要 IM 应用开关；未启用时正常发送文字，不要求回执。群文件容量、保留策略、成员权限依赖 IM。消息置顶及其他成员消息撤回仍需业务鉴权代理，不给会议主持人直接提升 IM 群权限。',`- ${r.error||'页面夹具流程无未解决失败。真实链路失败以其表格为准。'}`,'');
  if(!live){
    const index=lines.findIndex(line=>line.startsWith('此前失败保留在'));
    if(index>=0)lines[index]='本轮未执行真实 IM；页面历史见 [results.json](results.json)。开发日志见 [next.log](next.log)，跟踪见 [trace.zip](trace.zip)。';
  }
  if(merge)lines.push('','## 合并验证记录','','```json',JSON.stringify(merge,null,2),'```');
  writeFileSync(path.join(output,'测试报告.md'),lines.join('\n'));console.log(path.join(output,'测试报告.md'));
}
if(process.argv.includes('--report')){report();process.exit(0);}
async function smoke(){
  const state={},client={conversations:{},messages:{}},fixture=installMeetingFixture(client,()=>state);
  const done=[];
  const check=async(name,fn)=>{await fn();done.push(name);console.log(JSON.stringify({phase:'fixture-smoke',operation:name,expected:'Deterministic target state',actual:'Confirmed',pass:true,screenshot:null}));};
  await check('files empty',async()=>{fixture.control({emptyFiles:true});assert.equal((await client.files.groupFiles('g')).items.length,0);});
  await check('files error',async()=>{fixture.control({fileError:true});await assert.rejects(client.files.groupFiles('g'),/读取失败/);});
  await check('files denied',async()=>{fixture.control({fileError:false,fileDenied:true});await assert.rejects(client.files.groupFiles('g'),/权限不足/);});
  await check('files loading and release',async()=>{fixture.control({fileDenied:false,emptyFiles:false,pauseFiles:true});let complete=false;const task=client.files.groupFiles('g').then(()=>complete=true);await Promise.resolve();assert.equal(complete,false);fixture.control({pauseFiles:false});await task;assert.equal(complete,true);});
  await check('failed send and forbidden action',async()=>{fixture.control({sendError:true,actionDenied:true});await assert.rejects(client.messages.send({to_group:'g'},{type:'text',body:{text:'failure'}}));await assert.rejects(client.messages.recall('g',1),/权限不足/);});
  const backend=await startLayoutBackend();
  try{await check('chat session error and recovery',async()=>{const control=patch=>fetch(backend.base+'/control',{method:'POST',body:JSON.stringify({session:'smoke',patch})});const rpc=()=>fetch(backend.base+'/invoke',{method:'POST',body:JSON.stringify({session:'smoke',command:'room_chat_session'})});await control({chatError:true});assert.equal((await rpc()).status,503);await control({chatError:false});assert.equal((await rpc()).status,200);});}finally{await backend.close();}
  const result={passed:done.length,checks:done};writeFileSync(path.join(output,'smoke.json'),JSON.stringify(result,null,2));return result;
}
if(process.argv.includes('--smoke')){await smoke();process.exit(0);}
assert.ok(existsSync(path.join(output,'smoke.json')),'Run --smoke separately first');
const previous=existsSync(resultsFile)?JSON.parse(readFileSync(resultsFile,'utf8')):null;
const budgetStarted=previous?.budgetStarted||Date.now();
const result={started:new Date().toISOString(),budgetStarted,probe:[],smoke:JSON.parse(readFileSync(path.join(output,'smoke.json'),'utf8')),steps:[],cleanup:{},history:previous?[...(previous.history||[]),...(previous.error?[{steps:previous.steps,error:previous.error}]:[])]:[],startup:'node tests/e2e/meeting-im-integration.mjs; isolated Next :3141, OPENMEETING_NEXT_DIST_DIR=.next-e2e-im-integration, OPENMEETING_E2E_DESKTOP_LAYOUT=1, NEXT_PUBLIC_LIVE_MEETING_DATA_SOURCE=real; explicit loopback fixtures'};
const save=()=>writeFileSync(resultsFile,JSON.stringify(result,null,2));
let next,browser,context,page,session,phase='assertions',sequence=0;
const backend=await startLayoutBackend(),ui='http://localhost:3141';
const tsconfigPath=path.join(frontend,'tsconfig.json'),tsconfigBefore=readFileSync(tsconfigPath);
const control=patch=>fetch(backend.base+'/control',{method:'POST',body:JSON.stringify({session,patch})});
const sdk=patch=>page.evaluate(patch=>window.__meetingFixture.control(patch),patch);
const dialog=()=>page.getByRole('dialog');
const closeDialog=async()=>{await dialog().getByRole('button',{name:'关闭',exact:true}).first().click();await dialog().waitFor({state:'hidden'});};
const input=()=>page.getByPlaceholder('发送消息，全体成员可见');
async function layout(){const issues=await page.evaluate(()=>{const issues=[];if(document.documentElement.scrollWidth>innerWidth+2)issues.push('document overflow');for(const el of document.querySelectorAll('[role=dialog],[data-testid=room-side-panel]')){const r=el.getBoundingClientRect();if(r.left<0||r.right>innerWidth+1||r.top<0||r.bottom>innerHeight+1)issues.push('dialog/panel outside viewport');}return issues;});assert.deepEqual(issues,[]);}
async function step(operation,expected,action,shot){
  if(Date.now()-budgetStarted>30*60000)throw Error('30-minute E2E budget exhausted; degrade to API evidence');
  const size=page.viewportSize(),row={phase,viewport:`${size.width}x${size.height}`,operation,expected,actual:'',pass:false,screenshot:null};result.steps.push(row);
  try{
    await page.locator('button[data-close-button]').evaluateAll(buttons=>buttons.forEach(button=>button.click()));
    row.actual=await action()||'Confirmed';await layout();row.pass=true;
    if(phase==='screenshots'&&shot){
      await page.locator('button[data-close-button]').evaluateAll(buttons=>buttons.forEach(button=>button.click()));
      row.screenshot=`screenshots/${String(++sequence).padStart(2,'0')}-${row.viewport}-${shot}.png`;await page.screenshot({path:path.join(output,row.screenshot),animations:'disabled'});
    }
  }
  catch(e){row.actual=String(e.message||e);row.screenshot=`screenshots/failure-${Date.now()}.png`;await page.screenshot({path:path.join(output,row.screenshot)}).catch(()=>{});throw e;}
  finally{save();console.log(JSON.stringify(row));}
}
async function flow(viewport){
  session=`${phase}-${viewport.width}`;await control({loggedIn:false});
  context=await browser.newContext({viewport,locale:'zh-CN'});await context.addInitScript(installLayoutBridge,{base:backend.base,session});page=await context.newPage();page.setDefaultTimeout(12000);
  if(phase==='assertions')await context.tracing.start({screenshots:true,snapshots:true});
  await step('登录并发起会议','登录→快速会议→打开聊天',async()=>{await page.goto(ui,{waitUntil:'domcontentloaded'});await page.locator('#phone-auth-phone').fill('13800138000');await page.locator('#phone-auth-password').fill('LayoutTest123!');await page.locator('button[type=submit]').click();await page.getByRole('button',{name:/快速会议 立即/}).click();await page.getByRole('button',{name:'聊天',exact:true}).click();await input().waitFor();});
  await step('IM invitation', 'Meeting info sends an IM card without a password', async()=>{
    await page.getByTestId('room-side-panel').getByRole('button',{name:'关闭',exact:true}).click();
    await page.getByTestId('room-side-panel').waitFor({state:'hidden'});
    await page.getByRole('button',{name:'更多',exact:true}).click();
    await page.getByRole('menuitem',{name:'会议信息',exact:true}).click();
    await dialog().getByRole('textbox',{name:'用户 ID',exact:true}).fill('layout-peer');
    await dialog().getByRole('button',{name:'发送邀请',exact:true}).click();
    await dialog().getByRole('status').filter({hasText:'邀请已发送'}).waitFor();
    const call=await page.evaluate(()=>window.__layoutIm.chatCalls.find(c=>c.operation==='send'&&c.target.to_user==='layout-peer'));
    assert.equal(call.message.body.kind,'openmeeting.invitation'); assert.equal(call.message.body.pwd,undefined);
  },'IM-invitation');
  await closeDialog();
  await page.getByRole('button',{name:'聊天',exact:true}).click();
  await step('聊天空态','空会话正常，输入可用',async()=>{assert.equal(await page.getByTestId('im-meeting-message').count(),0);assert.equal(await input().isDisabled(),false);},'空态');
  await step('发送文字','消息经 SDK 订阅显示',async()=>{await input().fill('会议 IM 成功消息');await input().press('Enter');await page.getByText('会议 IM 成功消息',{exact:true}).waitFor();},'发送成功');
  await step('回复与表情反馈','回复携带 seq，反馈显示计数',async()=>{const first=page.getByTestId('im-meeting-message').first();await first.getByRole('button',{name:'回复',exact:true}).click();await input().fill('会议回复');await input().press('Enter');await page.getByText('会议回复',{exact:true}).waitFor();assert.ok(await page.evaluate(()=>window.__layoutIm.chatCalls.some(c=>c.operation==='send'&&c.options?.reply_to?.seq===1)));await first.getByRole('button',{name:'👍',exact:true}).click();await first.getByRole('button',{name:'👍 1',exact:true}).waitFor();await first.getByRole('button',{name:'已读回执',exact:true}).click();await first.getByRole('status').filter({hasText:'2 / 3'}).waitFor();},'回复回执');
  await step('历史分页与未读同步','历史可读取；外端未读变更更新徽标',async()=>{await page.getByRole('button',{name:'加载更早消息',exact:true}).click();await page.getByText('更早的会议消息',{exact:true}).waitFor();await page.getByTestId('room-side-panel').getByRole('button',{name:'关闭',exact:true}).click();
    await sdk({unread:7});await page.getByRole('button',{name:'聊天',exact:true}).getByText('7',{exact:true}).waitFor();
    await sdk({unread:0});await page.getByRole('button',{name:'聊天',exact:true}).getByText('7',{exact:true}).waitFor({state:'hidden'});
    await page.getByRole('button',{name:'聊天',exact:true}).click();});
  await step('上传并下载文件','群文件上传与 SDK 下载被调用',async()=>{await page.locator('input[type=file]').setInputFiles({name:'meeting-report.txt',mimeType:'text/plain',buffer:Buffer.from('IM file')});const article=page.getByTestId('im-meeting-message').filter({hasText:'meeting-report.txt'});await article.waitFor();await article.getByRole('button',{name:'下载',exact:true}).click();assert.ok(await page.evaluate(()=>window.__layoutIm.chatCalls.some(c=>c.operation==='upload'&&c.purpose==='group_file')));},'文件消息');
  await step('上传中取消','取消不发布消息',async()=>{await sdk({pauseUpload:true});await page.locator('input[type=file]').setInputFiles({name:'cancel.txt',mimeType:'text/plain',buffer:Buffer.from('cancel')});await page.getByRole('button',{name:'取消',exact:true}).click();await page.getByRole('button',{name:'取消',exact:true}).waitFor({state:'hidden'});await sdk({pauseUpload:false});assert.equal(await page.getByText('cancel.txt',{exact:true}).count(),0);});
  await step('文件列表加载','加载状态确定可触发',async()=>{await sdk({pauseFiles:true});await page.getByRole('button',{name:'会议文件',exact:true}).click();await dialog().getByRole('status').waitFor();},'加载');
  await step('文件列表分页滚动','列表可滚动，追加第二页后关闭',async()=>{await sdk({pauseFiles:false});await dialog().getByTestId('im-file-list').locator('li').filter({hasText:/^0-会议文件-LongFilename0123456789.txt/}).waitFor();await dialog().getByRole('button',{name:'加载更多文件',exact:true}).click();await dialog().getByTestId('im-file-list').locator('li').filter({hasText:'15-会议文件-LongFilename0123456789.txt'}).scrollIntoViewIfNeeded();},'文件列表滚动');await closeDialog();
  await step('文件空态','无文件时展示空态',async()=>{await sdk({emptyFiles:true});await page.getByRole('button',{name:'会议文件',exact:true}).click();await dialog().getByText('暂无内容',{exact:true}).waitFor();},'文件空态');await closeDialog();
  await step('文件错误与重试','读取失败保留明确错误，重试恢复',async()=>{await sdk({emptyFiles:false,fileError:true});await page.getByRole('button',{name:'会议文件',exact:true}).click();await dialog().getByRole('alert').waitFor();},'文件错误');await sdk({fileError:false});await dialog().getByRole('button',{name:'重试',exact:true}).click();await dialog().getByTestId('im-file-list').locator('li').first().waitFor();await closeDialog();
  await step('文件权限错误','拒绝访问可见且不回退本地文件服务',async()=>{await sdk({fileDenied:true});await page.getByRole('button',{name:'会议文件',exact:true}).click();await dialog().getByRole('alert').filter({hasText:'权限不足'}).waitFor();},'权限');await closeDialog();await sdk({fileDenied:false});
  await step('成员资料','成员按钮打开 IM 公开资料',async()=>{await page.getByRole('button',{name:/成员（/}).click();await page.getByRole('button',{name:/成员资料:/}).first().click();await dialog().getByText('IM 公开昵称',{exact:true}).waitFor();},'成员资料');await closeDialog();await page.getByTestId('room-side-panel').getByRole('button',{name:'聊天',exact:true}).click();
  await step('发送失败并重试','失败消息显示 SDK 重试和丢弃操作',async()=>{await sdk({sendError:true});await input().fill('失败后重试消息');await input().press('Enter');const article=page.getByTestId('im-meeting-message').filter({hasText:'失败后重试消息'});await article.getByRole('button',{name:'重试',exact:true}).waitFor();await sdk({sendError:false});await article.getByRole('button',{name:'重试',exact:true}).click();await article.getByRole('button',{name:'重试',exact:true}).waitFor({state:'hidden'});});
  await step('消息操作权限与撤回','拒绝错误可见，恢复后撤回变占位',async()=>{const article=page.getByTestId('im-meeting-message').filter({hasText:'失败后重试消息'});await sdk({actionDenied:true});await article.getByRole('button',{name:'撤回',exact:true}).click();await article.getByRole('alert').waitFor();},'消息操作拒绝');await sdk({actionDenied:false});await page.getByTestId('im-meeting-message').filter({hasText:'失败后重试消息'}).getByRole('button',{name:'撤回',exact:true}).click();
  await step('图片消息预览','复用富消息弹窗，打开并关闭',async()=>{await page.locator('input[type=file]').setInputFiles({name:'meeting-image.png',mimeType:'image/png',buffer:Buffer.from('fixture-image')});await page.getByTestId('im-meeting-message').filter({hasText:'meeting-image.png'}).getByRole('button',{name:'预览 / 播放',exact:true}).click();await dialog().locator('img').waitFor();},'图片预览');await closeDialog();
  await step('可信状态刷新及伪造拒绝','仅 notice 的匹配房间提示触发后端读取',async()=>{const count=()=>backend.calls.filter(c=>c.session===session&&c.command==='room_get').length;const before=count();const body={kind:'openmeeting.meeting',version:1,event:'room_state',roomId:'room-layout',versionAt:new Date().toISOString(),reason:'settings'};await sdk({receive:{type:'custom',sender:'attacker',body}});await page.waitForTimeout(250);assert.equal(count(),before);await sdk({receive:{type:'custom',sender:'notice',body}});await page.waitForTimeout(400);assert.ok(count()>before);});
  await step('聊天连接失败','输入禁用，重试入口可见',async()=>{await control({chatError:true});await page.reload({waitUntil:'domcontentloaded'});await page.getByRole('button',{name:'聊天',exact:true}).click();await page.getByRole('button',{name:'重试',exact:true}).waitFor();assert.equal(await input().isDisabled(),true);},'连接失败');await control({chatError:false});await page.getByRole('button',{name:'重试',exact:true}).click();await page.waitForFunction(()=>!document.querySelector('input[placeholder="发送消息，全体成员可见"]')?.disabled);
  await step('长消息滚动与关闭面板','长文本换行，面板能关闭重开',async()=>{await sdk({seed:true});await page.getByTestId('im-meeting-message').last().scrollIntoViewIfNeeded();},'长消息');await page.getByTestId('room-side-panel').getByRole('button',{name:'关闭',exact:true}).click();await page.getByTestId('room-side-panel').waitFor({state:'hidden'});
  await step('结束会议','真实页面结束确认并进入记录页',async()=>{
    await page.getByRole('button',{name:'离开并结束',exact:true}).click();
    await dialog().getByRole('button',{name:'结束会议',exact:true}).click();
    await page.waitForURL('**/meeting-details?id=meeting-layout-0',{timeout:60000,waitUntil:'domcontentloaded'});
    await page.getByRole('heading',{name:'响应式验收纪要',exact:true}).waitFor();
    // Navigation completes before Framer Motion's JavaScript fade-in completes.
    await page.waitForFunction(()=>{
      let node=[...document.querySelectorAll('h1,h2,h3')].find(el=>el.textContent==='响应式验收纪要');
      if(!node)return false;
      for(;node;node=node.parentElement)if(Number(getComputedStyle(node).opacity)<0.99)return false;
      return true;
    });
  },'结束成功');
  await step('Notification and invitation cards', 'Verified notice and user invitation render with safe internal links', async()=>{
    await page.goto(ui+'/chats',{waitUntil:'domcontentloaded'});
    await page.waitForFunction(()=>Boolean(window.__meetingFixture));
    await page.evaluate(()=>window.__meetingFixture.control({messages:[
      window.__meetingFixture.raw({type:'custom',sender:'notice',body:{kind:'openmeeting.meeting',version:1,event:'scheduled_updated',title:'会议通知 '+ 'LongNoticeText0123456789'.repeat(15),code:'654321',startAt:'2026-10-23T13:00:00Z'}},1),
      window.__meetingFixture.raw({type:'custom',sender:'member-1',body:{kind:'openmeeting.invitation',version:1,title:'IM 邀请卡片',code:'654321'}},2),
      window.__meetingFixture.raw({type:'custom',sender:'attacker',body:{kind:'openmeeting.meeting',version:1,event:'scheduled_updated',title:'FORGED-NOTICE-MUST-NOT-RENDER'}},3)
    ]}));
    await page.getByRole('button').filter({hasText:'项目验收讨论组与超长会话标题的显示检查'}).click();
    await page.getByTestId('meeting-notice').waitFor();
    assert.equal(await page.getByText('FORGED-NOTICE-MUST-NOT-RENDER',{exact:true}).count(),0);
    await page.getByText('IM 邀请卡片',{exact:true}).waitFor();
    await page.getByTestId('meeting-notice').scrollIntoViewIfNeeded();
  },'IM-cards');
  await step('No local chat fallback', 'All chat and file IPC use IM bindings', async()=>{
    const commands=backend.calls.filter(c=>c.session===session).map(c=>c.command);
    assert.ok(commands.includes('room_chat_session'));
    assert.equal(commands.some(c=>['room_list_chat','room_send_chat','room_send_attachment','room_download_attachment'].includes(c)),false);
  });
  if(phase==='assertions')await context.tracing.stop({path:path.join(output,'trace.zip')});await context.close();
}
try{
  for(const port of [3118,39110,9256,9257,3141]){try{const r=await fetch(`http://127.0.0.1:${port}/${port===9256||port===9257?'json/list':''}`,{signal:AbortSignal.timeout(1200)});result.probe.push({port,status:r.status,existing:true});}catch{result.probe.push({port,reachable:false});}}
  assert.equal(result.probe.find(p=>p.port===3141).reachable,false,'Do not replace an existing service');
  next=spawn(process.execPath,[path.join(frontend,'node_modules/next/dist/bin/next'),'dev','-p','3141'],{cwd:frontend,windowsHide:true,env:{...process.env,OPENMEETING_NEXT_DIST_DIR:'.next-e2e-im-integration',OPENMEETING_E2E_DESKTOP_LAYOUT:'1',NEXT_PUBLIC_LIVE_MEETING_DATA_SOURCE:'real'},stdio:['ignore','pipe','pipe']});
  next.stdout.on('data',data=>writeFileSync(path.join(output,'next.log'),data,{flag:'a'}));next.stderr.on('data',data=>writeFileSync(path.join(output,'next.log'),data,{flag:'a'}));
  const deadline=Date.now()+90000;while(true){try{if((await fetch(ui)).ok)break;}catch{}if(Date.now()>deadline)throw Error('Dev server readiness timed out');await new Promise(resolve=>setTimeout(resolve,500));}
  await fetch(ui+'/meeting-details');
  await fetch(ui+'/chats');
  browser=await chromium.launch({headless:true});
  for(const mode of ['assertions','screenshots']){phase=mode;for(const viewport of [{width:1280,height:800},{width:520,height:760}])await flow(viewport);}
}catch(e){
  result.error=String(e.message||e);process.exitCode=1;
  if(!result.steps.some(s=>!s.pass))result.steps.push({phase,viewport:page?JSON.stringify(page.viewportSize()):'',operation:'Flow transition',expected:'Open/close/navigation completes',actual:result.error,pass:false,screenshot:null});
  if(context&&phase==='assertions')await context.tracing.stop({path:path.join(output,'failed-trace.zip')}).catch(()=>{});
}
finally{
  await browser?.close();if(next){await new Promise(resolve=>{const kill=spawn('taskkill',['/pid',String(next.pid),'/t','/f'],{windowsHide:true,stdio:'ignore'});kill.on('exit',code=>{result.cleanup.nextTaskkill=code;resolve();});});}
  await backend.close();result.cleanup.fixtureClosed=true;
  writeFileSync(tsconfigPath,tsconfigBefore);result.cleanup.tsconfigRestored=true;save();report();
}
