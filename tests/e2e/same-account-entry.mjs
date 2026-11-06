// Real Tauri/IM/RTC investigation. Two independent desktop device identities
// exercise the same-account condition; this does not claim Android acceptance.
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import net from 'node:net';
import assert from 'node:assert/strict';
import {spawn,execFileSync} from 'node:child_process';
import {createRequire} from 'node:module';
const root=path.resolve(import.meta.dirname,'../..'),front=path.join(root,'frontend');
const main=process.env.OPENMEETING_MAIN_WORKSPACE||root;
const out=path.join(root,'.artifacts/same-account-meeting-entry');
fs.mkdirSync(path.join(out,'screenshots'),{recursive:true});
const write=(name,data)=>fs.writeFileSync(path.join(out,name),JSON.stringify(data,null,2));
const read=name=>JSON.parse(fs.readFileSync(path.join(out,name),'utf8'));
const delay=ms=>new Promise(r=>setTimeout(r,ms));
for(const key of Object.keys(process.env))if(/^(https?|all)_proxy$/i.test(key))delete process.env[key];
const mode=process.argv[2]||'run';
async function api(token,method,route,body){const r=await fetch('http://127.0.0.1:39110/api/v1'+route,{method,headers:{'content-type':'application/json',...(token?{authorization:'Bearer '+token}:{})},body:body===undefined?undefined:JSON.stringify(body),signal:AbortSignal.timeout(20000)});const text=await r.text();return{status:r.status,body:text?JSON.parse(text):null};}
const state=fs.existsSync(path.join(out,'processes.json'))?read('processes.json'):{processes:[],profiles:[]};
function launch(exe,args,label,env={},cwd=front){const fd=fs.openSync(path.join(out,label+'.log'),'a');const child=spawn(exe,args,{cwd,env:{...process.env,...env},windowsHide:true,detached:true,stdio:['ignore',fd,fd]});fs.closeSync(fd);child.unref();state.processes.push({pid:child.pid,exe:path.resolve(exe),label});write('processes.json',state);return child.pid;}
async function ready(url,ms=60000){const end=Date.now()+ms;while(Date.now()<end){if(await fetch(url,{signal:AbortSignal.timeout(2000)}).then(r=>r.ok).catch(()=>false))return;await delay(300);}throw Error('Readiness failed: '+url);}
if(mode==='setup'){
 if(state.processes.length)throw Error('Existing managed processes; clean up first');
 for(const port of [3160,3162,9261,9262,9263]){const busy=await new Promise(resolve=>{const s=net.connect(port,'127.0.0.1');s.on('connect',()=>{s.destroy();resolve(true)});s.on('error',()=>resolve(false));});assert.equal(busy,false,'Preserve occupied port '+port);}
 if(!fs.existsSync(path.join(front,'node_modules')))fs.symlinkSync(path.join(main,'frontend/node_modules'),path.join(front,'node_modules'),'junction');
 const accounts=[];
 for(const profile of ['dev1','dev2']){const c=JSON.parse(fs.readFileSync(path.join(process.env.APPDATA,'com.openmeeting.ai.'+profile,'server-config.json')));const r=await api(c.sessionToken,'GET','/auth/me');assert.equal(r.status,200);accounts.push({token:c.sessionToken,id:r.body.id});}
 assert.notEqual(accounts[0].id,accounts[1].id);write('accounts.private.json',accounts);
 const smoke={identity:true,unauthorized:(await api(null,'GET','/meetings')).status};assert.equal(smoke.unauthorized,401);
 write('smoke.json',smoke);
 execFileSync(process.execPath,['scripts/build-im-engine.mjs'],{cwd:front,windowsHide:true,stdio:'ignore'});
 write('budget.json',{started:Date.now(),limitMs:1800000});
 launch(process.execPath,[import.meta.filename,'bridge'],'bridge',{},root);
 launch(process.execPath,[path.join(front,'node_modules/next/dist/bin/next'),'dev','-p','3162'],'next',{NEXT_PUBLIC_LIVE_MEETING_DATA_SOURCE:'real',OPENMEETING_NEXT_DIST_DIR:'.next-same-account',OPENMEETING_E2E_DESKTOP_LAYOUT:'0',OPENMEETING_E2E_SYNTHETIC:'0'});
 await ready('http://localhost:3162/');
 for(const [i,letter]of ['a','b','c'].entries()){
  const profile=path.join(process.env.APPDATA,'com.openmeeting.ai.imready.'+letter,'server-config.json');
  const backup=fs.existsSync(profile)?fs.readFileSync(profile,'utf8'):null;
  state.profiles.push({file:profile,backup});write('processes.json',state);
  fs.mkdirSync(path.dirname(profile),{recursive:true});fs.writeFileSync(profile,JSON.stringify({sessionToken:accounts[i===2?1:0].token,clientId:'same-account-investigation-'+letter}));
  const source=path.join(main,'.artifacts/meeting-ready-merge/clients',letter),dest=path.join(out,'clients',letter);fs.mkdirSync(dest,{recursive:true});
  for(const name of ['openmeeting.exe','app_lib.dll','ffmpeg.exe'])if(fs.existsSync(path.join(source,name)))fs.copyFileSync(path.join(source,name),path.join(dest,name));
  launch(path.join(dest,'openmeeting.exe'),[],'client-'+letter,{OPENMEETING_E2E_BROWSER_ARGS:`--remote-debugging-port=${9261+i} --remote-allow-origins=* --autoplay-policy=no-user-gesture-required`,WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS:`--remote-debugging-port=${9261+i} --remote-allow-origins=*`});
  await ready(`http://127.0.0.1:${9261+i}/json/list`);
 }
 console.log(JSON.stringify({operation:'setup',pass:true,smoke,out,backend:39110,frontend:3162,clients:3}));
}else if(mode==='bridge'){
 const proxy=http.createServer((req,res)=>{const p=http.request({hostname:'127.0.0.1',port:39110,path:req.url,method:req.method,headers:req.headers},r=>{res.writeHead(r.statusCode,r.headers);r.pipe(res)});p.on('error',()=>{res.writeHead(502);res.end()});req.pipe(p)});
 proxy.on('upgrade',(req,socket,head)=>{const upstream=net.connect(39110,'127.0.0.1',()=>{upstream.write(`${req.method} ${req.url} HTTP/1.1\r\n${Object.entries(req.headers).map(([k,v])=>`${k}: ${v}`).join('\r\n')}\r\n\r\n`);if(head.length)upstream.write(head);socket.pipe(upstream).pipe(socket)});upstream.on('error',()=>socket.destroy());socket.on('error',()=>upstream.destroy())});proxy.listen(3160,'127.0.0.1');
}else if(mode==='cleanup'){
 const cleanup=[];
 async function cleanupApi(token,method,route,body){let last;for(let i=0;i<3;i++){try{return await api(token,method,route,body)}catch(e){last=e;await delay(500)}}cleanup.push({operation:`cleanup request ${method} ${route}`,pass:false,error:String(last?.message)});write('cleanup.json',cleanup);return{status:0,body:null};}
 const accounts=fs.existsSync(path.join(out,'accounts.private.json'))?read('accounts.private.json'):[];
 if(fs.existsSync(path.join(out,'owned-room.json'))){const room=read('owned-room.json');const result=await cleanupApi(accounts[0].token,'POST',`/rooms/${room.id}/end`,{});cleanup.push({operation:'end owned room',status:result.status,pass:result.status===200});
  if(result.status===200&&result.body?.meetingId){let terminal=!result.body.jobId;for(let i=0;i<15&&!terminal;i++){const job=await cleanupApi(accounts[0].token,'GET',`/jobs/${result.body.jobId}`);terminal=job.status===404||(job.status===200&&!['queued','running'].includes(job.body.status));if(!terminal)await delay(500);}if(terminal){const deleted=await cleanupApi(accounts[0].token,'DELETE',`/meetings/${result.body.meetingId}`);cleanup.push({operation:'remove only generated test meeting record',status:deleted.status,pass:[204,404].includes(deleted.status)});}else cleanup.push({operation:'generated record retained because test job is still running',pass:false});}
 }
 write('cleanup.json',cleanup);
 for(const record of [...state.processes].reverse()){
  const script=`$p=Get-CimInstance Win32_Process -Filter "ProcessId=${record.pid}";if($p){if($p.ExecutablePath -ne '${record.exe.replaceAll("'","''")}'){throw 'Process identity changed'};& taskkill.exe /PID ${record.pid} /T /F | Out-Null}`;
  try{execFileSync('powershell.exe',['-NoProfile','-EncodedCommand',Buffer.from(script,'utf16le').toString('base64')],{windowsHide:true,stdio:'pipe'});cleanup.push({operation:'stop '+record.label,pass:true});}catch{cleanup.push({operation:'stop '+record.label,pass:false});}
 }
 for(const p of state.profiles){if(p.backup===null){if(fs.existsSync(p.file))fs.unlinkSync(p.file)}else fs.writeFileSync(p.file,p.backup);}
 cleanup.push({operation:'restore test profiles',pass:true});
 for(const name of ['same-account-probe.js','same-account-probe.html']){const file=path.join(front,'public',name);if(fs.existsSync(file))fs.unlinkSync(file);}
 cleanup.push({operation:'remove generated public probe files',pass:true});
 for(const [i,a]of accounts.entries()){const check=await cleanupApi(a.token,'GET','/auth/me');cleanup.push({operation:'preserve reused business login '+i,status:check.status,pass:check.status===200});}
 write('cleanup.json',cleanup);write('processes.json',{processes:[],profiles:[]});console.log(JSON.stringify(cleanup));
}else if(mode==='run'){
 const require=createRequire(path.join(front,'package.json')),{chromium}=require('playwright');
 const accounts=read('accounts.private.json'),budget=read('budget.json');
 if(fs.existsSync(path.join(out,'results.json')))fs.copyFileSync(path.join(out,'results.json'),path.join(out,`native-history-${Date.now()}.json`));
 const results={boundary:'Current develop UI + cached native debug shells + live business gateway/IM/RTC. Two Windows device identities are a cross-device reproduction, not native Android acceptance.',steps:[],console:[]};
 const browsers=[],pages=[];let room;
 const invoke=(p,command,args={})=>p.evaluate(({command,args})=>window.__TAURI_INTERNALS__.invoke(command,args),{command,args});
 const save=()=>write('results.json',results);
 async function step(operation,expected,fn){if(Date.now()-budget.started>budget.limitMs)throw Error('30 minute E2E budget exhausted');const row={operation,expected,actual:null,pass:false,screenshot:null};try{row.actual=await fn();row.pass=row.actual?.pass!==false;}catch(error){row.actual=String(error.stack||error);throw error;}finally{results.steps.push(row);save();console.log(JSON.stringify(row));}}
 async function until(fn,ms=60000){const end=Date.now()+ms;while(Date.now()<end){const value=await fn();if(value)return value;await delay(250);}throw Error('State did not settle');}
 async function snapshot(p){return p.evaluate(()=>({url:location.pathname,entryError:!!document.querySelector('[data-testid="meeting-entry-error"]'),busy:!!document.querySelector('[aria-busy="true"]'),body:document.body.innerText.slice(0,2600)}));}
 async function join(p,code,name){await p.getByRole('button',{name:'加入会议 输入会议号入会',exact:true}).click();const dialog=p.getByRole('dialog');for(let i=0;i<6;i++)await dialog.locator('input[inputmode="numeric"]').nth(i).fill(code[i]);await dialog.locator('#join-name').fill(name);for(const sw of await dialog.getByRole('switch').all())if(await sw.getAttribute('aria-checked')==='true')await sw.click();await dialog.getByRole('button',{name:'加入会议',exact:true}).click();}
 try{
  await step('native login smoke','Three native clients render current develop; A/B same user, C different user',async()=>{
   for(let i=0;i<3;i++){const b=await chromium.connectOverCDP(`http://127.0.0.1:${9261+i}`);browsers.push(b);const p=await until(()=>b.contexts()[0].pages().find(p=>p.url().startsWith('http://localhost:3162')&&!p.url().includes('/im/')));pages.push(p);p.setDefaultTimeout(20000);p.on('console',async m=>{if(['warning','error'].includes(m.type())){const args=await Promise.all(m.args().map(a=>a.jsonValue().catch(()=>null)));results.console.push({client:i,type:m.type(),text:m.text(),args});save();}});await p.evaluate(()=>{localStorage.setItem('dr.locale','zh-CN');localStorage.setItem('openmeeting:meeting-audio',JSON.stringify({autoJoin:false,microphoneId:'default',speakerId:'default',unmuteSound:false}))});await p.reload();await p.getByRole('button',{name:'快速会议 立即发起一场会议',exact:true}).waitFor({timeout:60000});assert.equal((await invoke(p,'auth_get_user')).id,accounts[i===2?1:0].id);}
   return{native:true,sameAccountClients:[0,1],differentAccountClient:2};
  });
  const [host,duplicate,other]=pages;
  await step('host quick meeting','Real business room, chat and RTC settle successfully before duplicate entry',async()=>{await host.getByRole('button',{name:'快速会议 立即发起一场会议',exact:true}).click();const code=await until(()=>new URL(host.url()).searchParams.get('code'));room=await invoke(host,'room_get_code',{code});write('owned-room.json',{id:room.id,code});const chat=await api(accounts[0].token,'POST',`/rooms/${room.id}/chat-session`,{}),media=await api(accounts[0].token,'POST',`/rooms/${room.id}/media`,{});const settled=await until(async()=>{const s=await snapshot(host);return(s.entryError||s.body.includes('离开并结束'))&&s;});return{code,chatStatus:chat.status,transport:media.body?.transport,settled,pass:!settled.entryError&&chat.status===200&&media.body?.transport==='dr-rtc'};});
  await step('same-account second device joins','Capture real duplicate-device RTC outcome and same participant/host identity',async()=>{await join(duplicate,room.code,'Same account second device');const settled=await until(async()=>{const s=await snapshot(duplicate);return(s.entryError||s.body.includes('离开并结束'))&&s;});const current=await api(accounts[0].token,'GET',`/rooms/${room.id}`);const hostState=await snapshot(host);return{settled,hostState,participants:current.body.participants.map(p=>({id:p.id,isHost:p.isHost,name:p.name})),sameUserParticipantCount:current.body.participants.length};});
  await step('host leave on failed-entry screen','If blocked, leave reproduces host-required-end rejection without ending active room',async()=>{if(!await duplicate.getByTestId('meeting-entry-error').count())return{applicable:false,state:await snapshot(duplicate)};await duplicate.getByRole('button',{name:'离开会议',exact:true}).click();await duplicate.getByText('主持人请使用「离开并结束会议」离场',{exact:true}).waitFor();return{blockedHostLeave:true,roomStatus:(await api(accounts[0].token,'GET',`/rooms/${room.id}`)).body.status};});
  await step('different-account control','Another account connects successfully to the same live room',async()=>{await join(other,room.code,'Different account control');const s=await until(async()=>{const s=await snapshot(other);return(s.entryError||s.body.includes('离开会议'))&&s;});return{...s,pass:!s.entryError};});
  await step('visual evidence','Desktop and narrow screenshots of actual settled states',async()=>{const files=[];for(const [i,p]of pages.entries())for(const [width,height]of [[1280,800],[520,760]]){await p.setViewportSize({width,height});await delay(500);const file=`screenshots/${String(files.length+1).padStart(2,'0')}-${i===0?'host':i===1?'duplicate':'control'}-${width}x${height}.png`;await p.screenshot({path:path.join(out,file),animations:'disabled'});files.push({file,viewport:{width,height},state:await snapshot(p)});}write('screenshots.json',files);return files.map(f=>({file:f.file,viewport:f.viewport}));});
 }catch(error){results.failure=String(error.stack||error);for(const [i,p]of pages.entries()){const file=`screenshots/failure-${Date.now()}-${i}.png`;await p.screenshot({path:path.join(out,file)}).catch(()=>{});results.steps.at(-1).screenshot=file;}console.error(results.failure);process.exitCode=1;
 }finally{save();if(results.steps.some(s=>!s.pass))process.exitCode=1;for(const b of browsers)await b.close();}
}else throw Error('Unknown mode '+mode);
