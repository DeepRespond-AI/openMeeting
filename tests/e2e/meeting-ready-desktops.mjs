import {spawn, execFileSync} from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root=fileURLToPath(new URL('../../',import.meta.url));
const front=path.join(root,'frontend'), out=path.resolve(root,process.env.MEETING_READY_OUTPUT||'.artifacts/meeting-ready-im-sync');
fs.mkdirSync(out,{recursive:true});
const statePath=path.join(out,'processes.json');
const state=fs.existsSync(statePath)?JSON.parse(fs.readFileSync(statePath,'utf8')):{};
const target=process.env.MEETING_READY_CARGO_TARGET||path.join(root,'target');
const run=(exe,args,env)=>new Promise((ok,no)=>{
 const child=spawn(exe,args,{cwd:front,env:{...process.env,...env},windowsHide:true,stdio:'inherit'});
 child.on('error',no);child.on('exit',code=>code===0?ok():no(Error(`${exe}: ${code}`)));
});
function launch(exe,args,log,env={}){
 const fd=fs.openSync(path.join(out,log),'a');
 const child=spawn(exe,args,{cwd:front,env:{...process.env,...env},windowsHide:true,detached:true,stdio:['ignore',fd,fd]});
 fs.closeSync(fd);child.unref();return child.pid;
}
if(process.argv.includes('--build')){
 const source=process.env.MEETING_READY_NATIVE_SDK;
 if(!source)throw Error('Set MEETING_READY_NATIVE_SDK to the installed Rust SDK source for the CDP-only test copy');
 const sdk=path.join(out,'native-sdk');fs.cpSync(source,sdk,{recursive:true,force:true});
 const enginePath=path.join(sdk,'src/engine.rs');
 let engine=fs.readFileSync(enginePath,'utf8');
 engine=engine.replace('let window = builder.build()?;',`let builder = if cfg!(debug_assertions) {
        if let Ok(args) = std::env::var("OPENMEETING_E2E_BROWSER_ARGS") { builder.additional_browser_args(&args) } else { builder }
    } else { builder };
    let window = builder.build()?;`);
 fs.writeFileSync(enginePath,engine);
 // This local SDK differs solely in debug WebView arguments. Never ship it.
 const lockPath=path.join(root,'Cargo.lock'),lock=fs.readFileSync(lockPath);
 try{
 const config=JSON.parse(fs.readFileSync(path.join(front,'src-tauri/tauri.conf.json'),'utf8'));
 for(const letter of ['a','b','c']){
  const browserArgs=`--remote-debugging-port=${9261+'abc'.indexOf(letter)} --remote-allow-origins=* --autoplay-policy=no-user-gesture-required --disable-features=msWebOOUI,msPdfOOUI,msSmartScreenProtection`;
  const override={identifier:`com.openmeeting.ai.imready.${letter}`,build:{devUrl:'http://localhost:3162',beforeDevCommand:''},app:{windows:[{...config.app.windows[0],label:'main',title:`IM Ready Test ${letter.toUpperCase()}`,additionalBrowserArgs:browserArgs} ]}};
  await run('cargo',['--config',`patch.crates-io.tauri-plugin-deeprespond-im.path=${JSON.stringify(sdk.replaceAll('\\','/'))}`,'build','-p','openmeeting','--bin','openmeeting'],{CARGO_TARGET_DIR:target,OPENMEETING_SERVER_URL:'http://127.0.0.1:3160',TAURI_CONFIG:JSON.stringify(override)});
  const dir=path.join(out,'clients',letter);fs.mkdirSync(dir,{recursive:true});
  for(const name of ['openmeeting.exe','app_lib.dll'])fs.copyFileSync(path.join(target,'debug',name),path.join(dir,name));
  for(const name of ['ffmpeg.exe','ffmpeg-x86_64-pc-windows-msvc.exe'])fs.copyFileSync(path.join(front,'src-tauri/binaries/ffmpeg-x86_64-pc-windows-msvc.exe'),path.join(dir,name));
  console.log(JSON.stringify({action:'build',client:letter,pass:true}));
 }
 }finally{fs.writeFileSync(lockPath,lock);}
}
if(process.argv.includes('--start')){
 if(state.next||state.clients?.length)throw Error('Stop previous managed processes before launching again');
 await run(process.execPath,['scripts/build-im-engine.mjs']);
 state.next=launch(process.execPath,['node_modules/next/dist/bin/next','dev','-p','3162'],'next.log',{NEXT_PUBLIC_LIVE_MEETING_DATA_SOURCE:'real',OPENMEETING_E2E_SYNTHETIC:'0',OPENMEETING_NEXT_DIST_DIR:'.next-im-ready'});
 fs.writeFileSync(statePath,JSON.stringify(state,null,2));
 let ready=false;
 for(let i=0;i<90;i++){
  try{const response=await fetch('http://localhost:3162/',{signal:AbortSignal.timeout(5000)});await response.body?.cancel();if(response.ok){ready=true;break;}}catch{}
  await new Promise(r=>setTimeout(r,1000));
 }
 if(!ready)throw Error('Next readiness failed; see next.log');
 state.clients=['a','b','c'].map((letter,index)=>({letter,pid:launch(path.join(out,'clients',letter,'openmeeting.exe'),[],`client-${letter}.log`,{OPENMEETING_E2E_BROWSER_ARGS:`--remote-debugging-port=${9261+index} --remote-allow-origins=* --autoplay-policy=no-user-gesture-required --disable-features=msWebOOUI,msPdfOOUI,msSmartScreenProtection`,WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS:`--remote-debugging-port=${9261+index} --remote-allow-origins=*`})}));
 fs.writeFileSync(statePath,JSON.stringify(state,null,2));console.log(JSON.stringify({action:'launch',...state}));
}
if(process.argv.includes('--stop')){
 // Only terminate executable paths created inside this task's output/check-out.
 const records=[...(state.clients||[]),...(state.next?[{pid:state.next}]:[])];
 state.cleanup=[];
 for(const {pid} of records){
  try{
   const script=`$ProgressPreference='SilentlyContinue';$p=Get-CimInstance Win32_Process -Filter "ProcessId=${Number(pid)}"; if($p){if(($p.ExecutablePath -like '${out.replaceAll("'","''")}*') -or (($p.Name -eq 'node.exe') -and ($p.CommandLine -like '*3162*'))){& taskkill.exe /PID ${Number(pid)} /T /F | Out-Null}else{throw 'Unexpected process identity'}}`;
   execFileSync('powershell.exe',['-NoProfile','-NonInteractive','-EncodedCommand',Buffer.from(script,'utf16le').toString('base64')],{windowsHide:true});
   state.cleanup.push({pid,pass:true});
  }catch(error){state.cleanup.push({pid,pass:false,error:String(error.message)});}
 }
 delete state.next;state.clients=[];fs.writeFileSync(statePath,JSON.stringify(state,null,2));console.log(JSON.stringify(state));
}
