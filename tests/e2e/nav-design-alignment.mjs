import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {spawn,spawnSync} from 'node:child_process';
import {createRequire} from 'node:module';
import {fileURLToPath} from 'node:url';
import {startLayoutBackend,installLayoutBridge} from './fixtures/desktop-layout-backend.mjs';
import {navigateWithinApp} from './app-navigation.mjs';
const root=fileURLToPath(new URL('../../',import.meta.url)),front=path.join(root,'frontend');
const out=path.resolve(root,process.env.NAV_DESIGN_OUTPUT||'.artifacts/nav-design-alignment');fs.mkdirSync(path.join(out,'screenshots'),{recursive:true});
const archive=path.join(root,'docs/testing/archive/侧栏设计对齐');
const read=file=>JSON.parse(fs.readFileSync(path.join(out,file),'utf8'));
function report(){
 const reportBase=process.argv.includes('--archive')?archive:out;
 const repoLink=file=>path.relative(reportBase,path.join(root,file)).replaceAll('\\','/');
 const r=read('results.json'),reviews=fs.existsSync(path.join(out,'visual-reviews.json'))?read('visual-reviews.json'):{},checks=fs.existsSync(path.join(out,'checks.json'))?read('checks.json'):[];
 const assertions=r.rows.filter(s=>s.phase==='assertions'),shots=r.rows.filter(s=>s.screenshot);
 const lines=['# 侧栏设计对齐测试报告','','分级：单组件导航调整，只验证受影响导航与一条会议聊天成功冒烟。生产 Next 页面使用项目已有显式 IPC/HTTP/IM/RTC 夹具；不访问恢复中的真实 IM/RTC，不声称原生或音视频验收。无 in-app browser，使用 Playwright 无头 Chromium。','',
  ...(r.error?['运行错误：'+r.error,'']:[]),
  `页面断言 ${assertions.filter(s=>s.pass).length} 通过、${r.rows.filter(s=>!s.pass).length} 失败；${shots.length} 张最终截图中 ${shots.filter(s=>reviews[s.screenshot]?.pass).length} 张已实际查看。代码检查 ${checks.filter(s=>s.pass).length} 通过。`,
  '', '启动：先探测并保留日常 3118，启动隔离 Next :3158，OPENMEETING_NEXT_DIST_DIR=.next-nav-design / OPENMEETING_E2E_DESKTOP_LAYOUT=1；独立回环 HTTP 夹具。先运行 --smoke 单独验证登录失败/成功，再执行页面；30 分钟累计预算未重置。','',
  '修改：侧栏仅保留首页、会议记录、录制、设置；移除独立消息入口及其未读订阅。会议内聊天、IM Provider、会议信号与提醒仍保留。/chats 兼容路由保留，旧专项通过测试内客户端路由跳转访问，未新增产品入口。','',
  '本轮运行当前工作树源码；既有服务和用户登录态保留。产物目录：'+out+'。','',
  '| 阶段 | 操作 | 预期 | 实际 | 结果 | 截图 |','|---|---|---|---|---|---|',
  ...r.rows.map(s=>`| ${s.phase} | ${s.operation} | ${s.expected} | ${String(s.actual).replaceAll('|','/').replaceAll('\n',' ')} | ${s.pass?'通过':'失败'} | ${s.screenshot?'[截图]('+s.screenshot+')':'—'} |`),'',
  '| 截图 | 视口 | 实际视觉检查 |','|---|---|---|',
  ...shots.map(s=>`| [${path.basename(s.screenshot)}](${s.screenshot}) | ${s.viewport.width}×${s.viewport.height} | ${reviews[s.screenshot]?`${reviews[s.screenshot].pass?'通过':'未通过'}：${reviews[s.screenshot].notes}`:'未实际查看'} |`),'',
  ...(fs.existsSync(path.join(out,'history'))?['首轮截图发现欢迎提示遮挡页面标题，未标记视觉通过；已通过真实关闭按钮关闭提示后重拍。历史证据见 [首轮记录](history/initial/results.json) 和 [视觉检查](history/initial/visual-reviews.json)。','']:[]),
  '静态与契约检查：[checks.json](checks.json)。独立失败冒烟：[smoke.json](smoke.json)。原始逐步结果：[results.json](results.json)。','',
  '清理与探测：'+JSON.stringify(r.cleanup)+'；原服务探测：'+JSON.stringify(r.probe)+'。','',
  '剩余边界：保留的独立 IM 工作台页面不再有主导航入口；完整三端私聊/RTC 专项未重跑。旧专项改用保持应用挂载的客户端路由，已在本轮页面验证跨页后可返回同一会议聊天，不能推断真实 RTC 连续传输。会后通知中心不在本轮新增范围。','',
  '不存在本次新引入的加载/错误/抽屉/表格流程；登录失败与会议聊天侧栏仅作回归冒烟。截图按 1280×800 / 520×760 统一在功能断言后生成，逐张实际查看后才记录视觉通过。','',
  `[E2E 脚本](${repoLink('tests/e2e/nav-design-alignment.mjs')}) · [开发文档](${repoLink('docs/development/nav-design-alignment.md')})`,''];
 fs.writeFileSync(path.join(out,'测试报告.md'),lines.join('\n'));
 if(!process.argv.includes('--archive')){console.log(JSON.stringify({assertionsPassed:assertions.filter(s=>s.pass).length,failed:r.rows.filter(s=>!s.pass).length,screenshots:shots.length,output:out}));return;}
 fs.mkdirSync(archive,{recursive:true});
 for(const name of ['results.json','smoke.json','checks.json','visual-reviews.json','测试报告.md',...fs.readdirSync(out).filter(f=>/^check-.*\.txt$/.test(f))])if(fs.existsSync(path.join(out,name)))fs.copyFileSync(path.join(out,name),path.join(archive,name));
 for(const s of shots){fs.mkdirSync(path.dirname(path.join(archive,s.screenshot)),{recursive:true});fs.copyFileSync(path.join(out,s.screenshot),path.join(archive,s.screenshot));}
 if(fs.existsSync(path.join(out,'history')))fs.cpSync(path.join(out,'history'),path.join(archive,'history'),{recursive:true});
 console.log(JSON.stringify({assertionsPassed:assertions.filter(s=>s.pass).length,failed:r.rows.filter(s=>!s.pass).length,screenshots:shots.length,archive}));
}
if(process.argv.includes('--report')||process.argv.includes('--archive')){report();process.exit(0);}
if(process.argv.includes('--checks')){
 const rows=[];
 for(const [name,args]of [['typescript',['node_modules/typescript/bin/tsc','--noEmit']],['im-provider',['tests/contracts/im-provider-lifecycle.mjs']],['meeting-chat',['tests/contracts/meeting-im-chat.mjs']]]){const r=spawnSync(process.execPath,args,{cwd:front,encoding:'utf8',windowsHide:true});fs.writeFileSync(path.join(out,`check-${name}.txt`),(r.stdout||'')+(r.stderr||''));rows.push({operation:name,expected:'exit 0',actual:r.status,pass:r.status===0});}
 fs.writeFileSync(path.join(out,'checks.json'),JSON.stringify(rows,null,2));console.log(JSON.stringify(rows));process.exit(rows.some(r=>!r.pass)?1:0);
}
const backend=await startLayoutBackend();
async function rpc(session,command,args={}){const r=await fetch(backend.base+'/invoke',{method:'POST',body:JSON.stringify({session,command,args})});return{status:r.status,body:await r.json()};}
async function control(session,patch){await fetch(backend.base+'/control',{method:'POST',body:JSON.stringify({session,patch})});}
if(process.argv.includes('--smoke')){try{const a=await rpc('smoke','auth_login',{phone:'13800138000',password:'WrongPassword123!'});assert.equal(a.status,401);const b=await rpc('smoke','auth_login',{phone:'13800138000',password:'LayoutTest123!'});assert.equal(b.status,200);const rows=[{operation:'independent login failure and recovery fixture',expected:'401 then 200',actual:[a.status,b.status],pass:true,screenshot:null}];fs.writeFileSync(path.join(out,'smoke.json'),JSON.stringify(rows,null,2));console.log(JSON.stringify(rows));}finally{await backend.close();}process.exit(0);}
assert.ok(read('smoke.json').every(r=>r.pass));
const bp=path.join(out,'budget.json'),budget=fs.existsSync(bp)?read('budget.json'):{started:Date.now(),limitMs:1800000};fs.writeFileSync(bp,JSON.stringify(budget));
const r={rows:[],probe:[],cleanup:{}},save=()=>fs.writeFileSync(path.join(out,'results.json'),JSON.stringify(r,null,2));
const require=createRequire(path.join(front,'package.json')),{chromium}=require('playwright');
let browser,next,page,phase='assertions',sequence=0;
const tsconfigPath=path.join(front,'tsconfig.json'),tsconfigBefore=fs.readFileSync(tsconfigPath);
const ui='http://localhost:3158',pause=ms=>new Promise(r=>setTimeout(r,ms));
async function step(operation,expected,action,label){if(Date.now()-budget.started>budget.limitMs)throw Error('30 minute E2E budget exhausted');const row={phase,viewport:page.viewportSize(),operation,expected,actual:null,pass:false,screenshot:null};try{row.actual=await action();row.pass=true;if(phase==='screenshots'&&label){row.screenshot=`screenshots/${String(++sequence).padStart(2,'0')}-${row.viewport.width}x${row.viewport.height}-${label}.png`;const toastClose=page.locator('[data-sonner-toast] [data-close-button]');if(await toastClose.count())await toastClose.first().click();await page.locator('[data-sonner-toast]').waitFor({state:'hidden'});await page.screenshot({path:path.join(out,row.screenshot),animations:'disabled'});}}catch(e){row.pass=false;row.actual=String(e.stack||e);row.screenshot=`screenshots/failure-${Date.now()}.png`;await page.screenshot({path:path.join(out,row.screenshot)}).catch(()=>{});throw e;}finally{r.rows.push(row);save();console.log(JSON.stringify(row));}}
async function designNav(){const nav=page.locator('aside nav');assert.deepEqual(await nav.getByRole('button').allTextContents(),['首页','会议记录','录制','设置']);assert.equal(await nav.getByRole('button',{name:'消息',exact:true}).count(),0);assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth+1),false);return nav;}
async function flow(size){const session=phase+'-'+size.width;await control(session,{loggedIn:false,chatLifecycle:true});const context=await browser.newContext({viewport:size,locale:'zh-CN'});await context.addInitScript(installLayoutBridge,{base:backend.base,session});page=await context.newPage();page.setDefaultTimeout(12000);try{
 await page.goto(ui,{waitUntil:'domcontentloaded'});
 await step('登录错误入口','已有确定性错误展示正常',async()=>{await page.locator('#phone-auth-phone').fill('13800138000');await page.locator('#phone-auth-password').fill('WrongPassword123!');await page.locator('form button[type=submit]').click();await page.getByRole('alert').filter({hasText:'账号或密码不正确'}).waitFor();return'错误提示可见';},'登录错误');
 await step('登录恢复与四项导航','首页/会议记录/录制/设置，消息入口不存在',async()=>{await page.locator('#phone-auth-password').fill('LayoutTest123!');await page.locator('form button[type=submit]').click();await page.getByRole('button',{name:/快速会议.*立即/}).waitFor();await designNav();return'四项导航存在，消息入口不存在';},'首页四项导航');
 for(const [label,route]of [['会议记录','/meetings'],['录制','/record'],['设置','/settings']])await step(label+'导航高亮','点击后路由及当前项正确',async()=>{const nav=await designNav();await nav.getByRole('button',{name:label,exact:true}).click();await page.waitForURL(url=>url.pathname===route);await nav.locator('[aria-current=page]').filter({hasText:label}).waitFor();return route;},label+'导航高亮');
 await step('会议内聊天成功','无消息主导航仍可加入会议并发送消息',async()=>{await page.locator('aside nav').getByRole('button',{name:'首页',exact:true}).click();await page.getByRole('button',{name:/快速会议.*立即/}).click();await page.getByRole('button',{name:'聊天',exact:true}).click();const input=page.getByPlaceholder('发送消息，全体成员可见');await input.fill('侧栏按设计调整后的会议聊天');await input.press('Enter');await page.getByTestId('im-meeting-message').filter({hasText:'侧栏按设计调整后的会议聊天'}).waitFor();return'会议聊天可打开且消息已显示（显式 SDK 夹具）';},'会议聊天成功');
 await step('兼容工作台直接访问及会话返回','不新增侧栏入口，客户端路由不重建会议',async()=>{await page.getByRole('button',{name:'返回首页',exact:true}).click();await navigateWithinApp(page,'/chats');await page.getByRole('heading',{name:'消息',exact:true}).waitFor();await designNav();await page.getByTestId('return-meeting').click();await page.getByTestId('im-meeting-message').filter({hasText:'侧栏按设计调整后的会议聊天'}).waitFor();return'兼容路由可访问，原会议聊天仍在';});
 }finally{await context.close();}}
