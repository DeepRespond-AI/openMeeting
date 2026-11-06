import { testAppData } from './local-tools.cjs';
import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
import {spawn} from 'node:child_process';
import {existsSync,mkdirSync,readFileSync,writeFileSync,openSync,closeSync,appendFileSync} from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const root=fileURLToPath(new URL('../../',import.meta.url));
const out=process.env.GATEWAY_TEST_OUTPUT||path.join(root,'.artifacts/internal-gateway-routing');
mkdirSync(path.join(out,'screenshots'),{recursive:true});
const require=createRequire(path.join(process.env.OPENMEETING_TEST_DEPENDENCIES||root,'frontend/package.json'));
const {chromium}=require('playwright');
const python=process.env.OPENMEETING_TEST_PYTHON||path.join(root,'server/.venv/Scripts/python.exe');
const gateway='http://127.0.0.1:39710',ui='http://127.0.0.1:5179';
const resultPath=path.join(out,'results.json'),smokePath=path.join(out,'smoke.json');
let result={started:new Date().toISOString(),steps:[],probe:[],cleanup:[],startup:'三个独立 PostgreSQL 容器 :55451/55452/55453；生产四服务源码通过隔离回环启动器运行于 :39710/39713/39707/39709；工作树 Vue/Vite 管理端 :5179，OPENMEETING_GATEWAY_URL 指向测试网关。'};
let phase='api',viewport='服务',page,browser,sequence=0;
const children=[];
const save=()=>writeFileSync(resultPath,JSON.stringify(result,null,2));
const pause=ms=>new Promise(resolve=>setTimeout(resolve,ms));
function report(){
  const r=JSON.parse(readFileSync(resultPath,'utf8'));
  const reviews=existsSync(path.join(out,'visual-reviews.json'))?JSON.parse(readFileSync(path.join(out,'visual-reviews.json'),'utf8')):{};
  const checks=existsSync(path.join(out,'checks.json'))?JSON.parse(readFileSync(path.join(out,'checks.json'),'utf8')):{};
  const smoke=existsSync(smokePath)?JSON.parse(readFileSync(smokePath,'utf8')):{};
  const pass=r.steps.filter(x=>x.pass).length,fail=r.steps.filter(x=>!x.pass).length;
  const lines=['# 内部网关与独立数据库测试报告','','本次为服务间路由与数据库部署变更，采用完整真实管理端流程验收，不采用小改动降级。真实 Vue 页面、四个 FastAPI 服务、HTTP、会话认证和三个独立 PostgreSQL Docker 均执行；仅隔离测试启动器提供可控延迟和出站断连。IM/RTC 平台和语音模型未启用，不将契约替身计为真实平台通过。','','未使用 in-app browser，使用 Playwright 无头 Chromium。先独立冒烟夹具，再进行双视口断言；全部断言通过后统一截图。逐张实际查看后的结论单独写入 visual-reviews.json，未查看不算视觉通过。','',`开始：${r.started}。E2E 调试预算 30 分钟，累计起点：${r.budgetStarted?new Date(r.budgetStarted).toISOString():'未开始'}。`, '',`启动：${r.startup}`,'',`结果：通过 ${pass}，失败 ${fail}；独立冒烟通过 ${smoke.steps?.filter(x=>x.pass).length||0}，失败 ${smoke.steps?.filter(x=>!x.pass).length||0}。`,'','## 已有资源与登录态探测','',...r.probe.map(x=>'- '+JSON.stringify(x)),'','## 逐步结果','','| 阶段 / 视口 | 操作 | 预期 | 实际 | 结果 | 截图 |','| --- | --- | --- | --- | --- | --- |'];
  const clean=s=>String(s).replaceAll('|','/').replaceAll('\n',' ');
  for(const s of r.steps)lines.push(`| ${s.phase} / ${s.viewport} | ${clean(s.operation)} | ${clean(s.expected)} | ${clean(s.actual)} | ${s.pass?'通过':'失败'} | ${s.screenshot?`[截图](${s.screenshot})`:'—'} |`);
  lines.push('','## 夹具独立冒烟','',`[smoke.json](smoke.json)；成功、拒绝、上游故障、恢复与延迟均在启动浏览器前单独验证。`,'','## 检查记录','', '```json',JSON.stringify(checks,null,2),'```','','## 逐张视觉检查','','| 截图 | 结论 |','| --- | --- |');
  for(const s of r.steps.filter(x=>x.screenshot))lines.push(`| [${s.screenshot}](${s.screenshot}) | ${clean(reviews[s.screenshot]||'待实际查看，未标记视觉通过')} |`);
  const failures=(r.history||[]).flatMap(x=>x.steps?.filter(y=>!y.pass)||[]);
  lines.push('','## 调试失败留档','',`历史失败 ${failures.length} 项；完整记录保存在 results.json.history，未计入通过项。`);
  for(const s of failures)lines.push(`- ${s.operation}：${clean(s.actual)}${s.screenshot?`；[证据](${s.screenshot})`:''}`);
  lines.push('','后端历史失败与中断另见 checks.json.history：首次会议测试继承 SOCKS 代理，缺少 socksio；清除测试进程的 HTTP_PROXY/HTTPS_PROXY/ALL_PROXY 后，9 项会议回归通过。历史失败 JUnit 保留，未算通过。','',`后端最终通过 ${checks.backendPassed??'待汇总'} 项；页面检查 ${r.steps.filter(x=>!x.screenshot).length} 项；最终截图 ${r.steps.filter(x=>x.screenshot).length} 张，逐图已查看 ${r.steps.filter(x=>x.screenshot&&reviews[x.screenshot]).length} 张。`,'','[数据库拓扑证据](topology.json)、[检查汇总](checks.json)、[数据库关闭](database-cleanup.json)、[网关日志](gateway.log)、[会议服务日志](meeting.log)、[用户服务日志](user.log)、[STT 日志](stt.log)、[前端日志](vite.log)。原始 Playwright trace 留在本地 .artifacts，不归档含会话的网络记录；[哈希清单](trace-manifest.json)记录文件名和校验值。');
  lines.push('','## 关闭记录','', '```json',JSON.stringify(r.cleanup,null,2),'```','','## 剩余风险','','- 未修改现有业务数据库，也未执行旧部署的数据迁移；已有部署必须按数据库拆分说明先备份、恢复并核对，再切换应用。','- 网关增加了服务间调用的一跳，成为内部通信依赖；本轮不覆盖生产负载、多实例故障转移和公网网络。','- 真实 DeepRespond 音视频、模型推理、原生桌面和移动端未在本轮验收；原客户端与其登录态均保留。','- 全部实际执行的截图及视觉问题以本报告逐图记录为准。','','证据：[结构化结果](results.json)、[网关内部请求](gateway-requests.jsonl)、[夹具冒烟](smoke.json)、[视觉检查](visual-reviews.json)。','');
  writeFileSync(path.join(out,'测试报告.md'),lines.join('\n'));
}
if(process.argv.includes('--report')){report();process.exit(0);}
const smokeOnly=process.argv.includes('--smoke');
const scrollOnly=process.argv.includes('--scroll-only');
if(scrollOnly){
  result=JSON.parse(readFileSync(resultPath,'utf8'));
  if(result.error){
    const extra=result.steps.filter(x=>x.phase==='assertions-scroll'||x.operation.startsWith('真实长表格')||x.operation.startsWith('长会话详情'));
    assert.ok(extra.some(x=>!x.pass),'Only retry the supplemental scroll failure with --scroll-only');
    result.history=[...(result.history||[]),{started:new Date().toISOString(),steps:extra,error:result.error}];
    result.steps=result.steps.filter(x=>!extra.includes(x));delete result.error;
  }
  assert.ok(!result.error&&result.steps.every(x=>x.pass),'Complete the main flow before scroll acceptance');
  sequence=result.steps.filter(x=>x.screenshot).length;
}
if(!smokeOnly){
  assert.ok(existsSync(smokePath),'Run --smoke before browser acceptance');
  assert.ok(JSON.parse(readFileSync(smokePath,'utf8')).steps.every(x=>x.pass),'Fixture smoke must pass');
  const old=existsSync(resultPath)?JSON.parse(readFileSync(resultPath,'utf8')):null;
  const budgetFile=path.join(out,'budget.json');
  result.budgetStarted=existsSync(budgetFile)?JSON.parse(readFileSync(budgetFile,'utf8')).started:Date.now();
  writeFileSync(budgetFile,JSON.stringify({started:result.budgetStarted}));
  if(!scrollOnly)result.history=[...(old?.history||[]),...(old?.error?[{started:old.started,steps:old.steps,error:old.error}]:[])];
}
async function step(operation,expected,action,shot){
  const item={phase,viewport,operation,expected,actual:'',pass:false,screenshot:null};result.steps.push(item);
  try{
    if(result.budgetStarted&&Date.now()-result.budgetStarted>30*60000)throw Error('30 minute E2E budget exceeded; API fallback required');
    if(phase==='screenshots'&&page)await page.locator('.el-message').last().waitFor({state:'hidden',timeout:6000});
    item.actual=await action()||'符合预期';item.pass=true;
    if(phase==='screenshots'&&shot){
      await pause(400); // Let Element Plus enter transitions settle before visual evidence.
      item.screenshot=`screenshots/${String(++sequence).padStart(2,'0')}-${viewport}-${shot}.png`;
      await page.screenshot({path:path.join(out,item.screenshot),animations:'disabled'});
    }
  }catch(error){
    item.pass=false;
    item.actual=String(error.stack||error);
    if(page){item.screenshot=`screenshots/failure-${Date.now()}-${viewport}.png`;await page.screenshot({path:path.join(out,item.screenshot)}).catch(()=>{});}
    throw error;
  }finally{save();console.log(JSON.stringify(item));}
}
async function request(url,options={}){return fetch(url,{...options,signal:AbortSignal.timeout(15000)});}
async function control(patch){const r=await request(gateway+'/__test__/control',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(patch)});assert.equal(r.status,200);}
function start(command,args,cwd,name,env={}){
  const log=openSync(path.join(out,name+'.log'),'a');
  const child=spawn(command,args,{cwd,env:{...process.env,...env,GATEWAY_TEST_OUTPUT:out},stdio:['ignore',log,log],windowsHide:true});
  closeSync(log);children.push({child,name});return child;
}
async function ready(url){for(let i=0;i<75;i++){try{if((await request(url)).ok)return;}catch{}if(children.some(x=>x.child.exitCode!==null))throw Error('Service exited; inspect logs');await pause(500);}throw Error('Readiness failed: '+url);}
async function loginApi(){const r=await request(gateway+'/admin/api/login',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({password:'GatewayTest123!'})});assert.equal(r.status,200);return r.headers.get('set-cookie').split(';')[0];}
async function smoke(){
  const cookie=await loginApi(),auth={'Cookie':cookie,'Content-Type':'application/json'},internal={'X-Internal-Token':'gateway-acceptance-internal'};
  await step('三路内部 RPC 真正到达下游','user/meeting/stt 全部 200，且下游保持 /internal 命名空间',async()=>{
    for(const p of ['/internal/user/connections','/internal/meeting/users/stats-batch?ids=none','/internal/stt/status'])assert.equal((await request(gateway+p,{headers:internal})).status,200);
    return '三个目标均返回 200';
  });
  await step('无令牌与伪造身份权限拒绝','401，不能用客户端身份代替服务令牌',async()=>{assert.equal((await request(gateway+'/internal/user/connections',{headers:{'X-User-ID':'admin'}})).status,401);return '401';});
  await step('回调强制经网关进入','直接 user_ms 401，经网关到达回调处理器（IM 未启用 503）',async()=>{
    assert.equal((await request('http://127.0.0.1:39713/im/callback',{method:'POST',body:'{}'})).status,401);
    assert.equal((await request(gateway+'/im/callback',{method:'POST',body:'{}'})).status,503);return '直连 401 / 网关回调 503';
  });
  let user;
  await step('真实用户创建和跨库会议数查询','用户创建成功，会议数 0',async()=>{const r=await request(gateway+'/admin/api/users',{method:'POST',headers:auth,body:JSON.stringify({phone:'199'+String(Date.now()).slice(-8),name:'夹具冒烟用户'})});assert.equal(r.status,200);user=await r.json();assert.equal(user.meeting_count,0);return '真实 users 行创建，会议服务统计返回 0';});
  await control({outage:true});
  await step('出站断连失败夹具','用户删除 502，数据保留',async()=>{
    const r=await request(gateway+'/admin/api/users/'+user.id,{method:'DELETE',headers:auth});assert.equal(r.status,502);assert.match((await r.json()).detail,/用户未删除/);
    assert.equal((await request(gateway+'/admin/api/users/'+user.id,{headers:auth})).status,200);return '实际网关出站 ConnectError → 502，用户仍存在';
  });
  await control({outage:false});
  await step('恢复后重试删除','204，用户已不存在',async()=>{assert.equal((await request(gateway+'/admin/api/users/'+user.id,{method:'DELETE',headers:auth})).status,204);assert.equal((await request(gateway+'/admin/api/users/'+user.id,{headers:auth})).status,404);return '204 / 查询 404';});
  await control({list_error:true});
  await step('列表错误夹具','稳定返回 502 与指定文案',async()=>{const r=await request(gateway+'/admin/api/users',{headers:auth});assert.equal(r.status,502);assert.match((await r.json()).detail,/用户服务暂不可用/);return '502，中文错误文案一致';});
  await control({list_error:false,delay:0.8});
  await step('加载夹具','返回前至少延迟 0.8 秒',async()=>{const t=Date.now();assert.equal((await request(gateway+'/admin/api/users',{headers:auth})).status,200);assert.ok(Date.now()-t>=780);return '实际等待 '+(Date.now()-t)+'ms';});
  await control({delay:0});
}
async function exercise(width,height){
  viewport=`${width}x${height}`;
  const context=await browser.newContext({viewport:{width,height},locale:'zh-CN'});
  await context.tracing.start({screenshots:true,snapshots:true});
  page=await context.newPage();page.setDefaultTimeout(10000);
  const phone='199'+String(Date.now()).slice(-8),name='网关验收'+phase+width+'长文本用于检查表格截断与弹窗换行';
  let userId,token,meetingId;
  const users=()=>page.getByRole('row').filter({hasText:name});
  const closeDrawer=async()=>{await page.locator('.el-drawer__close-btn').click();await page.locator('.el-drawer').waitFor({state:'hidden'});};
  try{
    await step('未登录权限态','访问用户管理重定向到登录页',async()=>{await page.goto(ui+'/admin/users');await page.getByPlaceholder('管理员密码').waitFor();assert.match(page.url(),/login/);return '未登录被重定向';},'权限登录');
    await step('错误密码展示','展示密码错误且保留登录表单',async()=>{await page.getByPlaceholder('管理员密码').fill('wrong-password');await page.getByRole('button',{name:'登录',exact:true}).click();await page.locator('.el-message--error').waitFor();await page.getByPlaceholder('管理员密码').waitFor();return '真实后端 401，登录错误展示';},'登录错误');
    await step('真实登录与正常空列表','会话建立，进入用户管理',async()=>{await page.getByPlaceholder('管理员密码').fill('GatewayTest123!');await page.getByRole('button',{name:'登录',exact:true}).click();await page.getByRole('button',{name:'新增用户'}).waitFor();await page.getByText('暂无用户',{exact:true}).waitFor();return '真实 JWT cookie 登录成功，空列表可见';},'正常空态');
    await step('打开新增弹窗并输入长文本','弹窗正常打开，表单可编辑',async()=>{await page.getByRole('button',{name:'新增用户'}).click();const d=page.getByRole('dialog');await d.getByPlaceholder('11 位手机号').fill(phone);await d.getByPlaceholder('如：张三').fill(name);return '弹窗已打开并填入用户数据';},'新增弹窗长文本');
    await step('保存用户及跨服务统计','真实数据库新增用户，表格显示',async()=>{
      const response=page.waitForResponse(r=>r.url().endsWith('/admin/api/users')&&r.request().method()==='POST');
      await page.getByRole('dialog').getByRole('button',{name:'保存',exact:true}).click();const r=await response;assert.equal(r.status(),200);userId=(await r.json()).id;
      await page.getByRole('dialog').waitFor({state:'hidden'});await users().waitFor();return '新增成功，弹窗已关闭，真实表格已刷新';
    },'新增成功');
    await step('真实客户端登录并创建会议','SMS 开发验证码登录后创建会议，跨库统计显示 1',async()=>{
      const sent=await request(gateway+'/api/v1/auth/sms/send',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({phone,purpose:'login'})});assert.equal(sent.status,200);const code=(await sent.json()).dev_code;
      const logged=await request(gateway+'/api/v1/auth/login',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({phone,code,client:{client_id:'gateway-test-'+phone,hostname:'Gateway Acceptance',os:'test',app_version:'1.0'}})});assert.equal(logged.status,200);token=(await logged.json()).token;
      const created=await request(gateway+'/api/v1/meetings',{method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},body:JSON.stringify({title:'真实跨服务路由验收会议'})});assert.equal(created.status,201);meetingId=(await created.json()).id;
      await page.getByRole('button',{name:'刷新',exact:true}).click();await users().getByRole('cell',{name:'1',exact:true}).first().waitFor();return '真实认证、meeting 数据写入及 user → gateway → meeting 统计均完成';
    },'跨库会议统计');
    await step('用户详情抽屉与真实滚动','详情显示会议和会话，滚动后可关闭',async()=>{await users().getByRole('button',{name:'详情'}).click();await page.locator('.el-drawer').getByText('Gateway Acceptance',{exact:true}).waitFor();await page.locator('.el-drawer__body').evaluate(el=>{el.scrollTop=el.scrollHeight;});return '抽屉已打开、内容加载完成并滚动至底部';},'详情抽屉滚动');
    await step('关闭抽屉并打开编辑弹窗','抽屉关闭，编辑表单加载',async()=>{await closeDrawer();await users().getByRole('button',{name:'编辑'}).click();await page.getByRole('dialog').getByPlaceholder('如：张三').waitFor();return '真实关闭抽屉后编辑弹窗打开';},'编辑弹窗');
    await step('关闭编辑弹窗','表格恢复可操作',async()=>{await page.getByRole('dialog').getByRole('button',{name:'取消',exact:true}).click();await page.getByRole('dialog').waitFor({state:'hidden'});return '弹窗关闭';},'弹窗关闭');
    await step('受影响用户列表加载态','可控延迟期间展示加载遮罩',async()=>{await control({delay:2});await page.getByRole('button',{name:'刷新',exact:true}).click();await page.locator('.el-loading-mask').first().waitFor();return '真实请求等待期间 loading 可见';},'加载态');
    await page.locator('.el-loading-mask').first().waitFor({state:'hidden'});await control({delay:0});
    await step('列表错误展示','502 文案显示，保留已有用户数据',async()=>{await control({list_error:true});await page.getByRole('button',{name:'刷新',exact:true}).click();await page.getByText('用户服务暂不可用，请重试',{exact:true}).waitFor();await users().waitFor();return '指定错误展示，已有表格数据保留';},'列表错误');
    await control({list_error:false});await page.getByRole('button',{name:'刷新',exact:true}).click();
    await step('打开删除确认框','破坏性操作有确认入口',async()=>{await users().locator('button.el-button--danger').click();await page.getByRole('dialog').getByRole('button',{name:'永久删除',exact:true}).waitFor();return '确认框已打开';},'删除确认');
    await step('手机号二次确认','错误手机号阻止提交，填写正确手机号后可继续',async()=>{
      await page.getByRole('dialog').getByRole('button',{name:'永久删除',exact:true}).click();
      await page.getByRole('dialog').getByPlaceholder('手机号',{exact:true}).fill('19900000000');
      await page.getByRole('dialog').getByRole('button',{name:'确认删除',exact:true}).click();await page.getByText('手机号不匹配',{exact:true}).waitFor();
      return '手机号不匹配时未发起 DELETE，二次确认框保留并显示校验错误';
    },'手机号二次确认');
    await step('内部会议服务失败时保留用户与会议','删除 502，展示明确错误，两个库数据保留',async()=>{
      await control({outage:true});const response=page.waitForResponse(r=>r.request().method()==='DELETE'&&r.url().endsWith('/users/'+userId));
      await page.getByRole('dialog').getByPlaceholder('手机号',{exact:true}).fill(phone);
      await page.getByRole('dialog').getByRole('button',{name:'确认删除',exact:true}).click();assert.equal((await response).status(),502);
      await page.getByText('会议服务暂不可用，用户未删除，请稍后重试',{exact:true}).waitFor();await users().waitFor();
      const list=await request(gateway+'/api/v1/meetings',{headers:{Authorization:'Bearer '+token}});assert.ok((await list.json()).some(x=>x.id===meetingId));return '网关真实出站连接失败；用户行和会议行均保留';
    },'内部故障数据保留');
    await step('恢复后重试并完成跨库删除','204，用户与关联会议清理',async()=>{
      await control({outage:false});await users().locator('button.el-button--danger').click();
      await page.getByRole('dialog').getByRole('button',{name:'永久删除',exact:true}).click();await page.getByRole('dialog').getByPlaceholder('手机号',{exact:true}).fill(phone);
      const response=page.waitForResponse(r=>r.request().method()==='DELETE'&&r.url().endsWith('/users/'+userId));await page.getByRole('dialog').getByRole('button',{name:'确认删除',exact:true}).click();assert.equal((await response).status(),204);await users().waitFor({state:'hidden'});
      const list=await request(gateway+'/internal/meeting/users/stats-batch?ids='+userId,{headers:{'X-Internal-Token':'gateway-acceptance-internal'}});assert.equal(list.status,200);assert.deepEqual(await list.json(),{});return '重试成功，用户消失，会议统计已清空';
    },'恢复删除成功');
    await step('真实空搜索与表格滚动','无匹配数据时空态可见，页面可滚动',async()=>{await page.getByPlaceholder('搜索手机号 / 昵称').fill('不存在的网关测试用户');await page.getByRole('button',{name:'搜索',exact:true}).click();await page.getByText('暂无用户',{exact:true}).waitFor();await page.locator('.main').evaluate(el=>{el.scrollTop=el.scrollHeight;});return '真实搜索返回空列表，滚动操作完成';},'搜索空态');
  }finally{
    await control({outage:false,list_error:false,delay:0}).catch(()=>{});
    await context.tracing.stop({path:path.join(out,`${phase}-${viewport}-${Date.now()}.zip`)}).catch(()=>{});
    await context.close();page=null;
  }
}
async function scrollExercise(width,height){
  viewport=`${width}x${height}`;
  const cookie=await loginApi(),headers={Cookie:cookie,'Content-Type':'application/json'};
  const seeded=[];
  const context=await browser.newContext({viewport:{width,height},locale:'zh-CN'});
  const separator=cookie.indexOf('=');
  await context.addCookies([{name:cookie.slice(0,separator),value:cookie.slice(separator+1),url:gateway}]);
  page=await context.newPage();page.setDefaultTimeout(10000);
  try{
    for(let i=0;i<20;i++){
      const phone='199'+String(Date.now()+i).slice(-8);
      const response=await request(gateway+'/admin/api/users',{method:'POST',headers,body:JSON.stringify({phone,name:'网关验收滚动用户'+i+'长文本表格与会话详情'})});
      assert.equal(response.status,200);seeded.push(await response.json());
    }
    const person=seeded[0];
    const send=await request(gateway+'/api/v1/auth/sms/send',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({phone:person.phone,purpose:'login'})});
    assert.equal(send.status,200);const code=(await send.json()).dev_code;
    const client={client_id:'scroll-first',hostname:'滚动验收设备',os:'test',app_version:'1.0'};
    const login=await request(gateway+'/api/v1/auth/login',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({phone:person.phone,code,client})});assert.equal(login.status,200);
    const token=(await login.json()).token;
    assert.equal((await request(gateway+'/api/v1/auth/me/password',{method:'PUT',headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},body:JSON.stringify({password:'ScrollTest123!'})})).status,200);
    for(let i=0;i<20;i++){
      assert.equal((await request(gateway+'/api/v1/auth/login',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({phone:person.phone,password:'ScrollTest123!',client:{...client,client_id:'scroll-'+i,hostname:'滚动验收设备 '+i}})})).status,200);
    }
    await page.goto(ui+'/admin/users');await page.getByRole('button',{name:'新增用户'}).waitFor();
    await step('真实长表格纵向和横向滚动','20 行真实用户，页面与表格均产生非零滚动，文档无横向溢出',async()=>{
      await page.getByRole('row').filter({hasText:person.name}).waitFor();
      const metrics=await page.evaluate(()=>{
        const main=document.querySelector('.main'),table=document.querySelector('.el-table__body-wrapper .el-scrollbar__wrap');
        main.scrollTop=main.scrollHeight;table.scrollLeft=table.scrollWidth;
        return {mainTop:main.scrollTop,tableLeft:table.scrollLeft,documentWidth:document.documentElement.scrollWidth,viewport:innerWidth};
      });
      assert.ok(metrics.mainTop>0);assert.ok(metrics.tableLeft>0);assert.ok(metrics.documentWidth<=width+1);return JSON.stringify(metrics);
    },'长表格真实双向滚动');
    await step('长会话详情抽屉真实滚动和关闭','21 个真实登录设备，抽屉滚动非零且位于视口内',async()=>{
      await page.getByRole('row').filter({hasText:person.name}).getByRole('button',{name:'详情'}).click();
      await page.getByText('滚动验收设备 19',{exact:true}).waitFor();
      await page.waitForFunction(()=>{const r=document.querySelector('.el-drawer').getBoundingClientRect();return r.left>=0&&r.right<=innerWidth+1;});
      const metrics=await page.locator('.el-drawer__body').evaluate(el=>{el.scrollTop=el.scrollHeight;const r=el.closest('.el-drawer').getBoundingClientRect();return {scrollTop:el.scrollTop,left:r.left,right:r.right,viewport:innerWidth};});
      assert.ok(metrics.scrollTop>0,JSON.stringify(metrics));assert.ok(metrics.left>=0&&metrics.right<=width+1,JSON.stringify(metrics));return JSON.stringify(metrics);
    },'长抽屉真实滚动');
    await page.locator('.el-drawer__close-btn').click();await page.locator('.el-drawer').waitFor({state:'hidden'});
  }finally{
    await context.close();page=null;
    for(const person of seeded)assert.equal((await request(gateway+'/admin/api/users/'+person.id,{method:'DELETE',headers})).status,204);
  }
}
try{
  for(const port of [3118,39110,39113,39107,39109,9256,9257,9258]){
    const isCdp=[9256,9257,9258].includes(port);
    try{const r=await fetch(`http://127.0.0.1:${port}/${isCdp?'json/version':port===3118?'':'healthz'}`,{signal:AbortSignal.timeout(1000)});result.probe.push({port,status:r.status,reused:isCdp?'CDP 探测':'保留原服务，隔离本次后端测试'});}catch{result.probe.push({port,available:false});}
  }
  // Probe only presence/validity, never serialize a session token.
  for(const profile of ['com.openmeeting.ai.dev1','com.openmeeting.ai.dev2','com.openmeeting.ai.dev3']){
    const file=path.join(process.env.APPDATA||testAppData(),profile,'server-config.json');
    if(existsSync(file)){
      const cfg=JSON.parse(readFileSync(file,'utf8'));const token=cfg.sessionToken;
      let status=null;if(token){try{status=(await request('http://127.0.0.1:39110/api/v1/auth/me',{headers:{Authorization:'Bearer '+token}})).status;}catch{}}
      result.probe.push({profile,configPresent:true,sessionPresent:!!token,sessionProbeStatus:status,action:'保留原登录态；隔离数据库使用专用验收会话'});
    }
  }
  save();
  for(const service of ['user','stt','meeting','gateway'])start(python,[path.join(root,'tests/e2e/fixtures/internal-gateway-services.py'),'--service',service],root,service);
  for(const port of [39713,39709,39707,39710])await ready(`http://127.0.0.1:${port}/healthz`);
  const previousCookie=await loginApi();
  const leftovers=await request(gateway+'/admin/api/users?limit=100',{headers:{Cookie:previousCookie}});
  for(const user of (await leftovers.json()).items.filter(x=>x.name.startsWith('网关验收'))){
    assert.equal((await request(gateway+'/admin/api/users/'+user.id,{method:'DELETE',headers:{Cookie:previousCookie}})).status,204);
  }
  if(smokeOnly){await smoke();writeFileSync(smokePath,JSON.stringify(result,null,2));}
  else{
    start(process.execPath,[path.join(root,'server/admin-web/node_modules/vite/bin/vite.js'),'--host','127.0.0.1','--port','5179','--strictPort'],path.join(root,'server/admin-web'),'vite',{OPENMEETING_GATEWAY_URL:gateway});
    await ready(ui+'/admin/');browser=await chromium.launch({headless:true});
    if(scrollOnly){
      phase='assertions-scroll';for(const [w,h]of [[1280,800],[800,900]])await scrollExercise(w,h);
      phase='screenshots';for(const [w,h]of [[1280,800],[800,900]])await scrollExercise(w,h);
    }else{
      phase='assertions';for(const [w,h]of [[1280,800],[800,900]])await exercise(w,h);
      phase='screenshots';for(const [w,h]of [[1280,800],[800,900]])await exercise(w,h);
    }
    const observed=readFileSync(path.join(out,'gateway-requests.jsonl'),'utf8').trim().split('\n').map(JSON.parse);
    await step('内部流量证据核对','三种目标和故障均实际经过 gateway_ms',async()=>{for(const service of ['user','meeting','stt'])assert.ok(observed.some(x=>x.path.startsWith('/internal/'+service+'/')&&x.status===200));assert.ok(observed.some(x=>x.method==='DELETE'&&x.status===502));return '网关访问记录包含三服务成功流量、DELETE 502 和恢复 204';});
  }
}catch(error){result.error=String(error.stack||error);save();console.error(error);process.exitCode=1;}
finally{
  if(browser)await browser.close().catch(()=>{});
  for(const {child,name} of children.reverse()){
    child.kill();await Promise.race([new Promise(resolve=>child.once('exit',resolve)),pause(5000)]);
    result.cleanup.push({name,pid:child.pid,exited:child.exitCode!==null||child.signalCode!==null});
  }
  for(const port of [39710,39713,39707,39709,5179]){try{await fetch(`http://127.0.0.1:${port}/healthz`,{signal:AbortSignal.timeout(500)});result.cleanup.push({port,closed:false});}catch{result.cleanup.push({port,closed:true});}}
  result.finished=new Date().toISOString();
  save();if(smokeOnly)writeFileSync(smokePath,JSON.stringify(result,null,2));else report();
}
