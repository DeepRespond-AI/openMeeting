import { testAdb, testDevice } from './local-tools.cjs';
// Real Windows Tauri <-> Android interoperability; no RTC/IM/media substitutes.
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import net from 'node:net';
import {spawn, execFileSync} from 'node:child_process';
import {createRequire} from 'node:module';
const root=path.resolve(import.meta.dirname,'../..');
const pointer=path.join(root,'.artifacts/share-interop-current.json');
const adb=testAdb();
const device=testDevice();
const require=createRequire(path.join(root,'frontend/package.json'));
const {chromium}=require('playwright');
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
for(const k of ['HTTP_PROXY','HTTPS_PROXY','ALL_PROXY','http_proxy','https_proxy','all_proxy'])delete process.env[k];
const mode=process.argv[2]||'setup';
const out=mode==='setup'?path.join(root,`.artifacts/mobile-desktop-share-${Date.now()}`):JSON.parse(fs.readFileSync(pointer)).out;
fs.mkdirSync(path.join(out,'screenshots'),{recursive:true});
const save=(name,data)=>fs.writeFileSync(path.join(out,name),JSON.stringify(data,null,2));
const read=name=>JSON.parse(fs.readFileSync(path.join(out,name),'utf8').replace(/^\uFEFF/,''));
const run=(...args)=>execFileSync(adb,['-s',device,...args],{windowsHide:true,timeout:15000,maxBuffer:20*1024*1024});
async function api(account,method,route,body){
 const r=await fetch('http://127.0.0.1:39110/api/v1'+route,{method,headers:{...(account?{authorization:`Bearer ${account.token}`} :{}),'content-type':'application/json'},body:body===undefined?undefined:JSON.stringify(body),signal:AbortSignal.timeout(20000)});
 const text=await r.text();let data;try{data=JSON.parse(text);}catch{}return {status:r.status,data};
}
function launch(exe,args,log,env={},cwd=root){const fd=fs.openSync(path.join(out,log),'a');const p=spawn(exe,args,{cwd,env:{...process.env,...env},windowsHide:true,detached:true,stdio:['ignore',fd,fd]});fs.closeSync(fd);p.unref();return p.pid;}
if(mode==='setup'){
 fs.writeFileSync(pointer,JSON.stringify({out}));save('budget.json',{started:Date.now(),limitMs:1800000});
 const accounts=[];
 for(const profile of ['e2ehost20261022','e2emember20261022','rtchostvalidation','rtcmembervalidation','dev1','dev2']){
  const f=path.join(process.env.APPDATA,`com.openmeeting.ai.${profile}`,'server-config.json');if(!fs.existsSync(f))continue;
  const cfg=JSON.parse(fs.readFileSync(f));if(!cfg.sessionToken)continue;
  const a={token:cfg.sessionToken};const me=await api(a,'GET','/auth/me');
  if(me.status===200&&!accounts.some(x=>x.user.id===me.data.id))accounts.push({...a,user:me.data});if(accounts.length===2)break;
 }
 if(accounts.length!==2)throw Error('Two existing sessions required');save('accounts.private.json',accounts);
 const denied=await api(null,'GET','/meetings');if(denied.status!==401)throw Error('Unauthorized smoke failed');save('smoke.json',{unauthorized:denied.status,accounts:2,realBackend:true});
 const timeout=run('shell','settings','get','system','screen_off_timeout').toString().trim();
 save('device-before.json',{timeout,forward:run('forward','--list').toString(),reverse:run('reverse','--list').toString()});
 run('shell','settings','put','system','screen_off_timeout','1800000');run('shell','input','keyevent','KEYCODE_WAKEUP');run('shell','wm','dismiss-keyguard');run('reverse','tcp:39343','tcp:39343');run('reverse','tcp:39110','tcp:39110');
 const source=(process.env.OPENMEETING_NATIVE_CLIENT_DIR || path.join(root,'.artifacts/recording-controls-merge/clients/a'));
 fs.mkdirSync(path.join(out,'client'),{recursive:true});for(const f of ['openmeeting.exe','app_lib.dll','ffmpeg.exe'])fs.copyFileSync(path.join(source,f),path.join(out,'client',f));
 const profile=path.join(process.env.APPDATA,'com.openmeeting.ai.imready.a');fs.mkdirSync(profile,{recursive:true});
 const config=path.join(profile,'server-config.json');save('profile-backup.private.json',{file:config,existed:fs.existsSync(config),content:fs.existsSync(config)?fs.readFileSync(config,'utf8'):null});
 fs.writeFileSync(config,JSON.stringify({sessionToken:accounts[0].token,clientId:`interop-${Date.now()}`}));
 save('tsconfig-before.json',{text:fs.readFileSync(path.join(root,'frontend/tsconfig.json'),'utf8')});
 const state={out};save('processes.json',state);state.bridge=launch(process.execPath,[import.meta.filename,'bridge'],'bridge.log');save('processes.json',state);
 execFileSync(process.execPath,['scripts/build-im-engine.mjs'],{cwd:path.join(root,'frontend'),windowsHide:true,stdio:'ignore'});
 state.next=launch(process.execPath,['node_modules/next/dist/bin/next','dev','-p','3162'],'next.log',{OPENMEETING_NEXT_DIST_DIR:'.next-interop',NEXT_PUBLIC_LIVE_MEETING_DATA_SOURCE:'real'},path.join(root,'frontend'));
 save('processes.json',state);console.log(JSON.stringify({out,setup:true}));
}else if(mode==='resume'){
 const accounts=read('accounts.private.json'),b=read('profile-backup.private.json');
 fs.writeFileSync(b.file,JSON.stringify({sessionToken:accounts[0].token,clientId:`interop-${Date.now()}`}));
 const state={out};save('processes.json',state);state.bridge=launch(process.execPath,[import.meta.filename,'bridge'],'bridge-resume.log');save('processes.json',state);
 state.next=launch(process.execPath,['node_modules/next/dist/bin/next','dev','-p','3162'],'next.log',{OPENMEETING_NEXT_DIST_DIR:'.next-interop',NEXT_PUBLIC_LIVE_MEETING_DATA_SOURCE:'real'},path.join(root,'frontend'));save('processes.json',state);
 run('shell','settings','put','system','screen_off_timeout','1800000');
 console.log(JSON.stringify({resumed:true,budgetUnchanged:true}));
}else if(mode==='bridge'){
 const state=read('processes.json');state.bridge=process.pid;save('processes.json',state);
 const mappingTimer=setInterval(()=>{try{const mappings=run('reverse','--list').toString();for(const port of [39343,39110])if(!mappings.includes(`tcp:${port} tcp:${port}`))run('reverse',`tcp:${port}`,`tcp:${port}`);}catch{}},1500);
 const accounts=read('accounts.private.json');let next=null,latest=null,visual=false,consentNumber=0;
 const respond=(res,status,obj)=>{res.writeHead(status,{'content-type':'application/json'});res.end(JSON.stringify(obj));};
 const server=http.createServer(async(req,res)=>{try{
  const parts=[];for await(const c of req)parts.push(c);const body=Buffer.concat(parts).toString();
  if(req.url==='/session')return respond(res,200,{...accounts[1],code:fs.existsSync(path.join(out,'room.json'))?read('room.json').code:null});
  if(req.url==='/command'&&req.method==='POST'){next=JSON.parse(body);latest=null;return respond(res,200,{ok:true});}
  if(req.url==='/command'){const c=next;next=null;return respond(res,200,c||{action:'wait'});}
  if(req.url==='/complete'){latest=JSON.parse(body);fs.appendFileSync(path.join(out,'mobile-steps.jsonl'),body+'\n');console.log(body);return respond(res,200,{ok:true});}
  if(req.url==='/status')return respond(res,200,latest||{waiting:true});
  if(req.url==='/visual-phase'){visual=true;return respond(res,200,{ok:true});}
  if(req.url==='/consent'){
   const allow=JSON.parse(body).allow;let clicked=false;
   for(let i=0;i<8&&!clicked;i++){
    const focus=run('shell','dumpsys','window').toString();
    if(/mCurrentFocus[^\r\n]*(MediaProjection|ScreenCapture)/i.test(focus)){
     run('shell','uiautomator','dump','/sdcard/interop-ui.xml');const xml=run('shell','cat','/sdcard/interop-ui.xml').toString();
     for(const node of xml.matchAll(/<node\b[^>]*>/g)){const text=/text="([^"]*)"/.exec(node[0])?.[1],b=/bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"/.exec(node[0]);
      if(b&&(allow?/^(立即开始|开始录制|现在开始|Start now)$/i:/^(取消|Cancel)$/i).test(text??'')){if(visual)fs.writeFileSync(path.join(out,'screenshots',`visual-system-${++consentNumber}-${allow?'allow':'deny'}.png`),run('exec-out','screencap','-p'));run('shell','input','tap',String((+b[1]+ +b[3])/2),String((+b[2]+ +b[4])/2));clicked=true;break;}}
    }if(!clicked)await sleep(400);
   }run('shell','rm','-f','/sdcard/interop-ui.xml');return respond(res,clicked?200:409,{clicked});
  }
  if(req.url.startsWith('/frame/')){const name=req.url.split('/').pop();if(!/^[a-z0-9-]+\.png$/.test(name))throw Error('Invalid frame name');fs.writeFileSync(path.join(out,'screenshots',name),Buffer.concat(parts));return respond(res,200,{ok:true});}
  if(req.url==='/shutdown'){respond(res,200,{ok:true});clearInterval(mappingTimer);server.close();proxy.close();return;}
  respond(res,404,{});
 }catch(e){respond(res,500,{error:e.message});}});
 // Cached test binary's compiled gateway is :3160. Forward transparently to the
 // already-running production gateway; preserve auth and WebSocket payloads.
 const proxy=http.createServer((req,res)=>{const p=http.request({hostname:'127.0.0.1',port:39110,path:req.url,method:req.method,headers:req.headers},r=>{res.writeHead(r.statusCode,r.headers);r.pipe(res);});p.on('error',()=>{res.writeHead(502);res.end();});req.pipe(p);});
 proxy.on('upgrade',(req,socket,head)=>{const upstream=net.connect(39110,'127.0.0.1',()=>{upstream.write(`${req.method} ${req.url} HTTP/1.1\r\n${Object.entries(req.headers).map(([k,v])=>`${k}: ${v}`).join('\r\n')}\r\n\r\n`);if(head.length)upstream.write(head);socket.pipe(upstream).pipe(socket);});upstream.on('error',()=>socket.destroy());socket.on('error',()=>upstream.destroy());});
 proxy.listen(3160,'127.0.0.1');server.listen(39343,'127.0.0.1');
}else if(mode==='desktop'){
 const state=read('processes.json');
 for(let i=0;i<60;i++){try{const r=await fetch('http://localhost:3162');if(r.ok)break;}catch{}await sleep(1000);}
 state.desktop=launch(path.join(out,'client/openmeeting.exe'),[],'desktop.log',{OPENMEETING_E2E_BROWSER_ARGS:'--remote-debugging-port=9261 --remote-allow-origins=* --autoplay-policy=no-user-gesture-required --disable-features=msWebOOUI,msPdfOOUI,msSmartScreenProtection',WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS:'--remote-debugging-port=9261 --remote-allow-origins=* --auto-select-desktop-capture-source=OpenMeeting Interop RGB'},path.join(root,'frontend'));save('processes.json',state);console.log(JSON.stringify({desktop:state.desktop}));
}else if(mode==='reset'){
 const browser=await chromium.connectOverCDP('http://127.0.0.1:9261');const p=browser.contexts()[0].pages().find(p=>p.url().startsWith('http://localhost:3162')&&!p.url().includes('/im/'));
 for(const name of ['停止共享','取消共享'])if(await p.getByRole('button',{name,exact:true}).isVisible())await p.getByRole('button',{name,exact:true}).click();await p.setViewportSize({width:1280,height:800});await browser.close();
}else if(mode==='enter'){
 const browser=await chromium.connectOverCDP('http://127.0.0.1:9261');const p=browser.contexts()[0].pages().find(p=>p.url().startsWith('http://localhost:3162')&&!p.url().includes('/im/'));
 const room=read('room.json');await p.evaluate(code=>sessionStorage.setItem('liveMeeting.joinIntent',JSON.stringify({code,name:'',micOn:false,camOn:false})),room.code);
 await p.goto(`http://localhost:3162/room?code=${room.code}`);await p.getByTestId('room-toolbar-region').waitFor({timeout:65000});console.log(JSON.stringify({joined:true}));await browser.close();
}else if(mode==='create'){
 const browser=await chromium.connectOverCDP('http://127.0.0.1:9261');const p=browser.contexts()[0].pages().find(p=>p.url().startsWith('http://localhost:3162')&&!p.url().includes('/im/'));
 p.setDefaultTimeout(25000);await p.getByRole('button',{name:'快速会议 立即发起一场会议',exact:true}).click();
 await p.waitForURL(u=>u.pathname==='/room'&&!!u.searchParams.get('code'),{timeout:60000});
 const room=await p.evaluate(code=>window.__TAURI_INTERNALS__.invoke('room_get_code',{code}),new URL(p.url()).searchParams.get('code'));
 save('room.json',room);console.log(JSON.stringify({created:true,code:room.code}));await browser.close();
}else if(mode==='diagnose'){
 const browser=await chromium.connectOverCDP('http://127.0.0.1:9261');const p=browser.contexts()[0].pages().find(p=>p.url().startsWith('http://localhost:3162')&&!p.url().includes('/im/'));
 const events=[];for(const page of browser.contexts()[0].pages()){page.on('console',m=>{if(['error','warning'].includes(m.type()))events.push({kind:m.type(),text:m.text().slice(0,1200)});});page.on('pageerror',e=>events.push({kind:'exception',text:e.message}));page.on('requestfailed',r=>events.push({kind:'requestfailed',url:new URL(r.url()).pathname,error:r.failure()?.errorText}));}
 await p.getByRole('button',{name:'重试',exact:true}).click();await sleep(22000);save('desktop-diagnostic.json',{events,body:await p.locator('body').innerText(),targets:await fetch('http://127.0.0.1:9261/json/list').then(r=>r.json())});console.log(JSON.stringify({events,body:await p.locator('body').innerText()}));await browser.close();
}else if(mode==='verify'){
 const visual=process.argv.includes('--visual'),resultFile=visual?'replay-results.json':'results.json';
 if(visual&&!read('assertions-passed.json').passed)throw Error('Assertions must pass before screenshot replay');
 if(fs.existsSync(path.join(out,resultFile)))fs.copyFileSync(path.join(out,resultFile),path.join(out,`history-${resultFile}-${Date.now()}.json`));
 if(visual)await fetch('http://127.0.0.1:39343/visual-phase',{method:'POST'});
 const browser=await chromium.connectOverCDP('http://127.0.0.1:9261');const p=browser.contexts()[0].pages().find(p=>p.url().startsWith('http://localhost:3162')&&!p.url().includes('/im/'));
 p.setDefaultTimeout(20000);const rows=[],room=read('room.json');let markerBrowser,view='assertions',activeRow;
 const budget=read('budget.json');
 const step=async(operation,expected,fn)=>{const row={phase:visual?'screenshots':'assertions',viewport:view,operation,expected,actual:'',pass:false,screenshot:null};try{activeRow=row;if(Date.now()-budget.started>budget.limitMs)throw Error('30 minute budget exhausted');row.actual=await fn();row.pass=true;}catch(e){row.actual=String(e.message);row.screenshot=`screenshots/${view}-${String(rows.length+1).padStart(2,'0')}-failure-desktop.png`;await p.screenshot({path:path.join(out,row.screenshot)}).catch(()=>{});fs.writeFileSync(path.join(out,'screenshots',`${view}-${String(rows.length+1).padStart(2,'0')}-failure-android.png`),run('exec-out','screencap','-p'));}finally{activeRow=null;rows.push(row);save(resultFile,rows);console.log(JSON.stringify(row));}return row.pass;};
 const until=async(fn,ms=60000)=>{const end=Date.now()+ms;while(Date.now()<end){const value=await fn();if(value)return value;await sleep(400);}throw Error('Expected interop state timed out');};
 const mobile=async(action,extra={})=>{await fetch('http://127.0.0.1:39343/command',{method:'POST',body:JSON.stringify({action,...extra})});const row=await until(async()=>{const r=await fetch('http://127.0.0.1:39343/status').then(r=>r.json());return r.operation===action?r:null;},75000);if(!row.pass)throw Error(row.actual);return row.actual;};
 const remotePixels=async()=>{
  await p.waitForFunction(()=>{const v=document.querySelector('[data-testid="screen-stage"] video');return v&&v.readyState>=2&&v.videoWidth>100&&v.videoHeight>100;},{},{timeout:55000});
  const sample=()=>p.locator('[data-testid="screen-stage"] video').evaluate(v=>{const c=document.createElement('canvas');c.width=160;c.height=100;const ctx=c.getContext('2d');ctx.drawImage(v,0,0,160,100);const d=ctx.getImageData(0,0,160,100).data;const colors=new Set();for(let i=0;i<d.length;i+=80)colors.add(`${d[i]>>4},${d[i+1]>>4},${d[i+2]>>4}`);return {width:v.videoWidth,height:v.videoHeight,time:v.currentTime,frames:v.getVideoPlaybackQuality().totalVideoFrames,colors:colors.size};});
  const a=await sample();await sleep(1500);const b=await sample();if(b.time<=a.time||b.frames<=a.frames||b.colors<=3)throw Error(`Remote frame verification failed ${JSON.stringify({a,b})}`);return b;
 };
 const shot=async(name)=>{await p.screenshot({path:path.join(out,'screenshots',`${view}-${name}-desktop.png`)});fs.writeFileSync(path.join(out,'screenshots',`${view}-${name}-android.png`),run('exec-out','screencap','-p'));const row=activeRow??rows.at(-1);if(row){row.screenshot=`screenshots/${view}-${name}-desktop.png`;row.androidScreenshot=`screenshots/${view}-${name}-android.png`;save(resultFile,rows);}};
 try{
  const boot=await step('mobile-boot','Current Android test package boots real app and existing identity',()=>until(async()=>{const r=await fetch('http://127.0.0.1:39343/status').then(r=>r.json());return r.operation==='boot'?r:null;},180000));
  if(!boot)throw Error('Android startup blocked');
  for(const width of visual?[1280,640]:[0]){
  view=width?String(width):'assertions';if(width)await p.setViewportSize({width,height:800});
  const joined=await step('two-native-participants','Windows and Android join same real IM RTC room',async()=>{await mobile('join',{code:room.code});return 'Windows toolbar ready; Android media connected';});
  if(!joined)throw Error('RTC join blocked');
  if(visual)await shot('01-normal');
  await step('android-permission-denial','System denial leaves sharing idle and creates no owner',()=>mobile('deny'));
  if(visual)await shot('02-denied');
  let mobileStarted=await step('android-publish','Android real MediaProjection publishes screen:<claim> over existing RTC',()=>mobile('start'));
  if(mobileStarted){await step('windows-receive-android','Windows renders changing remote Android pixels',()=>remotePixels());await shot('03-android-to-windows');}
  await step('android-stop','Android stops capture and remote screen disappears',async()=>{await mobile('stop');await p.locator('[data-testid="screen-stage"]').waitFor({state:'hidden',timeout:20000});return 'Remote stage removed';});
  markerBrowser=await chromium.launch({headless:false,channel:'chrome',args:['--window-size=960,640']});const marker=await markerBrowser.newPage();await marker.setContent('<title>OpenMeeting Interop RGB</title><style>body{margin:0;font:48px sans-serif;color:white}div{height:33vh;display:grid;place-items:center}</style><div style="background:#e11">WINDOWS RED</div><div style="background:#090">WINDOWS GREEN</div><div style="background:#11e" id="clock">WINDOWS BLUE</div><script>setInterval(()=>document.querySelector("#clock").textContent="WINDOWS BLUE "+new Date().toISOString(),300)</script>');
  const desktopStarted=await step('windows-publish','Windows native system source publishes through real IM RTC',async()=>{await p.getByRole('button',{name:'共享屏幕',exact:true}).click();if(visual)await shot('04-choosing');execFileSync('powershell.exe',['-NoProfile','-ExecutionPolicy','Bypass','-File',path.join(root,'tests/e2e/select-share-source.ps1'),'-TestProcessId',String(read('processes.json').desktop)],{windowsHide:true,timeout:20000});await p.getByRole('button',{name:'停止共享',exact:true}).waitFor({timeout:40000});return 'Native Windows screen capture published';});
  if(desktopStarted){await step('android-receive-windows','Android receives a remote screen publication and nonuniform real frame',()=>mobile('remote',{tag:view}));await shot('05-windows-to-android');await p.getByRole('button',{name:'停止共享',exact:true}).click();await step('windows-stop','After stopping, both sides return to normal meeting',async()=>{await p.locator('[data-testid="screen-stage"]').waitFor({state:'hidden'});const state=await mobile('state');if(state!=='connected, shared=0')throw Error(`Unexpected final state: ${state}`);return state;});}
  if(rows.every(r=>r.pass)){await shot('06-restored');if(!visual)save('assertions-passed.json',{passed:true});}
  await markerBrowser?.close();markerBrowser=null;
  }
 }catch(e){save('blocked.json',{error:e.message});console.log(JSON.stringify({blocked:e.message}));}
 finally{await mobile('finish').catch(()=>{});await markerBrowser?.close();await browser.close();save('budget-outcome.json',{elapsedMs:Date.now()-budget.started,withinBudget:Date.now()-budget.started<=budget.limitMs});}
}else if(mode==='cleanup'){
 const rows=[],accounts=read('accounts.private.json'),room=read('room.json'),state=read('processes.json');
 const record=async(operation,fn)=>{try{rows.push({operation,pass:true,actual:await fn()});}catch(e){rows.push({operation,pass:false,actual:e.message});}save('cleanup.json',rows);};
 await record('end-only-this-test-room',async()=>{const r=await api(accounts[0],'POST',`/rooms/${room.id}/end`);if(r.status!==200)throw Error(`End HTTP ${r.status}`);save('ended-room.json',{roomId:room.id,meetingId:r.data?.meetingId});return {status:r.status};});
 await record('delete-only-generated-test-record',async()=>{const id=read('ended-room.json').meetingId;if(!id)return 'No generated record';const r=await api(accounts[0],'DELETE',`/meetings/${encodeURIComponent(id)}`);if(![200,204].includes(r.status))throw Error(`Delete HTTP ${r.status}`);return {status:r.status};});
 await record('stop-owned-bridge',async()=>{const r=await fetch('http://127.0.0.1:39343/shutdown',{method:'POST',signal:AbortSignal.timeout(5000)});if(!r.ok)throw Error('Bridge shutdown failed');return r.status;});
 for(const [label,pid] of [['desktop',state.desktop],['next',state.next]])await record(`stop-owned-${label}`,async()=>{
  const script=`$p=Get-CimInstance Win32_Process -Filter "ProcessId=${Number(pid)}";if($p){if(($p.ExecutablePath -like '${out.replaceAll("'","''")}*') -or (($p.Name -eq 'node.exe') -and ($p.CommandLine -like '*next*3162*'))){taskkill.exe /PID ${Number(pid)} /T /F | Out-Null}else{throw 'Process identity mismatch'}}`;
  execFileSync('powershell.exe',['-NoProfile','-EncodedCommand',Buffer.from(script,'utf16le').toString('base64')],{windowsHide:true});return {pid};
 });
 await record('restore-test-desktop-profile',async()=>{const b=read('profile-backup.private.json');if(b.existed)fs.writeFileSync(b.file,b.content);else if(fs.existsSync(b.file))fs.unlinkSync(b.file);return 'Original test profile restored; daily profiles untouched';});
 await record('restore-tsconfig',async()=>{fs.writeFileSync(path.join(root,'frontend/tsconfig.json'),read('tsconfig-before.json').text);return 'Exact baseline text restored';});
 await record('remove-owned-next-cache',async()=>{const target=path.resolve(root,'frontend/.next-interop');if(target!==path.join(root,'frontend','.next-interop'))throw Error('Cache target mismatch');fs.rmSync(target,{recursive:true,force:true});return 'Only .next-interop removed';});
 const before=read('device-before.json');
 await record('restore-device-timeout',async()=>{run('shell','settings','put','system','screen_off_timeout',before.timeout);const actual=run('shell','settings','get','system','screen_off_timeout').toString().trim();if(actual!==before.timeout)throw Error('Timeout mismatch');return actual;});
 for(const pkg of ['cn.deeprespond.meeting.coreretry','cn.deeprespond.meeting.shareinterop'])await record(`remove-owned-${pkg}`,async()=>{run('shell','am','force-stop',pkg);if(run('shell','pm','list','packages',pkg).toString().includes(`package:${pkg}`)){const result=run('uninstall',pkg).toString();if(!result.includes('Success'))throw Error('Uninstall failed');}return 'Absent';});
 for(const port of [39343,39110])await record(`restore-reverse-${port}`,async()=>{if(!before.reverse.includes(`tcp:${port} `))run('reverse','--remove',`tcp:${port}`);return 'Baseline preserved';});
 await record('remove-only-owned-debug-forwards',async()=>{const lines=run('forward','--list').toString().trim().split(/\r?\n/).filter(Boolean);for(const line of lines){if(line.startsWith(device+' ')&&!before.forward.includes(line)){const port=line.split(/\s+/)[1];if(/^tcp:\d+$/.test(port))run('forward','--remove',port);}}return run('forward','--list').toString();});
 await record('restore-original-debug-forwards',async()=>{for(const line of before.forward.split(/\r?\n/).filter(Boolean)){const [serial,local,remote]=line.trim().split(/\s+/);if(serial===device&&/^tcp:\d+$/.test(local)&&/^tcp:\d+$/.test(remote))run('forward',local,remote);}return run('forward','--list').toString();});
 await record('original-mobile-app-preserved',async()=>{const text=run('shell','pm','list','packages','cn.deeprespond.meeting').toString();if(!text.split(/\r?\n/).includes('package:cn.deeprespond.meeting'))throw Error('Original app missing');return 'Original package/data retained';});
 await record('screen-service-stopped',async()=>{const text=run('shell','dumpsys','activity','services','cn.deeprespond.meeting.coreretry').toString();if(!text.includes('(nothing)'))throw Error('Test service still present');return 'No test service';});
 console.log(JSON.stringify(rows));
}else if(mode==='sdk'){
 const browser=await chromium.connectOverCDP('http://127.0.0.1:9261');const p=browser.contexts()[0].pages().find(p=>p.url().startsWith('http://localhost:3162')&&!p.url().includes('/im/'));
 const info=await p.evaluate(async()=>{const i=window.__TAURI_INTERNALS__;const id=i.transformCallback(()=>{},false);return i.invoke('plugin:deeprespond-im|hello',{js_version:'1.0.0-alpha',protocol:1,channel:`__CHANNEL__:${id}`});});
 save('sdk-info.json',info);console.log(JSON.stringify({state:info.engine_state,anotherInstance:info.another_instance}));
 const dest=await p.evaluate(async()=>window.__TAURI_INTERNALS__.invoke('plugin:deeprespond-im|diagnostics_export',{save_to:null,info:{}}));fs.copyFileSync(dest,path.join(out,'sdk-diagnostic.zip'));console.log(JSON.stringify({diagnosticSaved:true}));await browser.close();
}else if(mode==='inspect'){
 const browser=await chromium.connectOverCDP('http://127.0.0.1:9261');const p=browser.contexts()[0].pages().find(p=>p.url().startsWith('http://localhost:3162')&&!p.url().includes('/im/'));
 const state=await p.evaluate(()=>{
  const el=document.querySelector('body');let f=el[Object.keys(el).find(k=>k.startsWith('__reactFiber'))];while(f?.return)f=f.return;const q=[f],seen=new Set(),rows=[];
  while(q.length){const x=q.pop();if(!x||seen.has(x))continue;seen.add(x);const v=x.memoizedProps?.value;
   if(v&&typeof v==='object'){const r={keys:Object.keys(v)};for(const k of ['status','errorText','phase','entryStatus','entryError','mediaState','chatStatus','mediaAvailable','devicesReady'])if(k in v)r[k]=typeof v[k]==='object'?JSON.stringify(v[k],(key,value)=>['track','video','token','ticket'].includes(key)?undefined:value):v[k];rows.push(r);}q.push(x.child,x.sibling);
  }return rows;
 });save('react-diagnostic.json',state);console.log(JSON.stringify(state));await browser.close();
}else if(mode==='probe'){
 const browser=await chromium.connectOverCDP('http://127.0.0.1:9261');for(const p of browser.contexts()[0].pages())console.log(JSON.stringify({url:p.url(),body:(await p.locator('body').innerText()).slice(0,1300)}));await browser.close();
}