try{
 for(const port of [3118,3158]){const result=await fetch(`http://127.0.0.1:${port}`,{signal:AbortSignal.timeout(2000)}).then(async q=>{await q.body?.cancel();return{port,listening:true,status:q.status};}).catch(()=>({port,listening:false}));r.probe.push(result);}assert.equal(r.probe.at(-1).listening,false,'Preserve existing port 3158');
 const fd=fs.openSync(path.join(out,'next.log'),'a');next=spawn(process.execPath,[path.join(front,'node_modules/next/dist/bin/next'),'dev','-p','3158'],{cwd:front,env:{...process.env,OPENMEETING_NEXT_DIST_DIR:'.next-nav-design',OPENMEETING_E2E_DESKTOP_LAYOUT:'1',NEXT_PUBLIC_LIVE_MEETING_DATA_SOURCE:'real'},windowsHide:true,stdio:['ignore',fd,fd]});fs.closeSync(fd);
 const end=Date.now()+90000;while(!await fetch(ui).then(async q=>{await q.body?.cancel();return q.ok;}).catch(()=>false)){if(Date.now()>end)throw Error('Next startup timeout');await pause(500);}
 browser=await chromium.launch({headless:true});for(const mode of ['assertions','screenshots']){phase=mode;for(const size of [{width:1280,height:800},{width:520,height:760}])await flow(size);}
}catch(e){r.error=String(e.stack||e);process.exitCode=1;console.error(e);}
finally{await browser?.close();r.cleanup.browserClosed=true;if(next){const stopped=spawnSync('taskkill.exe',['/PID',String(next.pid),'/T','/F'],{windowsHide:true});r.cleanup.nextStopped=stopped.status===0;}await backend.close();r.cleanup.fixtureClosed=true;r.cleanup.nextPortClosed=await fetch(ui,{signal:AbortSignal.timeout(1000)}).then(()=>false).catch(()=>true);if(!next||r.cleanup.nextPortClosed){fs.writeFileSync(tsconfigPath,tsconfigBefore);r.cleanup.tsconfigRestored=fs.readFileSync(tsconfigPath).equals(tsconfigBefore);}r.cleanup.daily3118Listening=await fetch('http://127.0.0.1:3118/',{signal:AbortSignal.timeout(2000)}).then(async q=>{await q.body?.cancel();return true;}).catch(()=>false);budget.usedMs=Date.now()-budget.started;fs.writeFileSync(bp,JSON.stringify(budget,null,2));save();report();}
