import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
import {fileURLToPath} from 'node:url';
import {mkdirSync,readFileSync,writeFileSync,existsSync,unlinkSync,readdirSync} from 'node:fs';
import {spawn} from 'node:child_process';
import path from 'node:path';

const root=fileURLToPath(new URL('../../',import.meta.url)),frontend=path.join(root,'frontend');
const require=createRequire(path.join(frontend,'package.json'));
const out=path.resolve(process.env.CAMERA_TEST_OUTPUT||path.join(root,'.artifacts/camera-preview'));
mkdirSync(path.join(out,'screenshots'),{recursive:true});
const smoke=process.argv.includes('--smoke'),reportOnly=process.argv.includes('--report');
function report(){
 const data=JSON.parse(readFileSync(path.join(out,'results.json'),'utf8'));
 const visual=existsSync(path.join(out,'visual-review.json'))?JSON.parse(readFileSync(path.join(out,'visual-review.json'),'utf8')):{};
 const checks=existsSync(path.join(out,'checks.json'))?JSON.parse(readFileSync(path.join(out,'checks.json'),'utf8').replace(/^\uFEFF/,'')):[];
 const attempts=existsSync(path.join(out,'attempts'))?readdirSync(path.join(out,'attempts'),{withFileTypes:true}).filter(x=>x.isDirectory()).map(x=>{
  const result=JSON.parse(readFileSync(path.join(out,'attempts',x.name,'results.json'),'utf8'));
  const failure=result.results.find(row=>!row.passed)?.actual;
  const supplemental=path.join(out,'attempts',x.name,'failure.json');
  return {name:x.name,reason:failure?.split('\n')[0]||(existsSync(supplemental)?JSON.parse(readFileSync(supplemental,'utf8')).reason:'见截图及步骤日志')};
 }):[];
 const pass=data.results.filter(x=>x.passed).length,fail=data.results.filter(x=>!x.passed).length;
 const lines=['# 摄像头重复开启测试报告','','分级：完整会议界面回归。涉及状态同步与 SDK 轨道生命周期，执行完整入会、反复开关、权限拒绝、恢复、聚焦和成员弹窗路径。业务 API、RTC 传输和摄像头输入由确定性夹具替代；使用生产 RoomProvider、RoomScreen、ImChannelMediaClient、SDK 与 MediaElement。此结果不等同于原生双端或实体摄像头验收。',
 '',`启动：${data.startup}。探测并保留现有 3118 前端、39110 后端；夹具未调用其业务 API。既有原生客户端没有开放 CDP，未操作现有会议或账号。`,
 '',`E2E 调试预算：30 分钟；本轮耗时 ${data.elapsedSeconds} 秒。断言通过 ${pass}，失败 ${fail}。夹具先独立执行 --smoke，再执行本轮；记录见 smoke-results.json。`,
 '',`服务关闭：${data.cleanup}。`, '', '## 其他检查','',...checks.map(x=>`- ${x.name}：退出码 ${x.exitCode}；${x.exitCode===0?`${x.passedCount} 项通过`:'失败，见日志'}。`),
 '', '## 调试失败保留记录','',...attempts.map(x=>`- [${x.name}](attempts/${x.name}/results.json)：${x.reason}。早期失败未计为通过；截图保存在同目录。`),
 '', '## 逐步结果','','| 操作 | 预期 | 实际 | 通过 | 截图 |','|---|---|---|---|---|',
 ...data.results.map(x=>`| ${x.operation} | ${x.expected} | ${String(x.actual).replaceAll('|','/')} | ${x.passed?'通过':'失败'} | ${x.screenshot?`[截图](${x.screenshot})`:'—'} |`),
 '', '## 截图人工视觉检查','','使用 Playwright 无头 Chromium 截图，桌面 1280×800，窄视口 600×900。功能断言全部通过后统一采集；每张须实际打开后登记。', '',
 ...data.screenshots.map(x=>`- [${x.path}](${x.path})（${x.viewport}）：${visual[x.path]||'待实际查看，不标记视觉通过'}`),
 '', '## 边界与证据','','- 合成 canvas 摄像头，不占用真实摄像头；缺失信令回传与同一 publication 下更换 native track 为确定性入口。',
 '- 权限失败由 NotAllowedError 确定触发，确认 self、成员列表、提示及预览回退一致；随后正常开启恢复。',
 '- 本轮不涉及表格、附件上传或屏幕共享，不将这些路径列为通过。真实网络、实体摄像头、原生双端传输仍待验证。',
 '- [结构化结果](results.json)、[运行日志](steps.jsonl)、[视觉检查记录](visual-review.json)、[夹具冒烟](smoke-results.json)。',
 existsSync(path.join(out,'before-fix.log'))?'- 修复前 SDK 夹具失败证据见 [before-fix.log](before-fix.log)；相关契约与类型检查见 [checks.log](checks.log)。':'- 本次评审未重新执行修复前对照；相关契约、构建与类型检查见 [checks.log](checks.log)。',''];
 writeFileSync(path.join(out,'测试报告.md'),lines.join('\n'));
}
if(reportOnly){report();process.exit(0);}
writeFileSync(path.join(out,smoke?'smoke-steps.jsonl':'steps.jsonl'),'');
const started=Date.now(),results=[],screenshots=[];
 const data={startup:`工作区 ${root}；node 调用 Next startServer(dev:true, port:3148)，OPENMEETING_NEXT_DIST_DIR=.next-camera-e2e；静态夹具加载生产会议组件构建`,results,screenshots,cleanup:'待关闭',elapsedSeconds:0};
 const save=()=>writeFileSync(path.join(out,smoke?'smoke-results.json':'results.json'),JSON.stringify(data,null,2));
