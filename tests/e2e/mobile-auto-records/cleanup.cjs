const { testDevice, testPython } = require('../local-tools.cjs');
// Close only this run's owned services. Existing 39110 and 3160 services survive.
const fs=require('node:fs'),path=require('node:path'),cp=require('node:child_process');
const root=path.resolve(__dirname,'../../..'),out=path.join(root,'.artifacts/mobile-auto-records');
const rows=[];
function ps(code){return cp.execFileSync('powershell.exe',['-NoProfile','-NonInteractive','-EncodedCommand',Buffer.from("$ErrorActionPreference='Stop'; $ProgressPreference='SilentlyContinue'; "+code,'utf16le').toString('base64')],{encoding:'utf8',windowsHide:true,timeout:20000}).trim();}
async function step(action,run){const row={action,passed:false};try{row.actual=await run();row.passed=true;}catch(e){row.actual=e.message;process.exitCode=1;}finally{rows.push(row);fs.writeFileSync(path.join(out,'cleanup.json'),JSON.stringify(rows,null,2));console.log(JSON.stringify(row));}}
(async()=>{
  await step('结束本轮遗留活动房间',async()=>{
    const python=testPython();
    const code="import asyncio,asyncpg,json,sys\nasync def main():\n c=await asyncpg.connect('postgresql://openmeeting:openmeeting@127.0.0.1:55441/meeting_ready_meeting')\n ids=json.loads(sys.stdin.read())\n rows=await c.fetch(\"select id,host_user_id from live_rooms where host_user_id=ANY($1::varchar[]) and status='active'\",ids)\n print(json.dumps([dict(r) for r in rows]))\n await c.close()\nasyncio.run(main())";
    const accounts=JSON.parse(fs.readFileSync(path.join(out,'accounts.private.json'),'utf8'));
    const rooms=JSON.parse(cp.execFileSync(python,['-c',code],{input:JSON.stringify(accounts.map(a=>a.id)),encoding:'utf8'}));
    const tokens=new Map();
    for(const room of rooms){
      const account=accounts.find(a=>a.id===room.host_user_id);if(!account)throw Error('Room ownership mismatch');
      if(!tokens.has(account.id)){
        const r=await fetch('http://127.0.0.1:3260/api/v1/auth/login',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({phone:account.phone,password:account.password,client:{client_id:'mobile-auto-records-cleanup'}}),signal:AbortSignal.timeout(15000)});
        if(!r.ok)throw Error('Owned login failed '+r.status);tokens.set(account.id,(await r.json()).token);
      }
      const r=await fetch(`http://127.0.0.1:3260/api/v1/rooms/${room.id}/end`,{method:'POST',headers:{authorization:'Bearer '+tokens.get(account.id),'content-type':'application/json'},body:'{}',signal:AbortSignal.timeout(15000)});
      if(!r.ok)throw Error('Owned room end failed '+r.status);
    }return{ended:rooms.length};
  });
  await step('删除本轮平台测试资源',()=>{
    const output=cp.execFileSync(testPython(),[path.join(root,'tests/e2e/meeting-ready-cleanup.py'),path.join(root,'server/.env')],{cwd:root,encoding:'utf8',timeout:120000,
      env:{...process.env,MEETING_READY_OUTPUT:out,MEETING_READY_PG_PORT:'55441',OPENMEETING_EGRESS_PROXY_URL:'http://127.0.0.1:3263',OPENMEETING_INTERNAL_SERVICE_TOKEN:'isolated-native-ready'}});
    fs.writeFileSync(path.join(out,'logs/platform-cleanup.txt'),output);
    const result=JSON.parse(fs.readFileSync(path.join(out,'platform-cleanup.json'),'utf8'));
    if(result.errors.length)throw Error('Platform cleanup errors '+result.errors.length);return result;
  });
  await step('关闭本轮隔离后端树',()=>{
    const ids=JSON.parse(fs.readFileSync(path.join(out,'services.json'),'utf8')).pids;
    const raw=ps(`Get-CimInstance Win32_Process | Where-Object {$_.ProcessId -in @(${ids.join(',')})} | Select-Object ProcessId,ParentProcessId,Name,CommandLine | ConvertTo-Json -Compress`);
    const children=JSON.parse(raw);if(children.length!==3||children.some(p=>p.Name!=='python.exe'||!p.CommandLine.toLowerCase().includes(root.toLowerCase())||!p.CommandLine.includes('--service')))throw Error('Service ownership mismatch');
    const parents=[...new Set(children.map(p=>p.ParentProcessId))];if(parents.length!==1)throw Error('Supervisor mismatch');
    cp.execFileSync('taskkill.exe',['/PID',String(parents[0]),'/T','/F'],{stdio:'ignore'});return{supervisor:parents[0],children:ids};
  });
  for(const [name,port] of [['fixture',39330],['bridge',39331]])await step('关闭本轮 '+name,()=>{
    const pid=Number(ps(`Get-NetTCPConnection -LocalPort ${port} -State Listen | Select-Object -First 1 -ExpandProperty OwningProcess`));
    const proc=JSON.parse(ps(`Get-CimInstance Win32_Process -Filter 'ProcessId=${pid}' | Select-Object Name,CommandLine | ConvertTo-Json -Compress`));
    if(proc.Name!=='node.exe'||!proc.CommandLine.replaceAll('\\','/').includes(`tests/e2e/mobile-parity/${name}.cjs`))throw Error('Proxy ownership mismatch');
    cp.execFileSync('taskkill.exe',['/PID',String(pid),'/T','/F'],{stdio:'ignore'});return{pid,port};
  });
  await step('停止本轮专用数据库',()=>{
    const name='openmeeting-mobile-auto-records-postgres',id=cp.execFileSync('docker.exe',['inspect','--format','{{.Id}}',name],{encoding:'utf8'}).trim();
    if(id!=='b6aa1a87b1a8116dd8d3b341b2698c55debe59b507922105646d31bddc9e99d7')throw Error('Container ownership mismatch');
    return cp.execFileSync('docker.exe',['stop','-t','10',name],{encoding:'utf8',timeout:30000}).trim();
  });
  await step('停止本轮Gradle守护进程',()=>{
    const log=cp.execFileSync((process.env.JAVA_HOME ? path.join(process.env.JAVA_HOME,'bin/java.exe') : 'java'),['-classpath',path.join(root,'mobile/android/gradle/wrapper/gradle-wrapper.jar'),'org.gradle.wrapper.GradleWrapperMain','--stop'],{cwd:path.join(root,'mobile/android'),encoding:'utf8',timeout:30000,env:{...process.env,GRADLE_USER_HOME:(process.env.GRADLE_USER_HOME || path.join(out,'gradle-cache'))}});
    fs.writeFileSync(path.join(out,'logs/gradle-stop.txt'),log);if(!/Daemon stopped|Daemon\(s\) stopped|No Gradle daemons/.test(log))throw Error('No daemon stop confirmation');return{stopped:true};
  });
  await step('端口与设备最终复核',()=>{
    const raw=ps("@(Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Where-Object {$_.LocalPort -in @(3260,3261,3263,3267,39330,39331,39110,3160)} | Select-Object -ExpandProperty LocalPort -Unique) | ConvertTo-Json -Compress");
    const parsed=raw?JSON.parse(raw):[],ports=Array.isArray(parsed)?parsed:[parsed];if(ports.some(p=>![39110,3160].includes(p))||!ports.includes(39110))throw Error('Unexpected listeners '+ports);
    const adb=path.join(process.env.LOCALAPPDATA,'Android/Sdk/platform-tools/adb.exe');
    const devices=cp.execFileSync(adb,['devices'],{encoding:'utf8',timeout:15000});
    return{ownPortsClosed:true,preservedPorts:ports,tablet:devices.includes(`${testDevice()}\toffline`)?'offline':'see adb log',deviceSettingsChanged:false,applicationInstalledOrReplaced:false};
  });
})().catch(e=>{console.error(e.message);process.exitCode=1;});
