const { testDevice } = require('../local-tools.cjs');
const fs=require('fs'),path=require('path'),cp=require('child_process');
const root=path.resolve(__dirname,'../../..'),out=path.join(root,'.artifacts/mobile-desktop-parity');
const rows=[];
function step(action,run){try{rows.push({action,passed:true,actual:run()});}catch(e){rows.push({action,passed:false,actual:e.message});}fs.writeFileSync(path.join(out,'cleanup.json'),JSON.stringify(rows,null,2));console.log(JSON.stringify(rows.at(-1)));}
function ps(code){return cp.execFileSync('powershell.exe',['-NoProfile','-NonInteractive','-EncodedCommand',Buffer.from("$ErrorActionPreference='Stop'; $ProgressPreference='SilentlyContinue'; "+code,'utf16le').toString('base64')],{encoding:'utf8',windowsHide:true,timeout:20000}).trim();}
const processes=JSON.parse(ps("Get-CimInstance Win32_Process | Where-Object {$_.Name -in @('node.exe','python.exe','java.exe')} | Select-Object ProcessId,Name,CommandLine | ConvertTo-Json -Compress"));
const script=path.join(root,'tests/e2e/meeting-ready-services.py').toLowerCase();
step('关闭本次隔离后端监督进程及其子服务',()=>{
 const parent=processes.find(p=>p.Name==='python.exe'&&p.CommandLine.toLowerCase().includes(script)&&!p.CommandLine.includes('--service'));
 if(!parent)throw Error('Expected owned service supervisor not found');
 cp.execFileSync('taskkill.exe',['/PID',String(parent.ProcessId),'/T','/F'],{stdio:'ignore'});return{pid:parent.ProcessId,method:'verified task script, terminate owned tree'};
});
for(const name of ['fixture','bridge'])step('关闭本次 '+name,()=>{
 const fragment=`tests/e2e/mobile-parity/${name}.cjs`;
 const proc=processes.find(p=>p.Name==='node.exe'&&p.CommandLine.replaceAll('\\','/').includes(fragment));
 if(!proc)throw Error('Expected owned '+name+' not found');
 cp.execFileSync('taskkill.exe',['/PID',String(proc.ProcessId),'/T','/F'],{stdio:'ignore'});return{pid:proc.ProcessId};
});
step('停止本次专用测试数据库',()=>{
 const name='openmeeting-mobile-parity-postgres';
 const id=cp.execFileSync('docker.exe',['inspect','--format','{{.Id}}',name],{encoding:'utf8'}).trim();
 if(!id.startsWith('b4448ddec986'))throw Error('Container identity mismatch; preserved');
 return cp.execFileSync('docker.exe',['stop','-t','10',name],{encoding:'utf8',timeout:30000}).trim();
});
step('复核本次端口关闭、保留日常网关',()=>{
 const raw=ps("@(Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Where-Object {$_.LocalPort -in @(3160,3161,3163,3167,39330,39331,39110)} | Select-Object -ExpandProperty LocalPort -Unique) | ConvertTo-Json -Compress");
 const ports=raw?JSON.parse(raw):[];const list=Array.isArray(ports)?ports:[ports];if(list.some(p=>p!==39110)||!list.includes(39110))throw Error('Unexpected remaining listeners '+list.join(','));return{ownPortsClosed:true,preservedGateway:39110};
});
step('保留平板原应用并恢复开发网关映射',()=>{
 const adb=path.join(process.env.LOCALAPPDATA,'Android/Sdk/platform-tools/adb.exe');
 const run=args=>cp.execFileSync(adb,['-s',testDevice(),...args],{encoding:'utf8',timeout:15000}).trim();
 const mapping=run(['reverse','--list']);
 if(!mapping.includes('tcp:39110'))run(['reverse','tcp:39110','tcp:39110']);
 return{wireless:run(['get-state']),reverse:run(['reverse','--list']),originalAppInstalled:run(['shell','pm','path','cn.deeprespond.meeting']).includes('base.apk'),deviceSettingsChanged:false,applicationReplaced:false};
});
if(rows.some(r=>!r.passed))process.exitCode=1;
