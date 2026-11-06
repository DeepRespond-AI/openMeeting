import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
import {mkdirSync,readFileSync,writeFileSync,existsSync,appendFileSync} from 'node:fs';
import {spawn} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
import {startLayoutBackend,installLayoutBridge} from './fixtures/desktop-layout-backend.mjs';
const root=fileURLToPath(new URL('../../',import.meta.url)),frontend=path.join(root,'frontend');
const output=path.resolve(root,process.env.DESKTOP_RESPONSIVE_OUTPUT||'.artifacts/桌面响应式布局');mkdirSync(output,{recursive:true});
const require=createRequire(path.join(frontend,'package.json')),{chromium}=require('playwright');
const resultsFile=path.join(output,'results.json');
function report(){
  const r=JSON.parse(readFileSync(resultsFile,'utf8'));
  const reviews=existsSync(path.join(output,'visual-reviews.json'))?JSON.parse(readFileSync(path.join(output,'visual-reviews.json'),'utf8')):{};
  const rows=r.steps.filter(s=>s.phase==='assertions'),passed=rows.filter(s=>s.pass).length,failed=r.steps.filter(s=>!s.pass).length;
  const images=r.steps.filter(s=>s.screenshot);
  const lines=['# 电脑端响应式布局测试报告','','## 分级与边界','','本次为跨页面布局变更，执行完整开发版页面 E2E，覆盖 7 条路由、设置 5 个页签以及邀请、预定、抽屉、弹窗、长文本和滚动。使用真实 Next.js 开发页面及生产组件/状态逻辑；显式测试分支替换原生 IPC、业务数据与 IM/RTC，未把夹具结果计为真实原生或音视频互通。未使用 in-app browser，采用 Playwright 无头 Chromium。','',`开始：${r.started}；E2E 调试预算：30 分钟。`, `现有服务/登录态探测：${JSON.stringify(r.probe)}。现有原生 CDP 不可连接，无法读取/复用原生登录态；保留既有 3118 服务及客户端，不修改账号数据，使用隔离测试会话执行登录表单。`,'',`启动方式：${r.startup}`,'',`断言阶段：通过 ${passed}，失败 ${failed}。失败尝试及证据保留在 steps 中。夹具冒烟：${r.smoke?.passed||0} 项通过。`,'','## 逐步结果','','| 阶段/视口 | 操作 | 预期 | 实际 | 结果 | 截图 |','| --- | --- | --- | --- | --- | --- |'];
  for(const s of r.steps)lines.push(`| ${s.phase}/${s.viewport||'服务'} | ${s.operation.replaceAll('|','/')} | ${s.expected.replaceAll('|','/')} | ${String(s.actual).replaceAll('|','/').replaceAll('\n',' ')} | ${s.pass?'通过':'失败'} | ${s.screenshot?`[截图](${s.screenshot})`:'—'} |`);
  const checksPath=path.join(output,'checks.json');
  if(existsSync(checksPath)){
    const checks=JSON.parse(readFileSync(checksPath,'utf8')).checks;
    lines.push('','## 静态与契约检查','','原始输出：[checks.json](checks.json)。这些契约使用替代 SDK 与设备，不计为真实硬件验收。','');
    for(const check of checks)lines.push(`- ${check.label}：${check.exit_code===0?'通过':'失败/未完成'}；命令：\`${check.command}\`。`);
  }
  const historical=(r.history||[]).flatMap(attempt=>attempt.steps.filter(s=>!s.pass).map(s=>({...s,started:attempt.started})));
  lines.push('','## 调试失败留档','',`最终回归与调试尝试分开统计。此前 ${historical.length} 项失败保留原始证据，未计入通过项：`,'','| 时间 | 操作 | 原因/实际 | 证据 |','| --- | --- | --- | --- |');
  for(const s of historical)lines.push(`| ${s.started} | ${s.operation} | ${String(s.actual).replaceAll('|','/').replaceAll('\n',' ')} | ${s.screenshot?`[失败截图](${s.screenshot})`:'—'} |`);
  lines.push('','调试修正包括：IPC 错误字符串形状、预定成功 Toast 与列表同文案的定位范围、音频后端信息夹具字段、设备按钮定位方式、IM MessageView._local 字段。最终回归重新执行以上路径。','', '## 逐张视觉检查','','检查范围：遮挡、横向溢出、错位、必要截断提示、层级、窗口响应式；可滚动区域通过真实滚动验证。截图未查看时仅记为待检查。','','| 截图 | 视口 | 实际检查结论 |','| --- | --- | --- |');
  for(const s of images){const review=reviews[s.screenshot];lines.push(`| [${s.screenshot}](${s.screenshot}) | ${s.viewport} | ${review||'待实际查看，未标记视觉通过'} |`);}
  lines.push('','## 服务关闭与保留项','',JSON.stringify(r.cleanup),'','## 剩余风险','','- 本轮未控制真实 Tauri/WebView2 登录态，未验证真实 IM/RTC、麦克风、通知或系统文件对话框；这些不能由浏览器 IPC/HTTP 夹具替代验收。','- 常规桌面 1280×800、窄窗口 640×600，附加会议窗口 900×650、1200×420 和 24 人压力场景；未验收全部操作系统、DPI 和语言组合。','- 失败记录以实际产物为准，不将未执行路径标为通过。','');
  lines.push('- 首次安装引导、真实系统文件对话框和全部子弹窗未纳入本轮主页面布局回归。');
  writeFileSync(path.join(output,'测试报告.md'),lines.join('\n'));
}
if(process.argv.includes('--report')){report();process.exit(0);}
const previous=existsSync(resultsFile)?JSON.parse(readFileSync(resultsFile,'utf8')):null;
const started=previous?.budgetStarted||Date.now(),budget=30*60000;
const result={started:new Date().toISOString(),probe:[],startup:'复用 :3118 进行服务探测；隔离 Next 开发服务 :3138，OPENMEETING_NEXT_DIST_DIR=.next-e2e-layout、OPENMEETING_E2E_DESKTOP_LAYOUT=1、NEXT_PUBLIC_LIVE_MEETING_DATA_SOURCE=real；另启动随机回环端口 HTTP 夹具。',steps:[],cleanup:{}};
result.budgetStarted=started;
result.history=[...(previous?.history||[]),...(previous?.error?[{started:previous.started,steps:previous.steps,error:previous.error}]:[])];
const save=()=>writeFileSync(resultsFile,JSON.stringify(result,null,2));
const backend=await startLayoutBackend();let next,browser,context,page,phase='assertions',viewport='',sequence=0;
const ui='http://localhost:3138';
async function control(session,patch){const response=await fetch(backend.base+'/control',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({session,patch})});assert.equal(response.status,200);return response.json();}
async function rpc(session,command,args={}){const response=await fetch(backend.base+'/invoke',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({session,command,args})});return {status:response.status,data:await response.json()};}
async function step(operation,expected,action,shot){
  if(Date.now()-started>budget)throw Error('E2E 30 minute budget exhausted');
  const item={phase,viewport,operation,expected,actual:'',pass:false,screenshot:null};result.steps.push(item);
  try {
    if(page)await page.locator('button[data-close-button]').evaluateAll(buttons=>buttons.forEach(button=>button.click()));
    item.actual=await action()||'符合预期';item.pass=true;
    if(page){const actual=page.viewportSize();item.viewport=`${actual.width}x${actual.height}`;}
    if(phase==='screenshots'&&shot){
      if(['首页','预定成功'].includes(shot))await page.locator('button[data-close-button]').evaluateAll(buttons=>buttons.forEach(button=>button.click()));
      sequence++;item.screenshot=`screenshots/${String(sequence).padStart(2,'0')}-${item.viewport}-${shot}.png`;await page.screenshot({path:path.join(output,item.screenshot),animations:'disabled'});
    }
  }
  catch(error){item.actual=String(error.message||error);if(page){sequence++;item.screenshot=`screenshots/${Date.now()}-${viewport}-失败.png`;await page.screenshot({path:path.join(output,item.screenshot)}).catch(()=>{});}throw error;}
  finally {save();console.log(JSON.stringify(item));}
}
async function layout(){
  const issues=await page.evaluate(()=>{
    const root=document.documentElement;
    const problems=[];
    if(root.scrollWidth>innerWidth+2)problems.push(`document ${root.scrollWidth}>${innerWidth}`);
    const content=document.querySelector('[data-testid="desktop-content"]');
    if(content&&content.scrollWidth>content.clientWidth+2)problems.push('content horizontally clipped');
    for(const el of document.querySelectorAll('[role="dialog"], [data-testid="room-toolbar-region"], [data-testid="room-side-panel"], [data-testid="participant-grid"]')){
      if(!el.getClientRects().length)continue;const r=el.getBoundingClientRect();
      if(r.left< -1||r.right>innerWidth+1)problems.push(`${el.getAttribute('data-testid')||el.getAttribute('role')} outside horizontal viewport`);
      if(el.getAttribute('role')==='dialog'&&(r.top< -1||r.bottom>innerHeight+1))problems.push('dialog outside vertical viewport');
    }return problems;
  });assert.deepEqual(issues,[]);return '页面、网格、操作栏及打开的弹窗/侧栏均未横向越界';
}
const closeDialog=async()=>{await page.getByRole('dialog').getByRole('button',{name:'关闭',exact:true}).click();await page.getByRole('dialog').waitFor({state:'hidden'});};
async function goto(route){await page.goto(ui+route,{waitUntil:'domcontentloaded',timeout:60000});}
async function smoke(){
  const s='smoke';const cases=[];
  await control(s,{scheduleError:true,detailError:true,joinError:true,permission:true});
  for(const [cmd,status]of [['sched_create',503],['api_get_meeting_metadata',503],['room_join',404]]){const r=await rpc(s,cmd);assert.equal(r.status,status);cases.push({command:cmd,status:r.status,pass:true});}
  assert.deepEqual((await rpc(s,'get_audio_devices')).data.value,[]);cases.push({command:'permission-empty-devices',pass:true});
  assert.ok(Array.isArray((await rpc(s,'get_audio_backend_info')).data.value));cases.push({command:'audio-backend-shape',pass:true});
  await control(s,{scheduleError:false,detailError:false,joinError:false,permission:false,delay:100});
  const tick=Date.now();assert.equal((await rpc(s,'sched_create',{title:'smoke'})).status,200);assert.ok(Date.now()-tick>=90);cases.push({command:'async-delay-and-success',pass:true});
  result.smoke={passed:cases.length,cases};save();console.log(JSON.stringify({phase:'fixture-smoke',...result.smoke}));
}
async function exercise(width,height){
  viewport=`${width}x${height}`;const session=`${phase}-${viewport}`;
  await control(session,{loggedIn:false,participants:5,empty:false,detailError:false,joinError:false,scheduleError:false,delay:0,permission:false,scheduled:[]});
  context=await browser.newContext({viewport:{width,height},locale:'zh-CN'});await context.addInitScript(installLayoutBridge,{base:backend.base,session});
  page=await context.newPage();page.setDefaultTimeout(12000);
  const errors=[];page.on('pageerror',error=>errors.push(error.message));
  try{
    await step('登录失败后登录成功','错误展示明确；随后进入真实首页',async()=>{
      await goto('/');await page.locator('#phone-auth-phone').fill('13800138000');await page.locator('#phone-auth-password').fill('WrongPassword123!');await page.locator('button[type="submit"]').click();await page.getByRole('alert').filter({hasText:'账号或密码不正确'}).waitFor();await layout();
      await page.locator('#phone-auth-password').fill('LayoutTest123!');await page.locator('button[type="submit"]').click();await page.getByRole('button',{name:/快速会议 立即/}).waitFor();return layout();
    },'首页');
    await step('打开预定并显示加载态','保存期间按钮禁用，弹窗在窗口内',async()=>{
      await page.getByRole('button',{name:/预定会议/}).first().click();await page.locator('#sched-title').fill('响应式验收预定会议');await control(session,{delay:1800,scheduleError:true});await page.getByRole('dialog').locator('button[type="submit"]').click();await page.getByRole('button',{name:'正在保存…',exact:true}).waitFor();return layout();
    },'预定加载');
    await step('预定失败展示长错误并保留输入','错误可读、可滚动、输入未丢失',async()=>{
      await page.getByRole('dialog').getByRole('alert').waitFor();assert.equal(await page.locator('#sched-title').inputValue(),'响应式验收预定会议');await page.getByRole('dialog').evaluate(el=>el.scrollTop=el.scrollHeight);return layout();
    },'预定错误');
    await step('预定重试成功并关闭弹窗','首页出现创建的预定记录',async()=>{
      await control(session,{delay:0,scheduleError:false});await page.getByRole('dialog').locator('button[type="submit"]').click();await page.getByRole('dialog').waitFor({state:'hidden'});await page.getByTestId('desktop-content').getByText('响应式验收预定会议',{exact:true}).waitFor();return layout();
    },'预定成功');
    await step('会议列表及真实滚动','列表可滚到底部并打开第一条会议',async()=>{
      await goto('/meetings');await page.getByText('响应式验收会议记录 26',{exact:true}).scrollIntoViewIfNeeded();await layout();return '26 条会议记录可滚动，末条可见';
    },'会议列表滚动');
    await step('打开会议详情信息','长标题正常、信息页可访问',async()=>{
      await page.locator('[role="button"]').filter({hasText:'产品设计评审'}).first().click();await page.getByRole('tab',{name:'会议信息',exact:true}).click();await page.getByRole('tabpanel').filter({visible:true}).waitFor();return layout();
    },'会议详情信息');
    await step('转写列表真实滚动','转写有明确滚动距离且底部内容可达',async()=>{
      await page.getByRole('tab',{name:'转写',exact:true}).click();await page.getByText(/第 1 条转写/).first().waitFor();const scroll=page.getByRole('tabpanel',{name:'转写',exact:true}).locator('[class*="overflow-y-auto"]').first();await scroll.evaluate(el=>el.scrollTop=el.scrollHeight);assert.ok(await scroll.evaluate(el=>el.scrollTop>0));const last=page.getByText('第 65 条转写，讨论响应式布局和邀请入会占位卡片。',{exact:true});await last.scrollIntoViewIfNeeded();const lastBox=await last.boundingBox(),scrollBox=await scroll.boundingBox();assert.ok(lastBox&&scrollBox&&lastBox.y>=scrollBox.y&&lastBox.y+lastBox.height<=scrollBox.y+scrollBox.height+1,'last transcript is fully inside the scroll viewport');return layout();
    },'转写列表滚动');
    await step('纪要表格','纪要长表格不撑出窗口',async()=>{
      await page.getByRole('tab',{name:'AI 总结',exact:true}).click();await page.locator('[data-state="active"][role="tabpanel"]').waitFor();return layout();
    },'会议详情纪要表格');
    await step('会议详情加载与失败','加载后展示确定性错误，页面可返回',async()=>{
      await control(session,{detailError:true});await goto('/meeting-details?id=meeting-layout-error');await page.getByText('无法打开该会议',{exact:false}).waitFor();return layout();
    },'会议详情错误');await control(session,{detailError:false});
    await step('会议列表空态','没有记录时仍显示导航和空态',async()=>{
      await control(session,{empty:true});await goto('/meetings');await page.getByText('暂无会议',{exact:true}).waitFor();return layout();
    },'会议空态');await control(session,{empty:false});
    await step('录音页面及设备弹层','设备弹层打开、关闭；短窗口内容可滚动',async()=>{
      await goto('/record');await page.getByRole('button',{name:/布局测试麦克风/}).first().click();await page.getByText('麦克风',{exact:true}).first().waitFor();await layout();await page.keyboard.press('Escape');return layout();
    },'录音');
    await step('录音权限空态','无麦克风时页面可读且不溢出',async()=>{
      await control(session,{permission:true});await page.reload({waitUntil:'domcontentloaded'});await page.getByTitle('音频设备',{exact:true}).first().click();await page.getByText('未找到麦克风',{exact:true}).first().waitFor();return layout();
    },'录音权限');await page.keyboard.press('Escape');await control(session,{permission:false});
    for(const tab of ['server','general','recording','beta','about'])await step(`设置页 ${tab}`,'页签可进入、内容可滚动、无横向溢出',async()=>{
      await goto('/settings?tab='+tab);await page.locator(`#settings-panel-${tab}`).waitFor();await page.locator(`#settings-panel-${tab}`).evaluate(el=>{let node=el.parentElement;while(node&&node.scrollHeight<=node.clientHeight)node=node.parentElement;if(node)node.scrollTop=node.scrollHeight;});return layout();
    },'设置-'+tab);
    await step('消息页打开长消息会话','真实消息界面、长文本和输入框不溢出',async()=>{
      await goto('/chats');await page.getByRole('button').filter({hasText:'项目验收讨论组'}).first().click();await page.getByText(/长消息：/).waitFor();return layout();
    },'消息会话');
    await step('消息错误及重试','连接错误可读，重试恢复页面',async()=>{
      await page.evaluate(()=>{window.__layoutIm.mode='error';window.dispatchEvent(new Event('layout-im-change'));});await page.getByText(/测试夹具：消息连接失败/).waitFor();await layout();
    },'消息错误');await page.getByRole('button',{name:/重试/}).click();
    await step('快速会议进入五人网格','五位成员及一个邀请占位，网格可随窗口改变',async()=>{
      await goto('/');await page.getByRole('button',{name:/快速会议 立即/}).click();await page.getByTestId('participant-grid').waitFor();assert.equal(await page.getByTestId('participant-tile').count(),5);const columns=Number(await page.getByTestId('participant-grid').getAttribute('data-columns'));assert.equal(await page.getByTestId('invite-tile').count(),5%columns?1:0);return layout();
    },'五人网格');
    await step('五人两列补位','900px 两列三行，邀请卡补齐第六格',async()=>{
      await page.setViewportSize({width:900,height:650});await page.waitForFunction(()=>document.querySelector('[data-testid="participant-grid"]')?.getAttribute('data-columns')==='2');
      assert.equal(await page.getByTestId('participant-grid').getAttribute('data-rows'),'3');assert.equal(await page.getByTestId('invite-tile').count(),1);return layout();
    },'五人两列补位');
    await step('聚焦及退出后再次缩放','聚焦恢复后仍能随容器变化重排',async()=>{
      await page.getByTestId('participant-tile').first().click();await page.getByRole('button',{name:'还原宫格',exact:true}).click();
      await page.setViewportSize({width:1280,height:800});await page.waitForFunction(()=>document.querySelector('[data-testid="participant-grid"]')?.getAttribute('data-columns')==='3');await page.setViewportSize({width,height});return layout();
    },'缩放恢复');
    await step('邀请成功和权限失败','成功写入邀请；拒绝剪贴板后明确失败提示',async()=>{
      const copy=async()=>{if(await page.getByTestId('invite-tile').count())await page.getByTestId('invite-tile').click();else{await page.getByTitle('会议信息',{exact:true}).first().click();await page.getByRole('button',{name:'复制邀请信息',exact:true}).click();await page.keyboard.press('Escape');}};
      await copy();await page.waitForFunction(()=>window.__layoutClipboard?.includes('654321'));
      await page.evaluate(()=>window.__layoutDenyClipboard=true);await copy();await page.getByText('复制失败，请允许剪贴板访问后重试。',{exact:true}).waitFor();return layout();
    },'邀请权限错误');
    await step('成员侧栏打开滚动关闭','桌面重排、窄窗口抽屉；操作栏和关闭按钮可访问',async()=>{
      await page.getByRole('button',{name:'成员',exact:true}).click();await page.getByTestId('room-side-panel').waitFor();await layout();
      if(width>=1024){const panel=await page.getByTestId('room-side-panel').boundingBox(),stage=await page.getByTestId('video-stage').boundingBox();assert.ok(stage.x+stage.width<=panel.x+1);}return '侧栏打开，布局无覆盖/越界';
    },'成员侧栏');
    await page.getByTestId('room-side-panel').getByRole('button',{name:'关闭',exact:true}).click();
    await step('末行多格补齐及多人短窗口','四人三列时邀请卡跨两格；24 人短窗口可滚到底且工具栏不被挤走',async()=>{
      await control(session,{participants:4});let snapshot=(await rpc(session,'room_get')).data.value;
      await page.setViewportSize({width:1280,height:800});await page.evaluate(room=>window.__layoutEmit('room-event',{type:'room_state',ts:new Date().toISOString(),data:{room},roomId:room.id}),snapshot);
      await page.waitForFunction(()=>document.querySelector('[data-testid="participant-grid"]')?.getAttribute('data-columns')==='3');await page.getByTestId('participant-tile').last().waitFor();assert.equal(await page.getByTestId('participant-tile').count(),4);assert.equal(await page.getByTestId('invite-tile').evaluate(el=>el.style.gridColumn),'span 2');
      await control(session,{participants:24});snapshot=(await rpc(session,'room_get')).data.value;await page.evaluate(room=>window.__layoutEmit('room-event',{type:'room_state',ts:new Date().toISOString(),data:{room},roomId:room.id}),snapshot);await page.setViewportSize({width:1200,height:420});await page.getByTestId('participant-tile').last().scrollIntoViewIfNeeded();assert.equal(await page.getByTestId('participant-tile').count(),24);assert.ok(await page.getByTestId('video-stage').evaluate(el=>el.scrollTop>0));return layout();
    },'多人短窗口滚动');
    await control(session,{participants:5});await page.evaluate(room=>window.__layoutEmit('room-event',{type:'room_state',ts:new Date().toISOString(),data:{room},roomId:room.id}),(await rpc(session,'room_get')).data.value);await page.setViewportSize({width,height});
    await step('聊天抽屉长消息与关闭','发送长消息后自动换行、可关闭抽屉',async()=>{
      await page.getByRole('button',{name:'聊天',exact:true}).click();await page.getByPlaceholder('发送消息，全体成员可见').fill('响应式长消息 '+ 'LongUnbrokenText'.repeat(40));await page.getByTestId('room-side-panel').getByRole('button',{name:'发送',exact:true}).click();await page.getByText(/响应式长消息/).waitFor();return layout();
    },'会议聊天长文本');
    await page.getByTestId('room-side-panel').getByRole('button',{name:'关闭',exact:true}).click();
    await step('退出弹窗与取消','确认弹窗始终在视口内；取消恢复网格',async()=>{
      await page.getByRole('button',{name:'离开并结束',exact:true}).click();await page.getByRole('dialog').waitFor();return layout();
    },'退出弹窗');await closeDialog();
    await step('完成完整页面用户操作流程','结束测试会议回到首页，页面无运行错误',async()=>{
      await page.getByRole('button',{name:'离开并结束',exact:true}).click();await page.getByRole('dialog').getByRole('button',{name:'结束会议',exact:true}).click();await page.waitForURL(new URL('/',ui).href);assert.deepEqual(errors,[]);return '登录→预定→会议记录/详情→录音/设置/消息→会议邀请/聊天→结束会议返回首页全部通过';
    });
  }finally{await context.close();page=null;}
}
try{
  for(const [port,route]of [[3118,'/'],[3138,'/'],[39110,'/api/v1/auth/config'],[9256,'/json/list'],[9257,'/json/list']]){
    try{const r=await fetch(`http://127.0.0.1:${port}${route}`,{signal:AbortSignal.timeout(2500)});result.probe.push({port,status:r.status});await r.body?.cancel();}catch{result.probe.push({port,available:false});}
  }
  await smoke();if(process.argv.includes('--smoke')){console.log('Fixture smoke complete');}
  else{
    assert.ok(!result.probe.find(probe=>probe.port===3138)?.status,'Port 3138 already has a service; preserve it and choose another isolated port before testing');
    const log=path.join(output,'next.log');next=spawn(process.execPath,[path.join(frontend,'node_modules/next/dist/bin/next'),'dev','-p','3138'],{cwd:frontend,env:{...process.env,OPENMEETING_NEXT_DIST_DIR:'.next-e2e-layout',OPENMEETING_E2E_DESKTOP_LAYOUT:'1',NEXT_PUBLIC_LIVE_MEETING_DATA_SOURCE:'real'},windowsHide:true,stdio:['ignore','pipe','pipe']});
    next.stdout.on('data',chunk=>appendFileSync(log,chunk));next.stderr.on('data',chunk=>appendFileSync(log,chunk));
    const deadline=Date.now()+90000;let ready=false;
    while(Date.now()<deadline){try{const r=await fetch(ui,{signal:AbortSignal.timeout(5000)});await r.body.cancel();if(r.ok){ready=true;break;}}catch{}await new Promise(resolve=>setTimeout(resolve,500));}assert.ok(ready,'Isolated Next server failed to start');
    for(const route of ['/meetings','/meeting-details','/record','/settings','/im','/room']){
      const response=await fetch(ui+route,{signal:AbortSignal.timeout(60000)});await response.body?.cancel();
    }
    browser=await chromium.launch({headless:true});mkdirSync(path.join(output,'screenshots'),{recursive:true});
    for(const size of [[1280,800],[640,600]])await exercise(...size);
    phase='screenshots';for(const size of [[1280,800],[640,600]])await exercise(...size);
  }
}catch(error){result.error=String(error.stack||error);console.error(result.error);process.exitCode=1;}
finally{
  if(browser)await browser.close();result.cleanup.browserClosed=true;
  if(next){next.kill();await Promise.race([new Promise(resolve=>next.once('exit',resolve)),new Promise(resolve=>setTimeout(resolve,3000))]);result.cleanup.nextTerminationRequested=true;try{await fetch(ui,{signal:AbortSignal.timeout(1500)});result.cleanup.nextPortClosed=false;}catch{result.cleanup.nextPortClosed=true;}}
  await backend.close();result.cleanup.fixtureClosed=true;
  try{const response=await fetch('http://127.0.0.1:3118/',{signal:AbortSignal.timeout(2500)});result.cleanup.existing3118Preserved=response.ok;await response.body?.cancel();}catch{result.cleanup.existing3118Preserved=false;}
  result.finished=new Date().toISOString();save();report();
}
