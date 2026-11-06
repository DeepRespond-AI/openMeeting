import { testPython } from './local-tools.cjs';
import fs from 'node:fs';
import path from 'node:path';
import { spawn, spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { createRequire } from 'node:module';
const root=fileURLToPath(new URL('../../',import.meta.url)),front=path.join(root,'frontend');
for(const key of Object.keys(process.env))if(['HTTP_PROXY','HTTPS_PROXY','ALL_PROXY'].includes(key.toUpperCase()))delete process.env[key];
const out=path.resolve(process.env.MEETING_UI_NATIVE_OUTPUT||path.join(root,'.artifacts/会议模块配置/native-20261024-1347'));
fs.mkdirSync(out,{recursive:true});
const statePath=path.join(out,'processes.json');
const state=fs.existsSync(statePath)?JSON.parse(fs.readFileSync(statePath,'utf8')):{processes:[]};
if(process.argv.includes('--stop')){
  const rows=[];
  for(const record of [...state.processes].reverse()){
    const probe=spawnSync('powershell.exe',['-NoProfile','-Command',`Get-CimInstance Win32_Process -Filter "ProcessId=${Number(record.pid)}" | Select-Object ProcessId,ExecutablePath,CommandLine | ConvertTo-Json`],{encoding:'utf8',windowsHide:true});
    const actual=probe.stdout.trim()?JSON.parse(probe.stdout):null;
    if(!actual){rows.push({pid:record.pid,pass:true,actual:'already stopped'});continue;}
    const own=actual.ExecutablePath&&path.win32.normalize(actual.ExecutablePath).toLowerCase()===path.win32.normalize(record.exe).toLowerCase()&&(!record.marker||actual.CommandLine?.includes(record.marker));
    if(!own){rows.push({pid:record.pid,pass:false,actual:'process identity changed; preserved'});continue;}
    const stopped=spawnSync('taskkill.exe',['/PID',String(record.pid),'/T','/F'],{encoding:'utf8',windowsHide:true});
    rows.push({pid:record.pid,pass:stopped.status===0,actual:'stopped only recorded owned process'});
  }
  fs.writeFileSync(path.join(out,'service-cleanup.json'),JSON.stringify(rows,null,2));console.log(JSON.stringify({cleanup:rows}));
  process.exit(rows.some(r=>!r.pass)?1:0);
}
const require=createRequire(path.join(front,'package.json'));
if(process.argv.includes('--logout')){
  const {chromium}=require('playwright');
  const accounts=JSON.parse(fs.readFileSync(path.join(out,'accounts.private.json'),'utf8')),rows=[];
  for(let i=0;i<3;i++){
    let browser;
    try{
      browser=await chromium.connectOverCDP(`http://127.0.0.1:${9261+i}`);
      const page=browser.contexts()[0].pages().find(p=>p.url().startsWith('http://localhost:3162')&&!p.url().includes('/im/'));
      const user=await page.evaluate(()=>window.__TAURI_INTERNALS__.invoke('auth_get_user'));
      if(user&&user.id!==accounts[i].id)throw Error('Unexpected user; preserve session');
      if(user)await page.evaluate(()=>window.__TAURI_INTERNALS__.invoke('auth_logout'));
      const config=await page.evaluate(()=>window.__TAURI_INTERNALS__.invoke('server_get_config'));
      rows.push({client:i,loggedOut:!config.loggedIn,pass:!config.loggedIn});
    }catch(error){rows.push({client:i,pass:false,error:String(error.message)});}
    finally{if(browser)await browser.close();}
  }
  fs.writeFileSync(path.join(out,'native-logout.json'),JSON.stringify(rows,null,2));console.log(JSON.stringify({logout:rows}));process.exit(rows.some(r=>!r.pass)?1:0);
}
function launch(exe,args,label,env={},cwd=root,marker){
  const fd=fs.openSync(path.join(out,label+'.log'),'a');
  const child=spawn(exe,args,{cwd,env:{...process.env,MEETING_UI_NATIVE_OUTPUT:out,...env},windowsHide:true,detached:true,stdio:['ignore',fd,fd]});
  fs.closeSync(fd);child.unref();
  const record={pid:child.pid,exe,label,marker};state.processes.push(record);fs.writeFileSync(statePath,JSON.stringify(state,null,2));
  return record;
}
async function ready(port,route='/healthz'){
  const end=Date.now()+60000;
  while(Date.now()<end){if(await fetch(`http://${port===3162?'localhost':'127.0.0.1'}:${port}${route}`,{signal:AbortSignal.timeout(1500)}).then(r=>r.ok).catch(()=>false))return;await new Promise(r=>setTimeout(r,250));}
  throw Error(`owned service ${port} failed readiness`);
}
if(process.argv.includes('--user')){
  launch(testPython(),[path.join(root,'tests/e2e/fixtures/meeting-ui-native-services.py'),'--service','user'],'user',{},path.join(root,'server'),'meeting-ui-native-services.py');
  await ready(3161);
}else if(process.argv.includes('--clients')){
  for(const [i,letter]of ['a','b','c'].entries()){
    const exe=path.join(process.env.MEETING_UI_NATIVE_CLIENTS || path.join(root,'.artifacts/rtc-release-media-preview/clients'),letter,'openmeeting.exe');
    launch(exe,[],`client-${letter}`,{OPENMEETING_E2E_BROWSER_ARGS:`--remote-debugging-port=${9261+i} --remote-allow-origins=* --autoplay-policy=no-user-gesture-required --disable-features=msWebOOUI,msPdfOOUI,msSmartScreenProtection`,WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS:`--remote-debugging-port=${9261+i} --remote-allow-origins=*`},front);
  }
  for(const port of [9261,9262,9263])await ready(port,'/json/list');
}else{
  for(const port of [3160,3161,3162,3163,3167,9261,9262,9263])if(await fetch(`http://127.0.0.1:${port}`,{signal:AbortSignal.timeout(500)}).then(()=>true).catch(()=>false))throw Error(`port ${port} occupied; preserve existing service`);
  for(const service of ['user','meeting','gateway'])launch(testPython(),[path.join(root,'tests/e2e/fixtures/meeting-ui-native-services.py'),'--service',service],service,{},path.join(root,'server'),'meeting-ui-native-services.py');
  for(const port of [3160,3161,3167])await ready(port);
  const nextCode=`require(${JSON.stringify(require.resolve('next/dist/server/lib/start-server'))}).startServer({dir:${JSON.stringify(front)},isDev:true,hostname:'localhost',port:3162,allowRetry:false})`;
  launch(process.execPath,['-e',nextCode],'next',{NEXT_PUBLIC_LIVE_MEETING_DATA_SOURCE:'real',OPENMEETING_NEXT_DIST_DIR:'.next-e2e-native-ui-config',OPENMEETING_E2E_DESKTOP_LAYOUT:'0',OPENMEETING_E2E_MEETING_UI:'0',OPENMEETING_E2E_SYNTHETIC:'0'},front,'3162');
  await ready(3162,'/');
}
console.log(JSON.stringify({operation:'owned native development services ready',processes:state.processes.map(p=>({label:p.label,pid:p.pid})),pass:true}));
