import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
import {execFileSync,spawn,spawnSync} from 'node:child_process';
import {existsSync,mkdirSync,readFileSync,writeFileSync,openSync,closeSync,copyFileSync,cpSync} from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const root=fileURLToPath(new URL('../../',import.meta.url)),out=path.join(root,'.artifacts/unified-egress');
mkdirSync(path.join(out,'screenshots'),{recursive:true});
const gateway='http://127.0.0.1:39710',vendor='http://127.0.0.1:39880',ui='http://127.0.0.1:5179';
const resultPath=path.join(out,'results.json'),smokePath=path.join(out,'smoke.json');
const smokeOnly=process.argv.includes('--smoke');
const env={...process.env,INTERNAL_SERVICE_TOKEN:'egress-fixture-internal',OPENMEETING_ADMIN_PASSWORD:'EgressTest123!',OPENMEETING_SECRET_KEY:'egress-isolated-secret',POSTGRES_PASSWORD:'egress-db-test'};
const composeArgs=['compose','-p','openmeeting-egress-acceptance','-f','server/docker-compose.yml','-f','server/docker-compose.egress-test.yml'];
const docker=args=>execFileSync('docker',args,{cwd:root,env,encoding:'utf8',windowsHide:true,maxBuffer:16*1024*1024}).trim();
const compose=args=>docker([...composeArgs,...args]);
let result={started:new Date().toISOString(),steps:[],probe:[],cleanup:[],startup:'独立 Compose 项目 openmeeting-egress-acceptance，三个独立数据库、四个生产服务源码容器和仅在 edge 网络上的供应商夹具；网关 :39710，出站 :39711，Vite :5179。'};
let browser,page,vite,phase='fixture-smoke',viewport='服务',sequence=0;
const save=()=>writeFileSync(smokeOnly?smokePath:resultPath,JSON.stringify(result,null,2));
const pause=ms=>new Promise(resolve=>setTimeout(resolve,ms));
async function request(url,options={}){return fetch(url,{...options,headers:{Connection:'close',...options.headers},signal:AbortSignal.timeout(15000)});}
async function control(fault='normal'){const r=await request(gateway+'/__test__/control',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({proxy_fault:fault})});assert.equal(r.status,200);}
async function vendorControl(patch){const r=await request(vendor+'/control',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(patch)});assert.equal(r.status,200);}
async function ready(url){for(let i=0;i<80;i++){try{if((await request(url)).ok)return;}catch{}await pause(500);}throw Error('Readiness failed: '+url);}
async function step(operation,expected,action,shot){
  const item={phase,viewport,operation,expected,actual:'',pass:false,screenshot:null};result.steps.push(item);
  try{
    if(result.budgetStarted&&Date.now()-result.budgetStarted>30*60000)throw Error('30 分钟 E2E 调试预算用完，须降级 API 验证');
    if(phase==='screenshots'&&page)await page.locator('.el-message').last().waitFor({state:'hidden',timeout:6000});
    item.actual=await action()||'符合预期';
    if(phase==='screenshots'&&shot){await pause(400);item.screenshot=`screenshots/${String(++sequence).padStart(2,'0')}-${viewport}-${shot}.png`;await page.screenshot({path:path.join(out,item.screenshot),animations:'disabled'});}
    item.pass=true;
  }catch(error){item.actual=String(error.stack||error);if(page){item.screenshot=`screenshots/failure-${Date.now()}-${viewport}.png`;await page.screenshot({path:path.join(out,item.screenshot)}).catch(()=>{});}throw error;}
  finally{save();console.log(JSON.stringify(item));}
}
async function loginApi(){const r=await request(gateway+'/admin/api/login',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({password:'EgressTest123!'})});assert.equal(r.status,200);return r.headers.get('set-cookie').split(';')[0];}
async function smoke(){
  const inspect=JSON.parse(docker(['inspect','openmeeting-egress-acceptance-vendor-1']))[0];
  const ip=inspect.NetworkSettings.Networks['openmeeting-egress-acceptance_edge'].IPAddress;
  for(const service of ['user','meeting','stt']){
    const run=spawnSync('docker',['exec',`openmeeting-egress-acceptance-${service}_ms-1`,'python','/workspace/tests/e2e/fixtures/egress-sdk-checks.py','--service',service,'--vendor-ip',ip],{cwd:root,encoding:'utf8',windowsHide:true});
    writeFileSync(path.join(out,`sdk-${service}.log`),run.stdout+run.stderr);
    const rows=run.stdout.split('\n').filter(x=>x.startsWith('{')).map(x=>{try{return JSON.parse(x);}catch{return null;}}).filter(x=>x?.operation);
    for(const row of rows){result.steps.push({phase:'real-sdk',viewport:'容器',...row});console.log(JSON.stringify(row));}
    assert.equal(run.status,0,service+' SDK 夹具冒烟失败，查看独立日志');save();
  }
  const cookie=await loginApi(),headers={'Cookie':cookie,'Content-Type':'application/json'};
  let id;
  await step('真实提供方配置和成功路径','生产 API 保存配置；经代理调用 HTTPS 供应商成功',async()=>{
    const created=await request(gateway+'/admin/api/llm/providers',{method:'POST',headers,body:JSON.stringify({name:'出站夹具冒烟',base_url:'https://vendor:4081/v1',model:'gateway-fixture-model',api_key:'fixture-key'})});assert.equal(created.status,200);id=(await created.json()).id;
    const r=await request(gateway+`/admin/api/llm/providers/${id}/test`,{method:'POST',headers});assert.equal(r.status,200);assert.equal((await r.json()).ok,true);return '真实配置和业务请求成功';
  });
  for(const [fault,pattern]of [['deny',/403/],['down',/connect|connection/i]]){
    await control(fault);await step('独立冒烟 '+fault+' 失败路径','确定性触发出站失败，业务不能直连回退',async()=>{
      const r=await request(gateway+`/admin/api/llm/providers/${id}/test`,{method:'POST',headers});const data=await r.json();assert.equal(data.ok,false);assert.match(data.error,pattern);return 'ok=false；没有直连回退';
    });await control();
  }
  await vendorControl({fail:true});
  await step('独立冒烟供应商 503','生产业务收到上游 503',async()=>{const data=await(await request(gateway+`/admin/api/llm/providers/${id}/test`,{method:'POST',headers})).json();assert.equal(data.ok,false);assert.match(data.error,/503/);return '供应商 503 被业务识别';});
  await vendorControl({fail:false,delay:1});
  await step('独立冒烟加载和恢复','延迟至少 1 秒，恢复正常响应',async()=>{const t=Date.now();const data=await(await request(gateway+`/admin/api/llm/providers/${id}/test`,{method:'POST',headers})).json();assert.equal(data.ok,true);assert.ok(Date.now()-t>=900);return '延迟与恢复成功均稳定';});
  await vendorControl({delay:0});
  assert.equal((await request(gateway+`/admin/api/llm/providers/${id}`,{method:'DELETE',headers})).status,204);
}
async function exercise(width,height){
  viewport=`${width}x${height}`;
  const context=await browser.newContext({viewport:{width,height},locale:'zh-CN'});await context.tracing.start({screenshots:true,snapshots:true});
  page=await context.newPage();page.setDefaultTimeout(10000);
  const name='统一出站验收-'+phase+'-'+width+'-长名称用于验证表格截断与响应式';let providerId;
  const row=()=>page.getByRole('row').filter({hasText:name});
  const dialog=()=>page.getByRole('dialog').filter({has:page.getByText('连接测试结果',{exact:true})});
  const closeResult=async()=>{await dialog().getByRole('button',{name:'确定',exact:true}).click();await dialog().waitFor({state:'hidden'});};
  const testResponse=()=>page.waitForResponse(r=>r.url().endsWith('/providers/'+providerId+'/test')&&r.request().method()==='POST');
  try{
    await step('权限态与登录入口','未登录访问模型管理时跳转登录',async()=>{await page.goto(ui+'/admin/llm');await page.getByPlaceholder('管理员密码').waitFor();assert.match(page.url(),/login/);return '真实会话鉴权要求登录';},'权限态');
    await step('真实登录与空列表','建立测试会话，空列表可见',async()=>{await page.getByPlaceholder('管理员密码').fill('EgressTest123!');await page.getByRole('button',{name:'登录',exact:true}).click();await page.getByText('尚未添加大模型提供方',{exact:true}).waitFor();return '已登录，真实数据库无提供方';},'登录空态');
    await step('打开提供方表单并经网关获取模型列表','真实外部请求返回模型选项',async()=>{
      await page.getByRole('button',{name:'添加提供方',exact:true}).click();const d=page.getByRole('dialog');
      await d.getByPlaceholder('如：阿里云百炼').fill(name);await d.getByPlaceholder('https://.../v1').fill('https://vendor:4081/v1');await d.getByPlaceholder('请输入 API Key').fill('fixture-key');
      await d.getByRole('button',{name:'获取模型列表',exact:true}).click();await page.getByText('获取到 1 个模型',{exact:true}).waitFor();
      await d.locator('.model-select').click();await page.getByRole('option',{name:'gateway-fixture-model',exact:true}).click();return '真实 meeting_ms → gateway_ms → TLS 供应商返回模型选项';
    },'表单模型列表');
    await step('保存提供方','配置写入真实数据库并显示表格',async()=>{const response=page.waitForResponse(r=>r.url().endsWith('/llm/providers')&&r.request().method()==='POST');await page.getByRole('dialog').getByRole('button',{name:'保存',exact:true}).click();const r=await response;assert.equal(r.status(),200);providerId=(await r.json()).id;await row().waitFor();return '配置已保存，名称在表格内省略显示';},'保存成功');
    await step('出站请求加载态','等待供应商期间按钮显示 loading',async()=>{await vendorControl({delay:2});await row().getByRole('button',{name:'测试连接',exact:true}).click();await row().locator('button.is-loading').waitFor();return '真实异步网络请求处理中';},'加载态');
    await step('连接成功与长文本滚动','成功结果弹窗打开，长回复可滚动',async()=>{await dialog().getByText('连接成功',{exact:true}).waitFor();await vendorControl({delay:0});const textarea=dialog().locator('textarea');await textarea.waitFor();const position=await textarea.evaluate(el=>{el.scrollTop=el.scrollHeight;return el.scrollTop;});assert.ok(position>0);return '连接成功；回复文本实际滚动 '+position+'px';},'成功长文本滚动');
    await closeResult();
    await step('网关目标拒绝','403 失败明确展示，不能绕过网关',async()=>{await control('deny');const response=testResponse();await row().getByRole('button',{name:'测试连接',exact:true}).click();const data=await(await response).json();assert.equal(data.ok,false);assert.match(data.error,/403/);await dialog().getByText('连接失败',{exact:true}).waitFor();return '网关拒绝目标后显示连接失败及 403 原因';},'目标拒绝');
    await closeResult();await control();
    await step('出站代理断开','代理不可用时失败，不进行直连回退',async()=>{await control('down');const response=testResponse();await row().getByRole('button',{name:'测试连接',exact:true}).click();const data=await(await response).json();assert.equal(data.ok,false);assert.match(data.error,/connect|connection/i);await dialog().getByText('连接失败',{exact:true}).waitFor();return '代理断开被真实业务识别，错误弹窗可见';},'代理断开');
    await closeResult();await control();
    await step('供应商错误','上游 503 被展示为连接失败',async()=>{await vendorControl({fail:true});const response=testResponse();await row().getByRole('button',{name:'测试连接',exact:true}).click();const data=await(await response).json();assert.equal(data.ok,false);assert.match(data.error,/503/);await dialog().getByText('连接失败',{exact:true}).waitFor();return '上游 503 原因可见';},'供应商错误');
    await closeResult();await vendorControl({fail:false});
    await step('恢复后真实重试成功','恢复后无需改配置即可成功',async()=>{const response=testResponse();await row().getByRole('button',{name:'测试连接',exact:true}).click();assert.equal((await(await response).json()).ok,true);await dialog().getByText('连接成功',{exact:true}).waitFor();return '出站代理和供应商恢复后重试通过';},'恢复成功');
    await closeResult();
    await step('编辑弹窗与模型空结果','被拒绝时模型列表为空，保留原配置',async()=>{await row().getByRole('button',{name:'编辑',exact:true}).click();await control('deny');await page.getByRole('dialog').getByRole('button',{name:'获取模型列表',exact:true}).click();await page.getByText('未获取到模型列表（接口可能不支持 /models），请直接输入模型名',{exact:true}).waitFor();return '空结果提示可见，已保存配置保留';},'模型空结果');
    await control();await page.getByRole('dialog').getByRole('button',{name:'取消',exact:true}).click();await page.getByRole('dialog').waitFor({state:'hidden'});
    await step('关闭弹窗与响应式表格','没有残留遮罩，表格可横向滚动，页面无横向溢出',async()=>{const metrics=await page.evaluate(()=>{const wrap=document.querySelector('.el-table__body-wrapper .el-scrollbar__wrap');wrap.scrollLeft=wrap.scrollWidth;return {left:wrap.scrollLeft,documentWidth:document.documentElement.scrollWidth,width:innerWidth};});assert.ok(metrics.left>0);assert.ok(metrics.documentWidth<=width+1);return JSON.stringify(metrics);},'表格滚动与弹窗关闭');
  }finally{
    await control().catch(()=>{});await vendorControl({fail:false,delay:0}).catch(()=>{});
    if(providerId)await page.request.delete(gateway+'/admin/api/llm/providers/'+providerId).catch(()=>{});
    await context.tracing.stop({path:path.join(out,`${phase}-${viewport}-${Date.now()}.zip`)}).catch(()=>{});await context.close();page=null;
  }
}
function report(){
  const r=JSON.parse(readFileSync(resultPath,'utf8')),smoke=JSON.parse(readFileSync(smokePath,'utf8'));
  const reviews=existsSync(path.join(out,'visual-reviews.json'))?JSON.parse(readFileSync(path.join(out,'visual-reviews.json'),'utf8')):{};
  const checks=existsSync(path.join(out,'checks.json'))?JSON.parse(readFileSync(path.join(out,'checks.json'),'utf8')):{};
  const setup=existsSync(path.join(out,'setup-history.json'))?JSON.parse(readFileSync(path.join(out,'setup-history.json'),'utf8')):[];
  const clean=s=>String(s).replaceAll('|','/').replaceAll('\n',' ');
  const lines=['# 统一出入网关测试报告','','本次为全服务出站与网络隔离变更，采用完整真实管理端 E2E。运行真实 Docker 网络、三个独立 PostgreSQL、四个生产 FastAPI 服务源码、真实 SDK/HTTP/TLS/WSS 和 Vue/Vite 页面；外部平台由明确的边缘网络供应商夹具替代，不代表真实云端账号、短信投递、模型推理或模型权重下载验收。TLS 使用隔离 CA 并保持校验，未关闭证书验证。','','先独立运行 SDK/网络与故障冒烟，再执行双视口断言，全部通过后统一采集截图。无 in-app browser，采用 Playwright 无头 Chromium；桌面 1280×800，窄窗口 800×900。逐张实际查看后才记录视觉结论。本轮受影响页面涉及表格与表单/结果弹窗，抽屉未修改。','',`开始：${r.started}；结束：${r.finished||'尚未结束'}；E2E 累计 30 分钟预算起点：${new Date(r.budgetStarted).toISOString()}。`,'',`启动方式：${r.startup}`,'',`最终页面步骤：通过 ${r.steps.filter(x=>x.pass).length}，失败 ${r.steps.filter(x=>!x.pass).length}。独立 SDK/网络/故障冒烟通过 ${smoke.steps.filter(x=>x.pass).length}，失败 ${smoke.steps.filter(x=>!x.pass).length}。`,'','## 已有服务与登录态探测','',...r.probe.map(x=>'- '+JSON.stringify(x)),'','## 逐步结果','','| 阶段/视口 | 操作 | 预期 | 实际 | 结果 | 截图 |','| --- | --- | --- | --- | --- | --- |'];
  const totals=checks.backend_totals;
  lines.splice(10,0,`后端回归：${totals?`${totals.tests} 项，失败 ${totals.failures}，初始化错误 ${totals.errors}，跳过 ${totals.skipped}`:'尚未汇总'}。Compose 配置检查 ${checks.topology?.compose_configs??'待运行'} 组，实际独立数据库 ${checks.topology?.independent_database_instances??'待运行'} 个。最终运行错误：${r.error||smoke.error||'无'}。`,'',
    '重现命令：`python tests/e2e/fixtures/egress-cert.py` → `node tests/e2e/unified-egress.mjs --smoke` → `node tests/e2e/unified-egress.mjs`。本轮复用现有依赖镜像并挂载 worktree 当前源码，未测试重新构建的生产镜像或 GPU 镜像。','');
  for(const s of [...smoke.steps,...r.steps])lines.push(`| ${s.phase}/${s.viewport} | ${clean(s.operation)} | ${clean(s.expected)} | ${clean(s.actual)} | ${s.pass?'通过':'失败'} | ${s.screenshot?`[截图](${s.screenshot})`:'—'} |`);
  lines.push('','## 逐张视觉检查','','| 截图 | 实际查看结论 |','| --- | --- |');
  for(const s of r.steps.filter(x=>x.screenshot))lines.push(`| [${s.screenshot}](${s.screenshot}) | ${clean(reviews[s.screenshot]||'待实际查看，未标记视觉通过')} |`);
  lines.push('','## 检查与历史失败','','```json',JSON.stringify(checks,null,2),'```');
  for(const h of setup)lines.push(`- ${h.phase}：${clean(h.error)}${h.evidence?`；[证据](${h.evidence})`:''}`);
  for(const h of r.history||[]){lines.push(`- 历史运行错误：${clean(h.error)}`);for(const s of h.steps.filter(x=>!x.pass))lines.push(`- 历史失败：${s.operation}；${clean(s.actual)}${s.screenshot?`；[截图](${s.screenshot})`:''}`);}
  lines.push('','## 服务关闭与保留','','```json',JSON.stringify(r.cleanup,null,2),'```','','## 剩余风险','','- 真实 DeepRespond/OSS/短信云端、真实语音模型与权重仓库的业务协议及容量仍需部署环境专项验收；本轮已验证对应生产适配器/SDK 的代理传输，未把供应商夹具当作真实平台。','- CONNECT 为 TLS 透传，网关控制目标、端口、认证、连接数和超时，不解密供应商请求内容；URL 签名、Host 和远端证书校验保留。','- 网关成为统一出站依赖；生产负载、HA、完整大模型/模型 CDN 白名单须按部署维护。','- 原有业务服务、数据库和登录态均保留；本轮未部署到原栈，也未迁移其数据。','','证据：[结构化步骤](results.json)、[独立冒烟](smoke.json)、[供应商收包记录](vendor-requests.jsonl)、[拓扑检查](topology.json)、[网关日志](gateway.log)、[视觉检查](visual-reviews.json)。','');
  writeFileSync(path.join(out,'测试报告.md'),lines.join('\n'));
}
function archive(){
  const r=JSON.parse(readFileSync(resultPath,'utf8')),smoke=JSON.parse(readFileSync(smokePath,'utf8')),reviews=JSON.parse(readFileSync(path.join(out,'visual-reviews.json'),'utf8'));
  assert.ok(!r.error&&!smoke.error&&[...r.steps,...smoke.steps].every(x=>x.pass),'Archive only a completed successful final run; retain failed history separately');
  assert.ok(r.cleanup.every(x=>x.closed),'Own services must be closed');
  assert.ok(r.steps.filter(x=>x.screenshot).every(x=>reviews[x.screenshot]),'Review each screenshot before archiving');
  report();
  const destination=path.join(root,'docs/testing/archive/统一出入网关');mkdirSync(destination,{recursive:true});
  const files=['测试报告.md','results.json','smoke.json','smoke-failed-keepalive.json','visual-reviews.json','setup-history.json','checks.json','topology.json','contracts.xml','gateway.xml','gateway-failed-db-config.xml','user.xml','meeting.xml','stt.xml','gateway.log','user_ms.log','meeting_ms.log','stt_ms.log','vendor.log','internal-requests.jsonl','vendor-requests.jsonl','sdk-user.log','sdk-meeting.log','sdk-stt.log','vite.log','admin-build.log','ui-budget.json'];
  for(const file of files)if(existsSync(path.join(out,file))){
    const source=path.join(out,file),target=path.join(destination,file);
    if(file.endsWith('.xml'))writeFileSync(target,readFileSync(source,'utf8').replace(/[ \t]+$/gm,''));
    else copyFileSync(source,target);
  }
  cpSync(path.join(out,'screenshots'),path.join(destination,'screenshots'),{recursive:true});
  for(const file of ['tests/e2e/unified-egress.mjs','tests/e2e/internal-gateway-topology.mjs','tests/e2e/fixtures/egress-cert.py','tests/e2e/fixtures/egress-services.py','tests/e2e/fixtures/egress-vendor.py','tests/e2e/fixtures/egress-sdk-checks.py','server/tests/test_egress_proxy.py','server/docker-compose.egress-test.yml']){
    const target=path.join(destination,'scripts',file);mkdirSync(path.dirname(target),{recursive:true});copyFileSync(path.join(root,file),target);
  }
  console.log(JSON.stringify({archive:destination,screenshots:24,privateKeysAndTracesExcluded:true}));
}
if(process.argv.includes('--archive')){archive();process.exit(0);}
if(process.argv.includes('--report')){report();process.exit(0);}
if(!smokeOnly){
  assert.ok(existsSync(smokePath),'Run --smoke successfully before pages');
  const prerequisite=JSON.parse(readFileSync(smokePath,'utf8'));
  assert.ok(!prerequisite.error&&prerequisite.steps.length>=22&&prerequisite.steps.every(x=>x.pass),'Run the complete --smoke successfully before pages');
  const old=existsSync(resultPath)?JSON.parse(readFileSync(resultPath,'utf8')):null;
  const budget=path.join(out,'ui-budget.json');result.budgetStarted=existsSync(budget)?JSON.parse(readFileSync(budget,'utf8')).started:Date.now();writeFileSync(budget,JSON.stringify({started:result.budgetStarted}));
  result.history=[...(old?.history||[]),...(old?.error?[{started:old.started,steps:old.steps,error:old.error}]:[])];
}
try{
  for(const port of [3118,39110,39113,39107,39109,9256,9257,9258]){try{const cdp=[9256,9257,9258].includes(port);const r=await fetch(`http://127.0.0.1:${port}/${cdp?'json/version':port===3118?'':'healthz'}`,{signal:AbortSignal.timeout(700)});result.probe.push({port,status:r.status,action:'保留现有服务'});}catch{result.probe.push({port,available:false});}}
  for(const profile of ['com.openmeeting.ai.dev1','com.openmeeting.ai.dev2','com.openmeeting.ai.dev3']){const file=path.join(process.env.APPDATA||'',profile,'server-config.json');if(existsSync(file)){const cfg=JSON.parse(readFileSync(file,'utf8'));const status=cfg.sessionToken?(await request('http://127.0.0.1:39110/api/v1/auth/me',{headers:{Authorization:'Bearer '+cfg.sessionToken}})).status:null;result.probe.push({profile,sessionPresent:!!cfg.sessionToken,status,action:'保留原会话，隔离数据库使用专用管理员会话'});}}
  compose(['up','-d','--no-build']);await ready(gateway+'/healthz');await ready(vendor+'/healthz');
  await control();await vendorControl({fail:false,delay:0});
  const cookie=await loginApi();const list=await(await request(gateway+'/admin/api/llm/providers',{headers:{Cookie:cookie}})).json();
  for(const p of list.filter(x=>x.name.startsWith('统一出站验收-')||x.name==='出站夹具冒烟'))assert.equal((await request(gateway+'/admin/api/llm/providers/'+p.id,{method:'DELETE',headers:{Cookie:cookie}})).status,204);
  if(smokeOnly)await smoke();
  else{
    const require=createRequire(path.join(process.env.OPENMEETING_TEST_DEPENDENCIES||root,'frontend/package.json')),{chromium}=require('playwright');
    const log=openSync(path.join(out,'vite.log'),'a');vite=spawn(process.execPath,[path.join(root,'server/admin-web/node_modules/vite/bin/vite.js'),'--host','127.0.0.1','--port','5179','--strictPort'],{cwd:path.join(root,'server/admin-web'),env:{...process.env,OPENMEETING_GATEWAY_URL:gateway},stdio:['ignore',log,log],windowsHide:true});closeSync(log);await ready(ui+'/admin/');
    browser=await chromium.launch({headless:true});phase='assertions';for(const size of [[1280,800],[800,900]])await exercise(...size);
    phase='screenshots';for(const size of [[1280,800],[800,900]])await exercise(...size);
    await step('供应商记录与代理凭据隔离','真实请求已到达且未泄露 Proxy-Authorization',async()=>{const records=readFileSync(path.join(out,'vendor-requests.jsonl'),'utf8').trim().split('\n').map(JSON.parse);assert.ok(records.some(x=>x.path.endsWith('/chat/completions')));assert.ok(records.every(x=>!x.proxy_header_leaked));return '全部供应商收包记录没有代理凭据';});
  }
}catch(error){result.error=String(error.stack||error);console.error(error);process.exitCode=1;}
finally{
  if(browser)await browser.close().catch(()=>{});
  if(vite){vite.kill();await Promise.race([new Promise(r=>vite.once('exit',r)),pause(3000)]);result.cleanup.push({name:'vite',pid:vite.pid,closed:vite.exitCode!==null||vite.signalCode!==null});}
  for(const service of ['gateway_ms','user_ms','meeting_ms','stt_ms','vendor']){try{const log=spawnSync('docker',['logs',`openmeeting-egress-acceptance-${service}-1`],{encoding:'utf8',windowsHide:true,maxBuffer:16*1024*1024});writeFileSync(path.join(out,service==='gateway_ms'?'gateway.log':service+'.log'),log.stdout+log.stderr);}catch{}}
  try{compose(['stop']);const states=JSON.parse(docker(['inspect',...['gateway_ms','user_ms','meeting_ms','stt_ms','vendor','user-postgres','meeting-postgres','stt-postgres'].map(x=>'openmeeting-egress-acceptance-'+x+'-1')]));result.cleanup.push(...states.map(x=>({name:x.Name,running:x.State.Running,closed:!x.State.Running,volumesPreserved:true})));}catch(error){result.cleanup.push({closed:false,error:String(error)});process.exitCode=1;}
  result.finished=new Date().toISOString();save();if(!smokeOnly)report();
}
