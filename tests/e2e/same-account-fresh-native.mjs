import { testSdk } from './local-tools.cjs';
// Build a current native shell to separate stale debug-profile failures from
// the live RTC duplicate-device rejection. Reuses the root Cargo cache.
import fs from 'node:fs';
import path from 'node:path';
import {spawn,execFileSync} from 'node:child_process';
const root=path.resolve(import.meta.dirname,'../..'),front=path.join(root,'frontend'),out=path.join(root,'.artifacts/same-account-meeting-entry');
const main=process.env.OPENMEETING_MAIN_WORKSPACE||root,target=path.join(main,'target');
const nativeSdk=testSdk();
const binary=path.join(main,'frontend/src-tauri/binaries/ffmpeg-x86_64-pc-windows-msvc.exe');
fs.mkdirSync(path.join(front,'src-tauri/binaries'),{recursive:true});const binaryDestination=path.join(front,'src-tauri/binaries',path.basename(binary));if(path.resolve(binary)!==path.resolve(binaryDestination))fs.copyFileSync(binary,binaryDestination);
const budget=JSON.parse(fs.readFileSync(path.join(out,'budget.json')));if(Date.now()-budget.started>budget.limitMs)throw Error('30 minute E2E budget exhausted');
const state=JSON.parse(fs.readFileSync(path.join(out,'processes.json')));
for(const record of state.processes.filter(r=>r.label==='client-fresh')){const script=`$p=Get-CimInstance Win32_Process -Filter "ProcessId=${record.pid}";if($p){if($p.ExecutablePath -ne '${record.exe.replaceAll("'","''")}'){throw 'Unexpected process'};& taskkill.exe /PID ${record.pid} /T /F | Out-Null}`;execFileSync('powershell.exe',['-NoProfile','-EncodedCommand',Buffer.from(script,'utf16le').toString('base64')],{windowsHide:true,stdio:'pipe'});}
state.processes=state.processes.filter(r=>r.label!=='client-fresh');fs.writeFileSync(path.join(out,'processes.json'),JSON.stringify(state,null,2));
const sdk=path.join(out,'native-sdk-debug');
fs.cpSync(nativeSdk,sdk,{recursive:true});
const engine=path.join(sdk,'src/engine.rs');fs.writeFileSync(engine,fs.readFileSync(engine,'utf8').replace('let window = builder.build()?;',`let builder = if cfg!(debug_assertions) { if let Ok(args) = std::env::var("OPENMEETING_E2E_BROWSER_ARGS") { builder.additional_browser_args(&args) } else { builder } } else { builder }; let window = builder.build()?;`));
const config=JSON.parse(fs.readFileSync(path.join(front,'src-tauri/tauri.conf.json')));
const identifier='com.openmeeting.ai.sameaccount20261030';
const override={identifier,build:{devUrl:'http://localhost:3162',beforeDevCommand:''},app:{windows:[{...config.app.windows[0],label:'main',title:'Same account entry investigation',additionalBrowserArgs:'--remote-debugging-port=9271 --remote-allow-origins=* --autoplay-policy=no-user-gesture-required'}]}};
const fd=fs.openSync(path.join(out,'fresh-native-build.log'),'a');
const lock=path.join(root,'Cargo.lock'),before=fs.readFileSync(lock);
try{const child=spawn((process.env.OPENMEETING_CARGO_BIN || 'cargo'),['--config',`patch.crates-io.tauri-plugin-deeprespond-im.path=${JSON.stringify(sdk.replaceAll('\\','/'))}`,'build','-p','openmeeting','--bin','openmeeting'],{cwd:root,env:{...process.env,CARGO_TARGET_DIR:target,OPENMEETING_SERVER_URL:'http://127.0.0.1:39110',TAURI_CONFIG:JSON.stringify(override)},windowsHide:true,stdio:['ignore',fd,fd]});
await new Promise((ok,no)=>{child.on('error',no);child.on('exit',code=>code===0?ok():no(Error('Native build failed '+code)))});}finally{fs.writeFileSync(lock,before);fs.closeSync(fd);}
const dest=path.join(out,'clients/fresh');fs.mkdirSync(dest,{recursive:true});
for(const name of ['openmeeting.exe','app_lib.dll'])fs.copyFileSync(path.join(target,'debug',name),path.join(dest,name));fs.copyFileSync(binary,path.join(dest,'ffmpeg.exe'));
const accounts=JSON.parse(fs.readFileSync(path.join(out,'accounts.private.json')));
const profile=path.join(process.env.APPDATA,identifier,'server-config.json');if(!state.profiles.some(p=>p.file===profile))state.profiles.push({file:profile,backup:fs.existsSync(profile)?fs.readFileSync(profile,'utf8'):null});fs.mkdirSync(path.dirname(profile),{recursive:true});fs.writeFileSync(profile,JSON.stringify({sessionToken:accounts[0].token,clientId:'same-account-fresh-native'}));
const log=fs.openSync(path.join(out,'client-fresh.log'),'a');const exe=path.join(dest,'openmeeting.exe');
const app=spawn(exe,[],{cwd:front,env:{...process.env,OPENMEETING_E2E_BROWSER_ARGS:override.app.windows[0].additionalBrowserArgs,WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS:'--remote-debugging-port=9271 --remote-allow-origins=*'},windowsHide:true,detached:true,stdio:['ignore',log,log]});fs.closeSync(log);app.unref();state.processes.push({pid:app.pid,exe,label:'client-fresh'});fs.writeFileSync(path.join(out,'processes.json'),JSON.stringify(state,null,2));
fs.writeFileSync(path.join(out,'fresh-build.json'),JSON.stringify({identifier,pid:app.pid,source:'develop 621fea8; current Rust and frontend; SDK debug-only browser-arguments instrumentation matches hidden/main WebView options',cdp:9271},null,2));console.log(JSON.stringify({operation:'build and launch current native shell',pass:true,pid:app.pid,cdp:9271}));