async function step(operation,expected,fn){
 const row={operation,expected,actual:'',passed:false,screenshot:null};
 try{row.actual=await fn()||'断言全部通过';row.passed=true;}
 catch(e){row.actual=String(e.stack||e);throw e;}
 finally{const size=/^采集 (\d+)×(\d+)/.exec(operation);if(size)row.screenshot=screenshots.find(x=>x.viewport===`${size[1]}×${size[2]}`)?.path??null;results.push(row);const line=JSON.stringify(row);console.log(line);writeFileSync(path.join(out,smoke?'smoke-steps.jsonl':'steps.jsonl'),line+'\n',{flag:'a'});save();}
}
const {build}=require('esbuild'),{chromium}=require('playwright');
const fixture=path.join(root,'tests/e2e/fixtures/camera-preview.jsx');
const aliases=/^(next\/navigation|@\/i18n|@\/contexts\/(ServerContext|IMContext)|@\/components\/live-meeting\/JoinDialog|@\/services\/live-meeting)$/;
const bundle=await build({entryPoints:[fixture],absWorkingDir:frontend,tsconfig:path.join(frontend,'tsconfig.json'),bundle:true,write:false,format:'iife',platform:'browser',jsx:'automatic',define:{'process.env':'{}'},plugins:[{name:'camera-fixture-boundaries',setup(b){
 b.onResolve({filter:aliases},()=>({path:fixture}));
 b.onResolve({filter:/^[^./]/},args=>{if(args.path.startsWith('@/'))return;try{return{path:args.path==='@deeprespond/im-web'?path.join(frontend,'node_modules/@deeprespond/im-web/dist/index.js'):require.resolve(args.path)};}catch{return;}});
}}]});
const postcss=require('postcss'),tailwind=require('tailwindcss'),config=require(path.join(frontend,'tailwind.config.js'));
const css=await postcss([tailwind({...config,content:[path.join(frontend,'src/components/live-meeting/room/**/*.{tsx,ts}'),path.join(frontend,'src/components/ui/**/*.{tsx,ts}')]} )]).process(readFileSync(path.join(frontend,'src/app/globals.css'),'utf8'),{from:undefined});
const files=[path.join(frontend,'public/camera-preview-fixture.html'),path.join(frontend,'public/camera-preview-fixture.js')];
const tsconfigPath=path.join(frontend,'tsconfig.json'),tsconfigBefore=readFileSync(tsconfigPath,'utf8');
for(const file of files)assert.ok(!existsSync(file),'Refuse to overwrite '+file);
writeFileSync(files[0],`<!doctype html><html class="dark" lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><style>${css.css}</style></head><body><div id="root"></div><script src="/camera-preview-fixture.js"></script></body></html>`);
writeFileSync(files[1],bundle.outputFiles[0].text);
let server,browser,page;
const url='http://127.0.0.1:3148/camera-preview-fixture.html';
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
async function wait(fn,timeout=15000){const end=Date.now()+timeout;while(Date.now()<end){if(await fn())return;await sleep(100);}throw new Error('Expected state timed out');}
const camera=()=>page.getByRole('button',{name:'摄像头',exact:true});
const off=()=>page.getByRole('button',{name:'已关闭',exact:true});
async function readyVideo(){await wait(()=>page.locator('video').evaluateAll(videos=>videos.length===1&&videos[0].videoWidth>0&&videos[0].currentTime>0&&videos[0].srcObject.getVideoTracks()[0].readyState==='live'));}
async function state(on){const s=await page.evaluate(()=>window.cameraFixture.snapshot);assert.equal(s.self.camOn,on);assert.equal(s.participants.find(p=>p.isSelf).camOn,on);assert.equal(s.tracks.length,on?1:0);}
let index=0;
async function shot(name,viewport){
 if(!name.includes('开启成功'))await wait(()=>page.locator('[data-sonner-toast]').count().then(count=>count===0),12000);
 const file=`screenshots/${String(++index).padStart(2,'0')}-${name}.png`;
 await page.screenshot({path:path.join(out,file),animations:'disabled'});
 const row={operation:`采集 ${name}`,expected:'保存当前真实打开状态的截图',actual:'已保存；视觉结论待实际打开后登记',passed:true,screenshot:file};
 console.log(JSON.stringify(row));writeFileSync(path.join(out,'steps.jsonl'),JSON.stringify(row)+'\n',{flag:'a'});
 screenshots.push({path:file,viewport:`${viewport.width}×${viewport.height}`});
 save();
}
try{
 await step('环境探测','现有服务可达，隔离端口空闲',async()=>{
  const existing=await fetch('http://127.0.0.1:3118/').then(r=>r.status).catch(()=>null);
  let busy=false;try{await fetch(url,{signal:AbortSignal.timeout(1000)});busy=true;}catch{}assert.equal(busy,false);return `现有 3118 HTTP ${existing}；3148 空闲；CDP 9256/9257 未配置`;
 });
 const log=await import('node:fs').then(fs=>fs.openSync(path.join(out,'dev-server.log'),'a'));
 server=spawn(process.execPath,['-e',`process.on('message',()=>process.exit(0));require(${JSON.stringify(require.resolve('next/dist/server/lib/start-server'))}).startServer({dir:${JSON.stringify(frontend)},isDev:true,hostname:'127.0.0.1',port:3148,allowRetry:false})`],{cwd:frontend,env:{...process.env,OPENMEETING_NEXT_DIST_DIR:'.next-camera-e2e'},stdio:['ignore',log,log,'ipc'],windowsHide:true});
 await wait(async()=>fetch(url).then(r=>r.ok).catch(()=>false),60000);
 browser=await chromium.launch({headless:true,args:['--autoplay-policy=no-user-gesture-required']});
 page=await browser.newPage({viewport:{width:1280,height:800}});page.setDefaultTimeout(10000);
 await page.addInitScript(()=>localStorage.setItem('openmeeting:meeting-audio',JSON.stringify({autoJoin:true})));
 const errors=[];data.browserErrors=errors;page.on('pageerror',e=>errors.push(String(e)));
 await step('夹具加载与入会','真实会议组件从加载态进入摄像头关闭态',async()=>{await page.goto(url);await page.getByTestId('meeting-entry-loading').waitFor();await page.evaluate(()=>window.cameraFixture.releaseJoin());await off().waitFor();await wait(()=>page.evaluate(()=>window.cameraFixture.snapshot?.phase==='joined'));await state(false);});
 await step('首次开启','无信令回传仍显示本地动态视频',async()=>{await off().click();await camera().waitFor();await readyVideo();await state(true);});
 await step('重复关闭与开启五次','每次绑定新轨道；旧轨道移除；工具栏和成员状态一致',async()=>{
  let previous=await page.locator('video').evaluate(v=>v.srcObject.getVideoTracks()[0].id);
  for(let i=0;i<5;i++){await camera().click();await off().waitFor();await state(false);assert.equal(await page.locator('video').count(),0);await off().click();await camera().waitFor();await readyVideo();await state(true);const id=await page.locator('video').evaluate(v=>v.srcObject.getVideoTracks()[0].id);assert.notEqual(id,previous);previous=id;}
 });
 await step('权限拒绝与回滚','确定性 NotAllowedError；错误展示；两处 camOn=false；没有旧预览',async()=>{await camera().click();await off().waitFor();await page.evaluate(()=>window.cameraFixture.deny=true);await off().click();await page.getByTestId('media-status').filter({hasText:'权限'}).waitFor();await state(false);assert.equal(await page.locator('video').count(),0);});
 await step('权限恢复后重试','正常开启且错误提示消失',async()=>{await page.evaluate(()=>window.cameraFixture.deny=false);await off().click();await readyVideo();await state(true);assert.equal(await page.getByTestId('media-status').count(),0);});
 await step('聚焦与退出聚焦','切换布局后视频继续播放',async()=>{await page.locator('video').click();await page.getByRole('button',{name:'还原宫格',exact:true}).waitFor();await readyVideo();await page.getByRole('button',{name:'还原宫格',exact:true}).click();await readyVideo();});
 assert.deepEqual(errors,[]);
 if(!smoke)for(const viewport of [{width:1280,height:800},{width:600,height:900}])await step(`采集 ${viewport.width}×${viewport.height} 状态与浮层`,'功能断言通过后采集加载、空态、成功、权限、抽屉、弹窗及关闭画面',async()=>{
  const prefix=viewport.width===1280?'桌面':'窄屏';await page.setViewportSize(viewport);
  await page.reload();await page.getByTestId('meeting-entry-loading').waitFor();await shot(prefix+'-加载',viewport);
  await page.evaluate(()=>window.cameraFixture.releaseJoin());await off().waitFor();await shot(prefix+'-关闭空态',viewport);
  await off().click();await readyVideo();await shot(prefix+'-开启成功',viewport);
  await camera().click();await off().waitFor();await page.evaluate(()=>window.cameraFixture.deny=true);await off().click();await page.getByTestId('media-status').waitFor();await shot(prefix+'-权限失败',viewport);
  await page.evaluate(()=>window.cameraFixture.deny=false);await off().click();await readyVideo();
  await page.getByRole('button',{name:'成员',exact:true}).click();const panelClose=page.getByTestId('room-side-panel').getByRole('button',{name:'关闭',exact:true});await panelClose.waitFor();await page.mouse.wheel(0,600);await shot(prefix+'-成员抽屉',viewport);await panelClose.click();
  await page.getByRole('button',{name:'成员操作',exact:true}).first().click();await page.getByRole('menuitem',{name:'查看成员信息',exact:true}).click();await page.getByRole('dialog').waitFor();await shot(prefix+'-成员弹窗',viewport);await page.keyboard.press('Escape');await page.getByRole('dialog').waitFor({state:'detached'});
  await readyVideo();await shot(prefix+'-恢复并关闭浮层',viewport);
 });
 await step('浏览器运行完整性','无未捕获异常',async()=>{assert.deepEqual(errors,[]);return '无 pageerror；视频有解码尺寸且时间前进';});
}catch(e){console.error(e);process.exitCode=1;if(page){data.failureState=await page.evaluate(()=>({snapshot:window.cameraFixture?.snapshot,operations:window.cameraFixture?.operations})).catch(()=>null);const file='screenshots/failed.png';await page.screenshot({path:path.join(out,file)}).catch(()=>{});data.failureScreenshot=file;}}
finally{
 if(browser)await browser.close();
 if(server){try{if(server.connected)server.send('shutdown');await wait(()=>server.exitCode!==null,10000);const stopped=await fetch(url,{signal:AbortSignal.timeout(1000)}).then(()=>false).catch(()=>true);data.cleanup=stopped?'本次 Next 开发服务和无头浏览器已关闭，3148 不可达；临时 public 夹具已移除':'关闭后端口仍可达，需检查';}catch(e){data.cleanup='关闭异常：'+e.message;}}
 for(const file of files)if(existsSync(file))unlinkSync(file);
 writeFileSync(tsconfigPath,tsconfigBefore);
 data.elapsedSeconds=Math.round((Date.now()-started)/1000);save();if(!smoke)report();console.log('Artifacts: '+out);
}
