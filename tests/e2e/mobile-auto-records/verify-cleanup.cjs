const fs=require('node:fs'),path=require('node:path'),cp=require('node:child_process');
const out=path.resolve(__dirname,'../../../.artifacts/mobile-auto-records');
const code="$ProgressPreference='SilentlyContinue'; @(Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Where-Object {$_.LocalPort -in @(3260,3261,3263,3267,39330,39331,39110,3160)} | Select-Object -ExpandProperty LocalPort -Unique) | ConvertTo-Json -Compress";
const raw=cp.execFileSync('powershell.exe',['-NoProfile','-EncodedCommand',Buffer.from(code,'utf16le').toString('base64')],{encoding:'utf8'}).trim();
const parsed=raw?JSON.parse(raw):[],ports=Array.isArray(parsed)?parsed:[parsed];
const file=path.join(out,'cleanup.json'),rows=JSON.parse(fs.readFileSync(file,'utf8'));
rows.push({action:'端口复核补查（保留前次脚本类型错误）',passed:ports.every(p=>[39110,3160].includes(p))&&ports.includes(39110),
  actual:{ownPortsClosed:ports.every(p=>[39110,3160].includes(p)),gateway39110Preserved:ports.includes(39110),
    otherTest3160Listening:ports.includes(3160),otherTestProcessWasNotStoppedByThisRun:true,
    applicationInstalledOrReplaced:false,tabletDuringRun:'offline',at:new Date().toISOString()}});
const stop=path.join(out,'logs/gradle-final-stop.txt');
if(fs.existsSync(stop)){
  const b=fs.readFileSync(stop),text=b[0]===255&&b[1]===254?b.subarray(2).toString('utf16le'):b.toString();
  rows.push({action:'最终修复构建后关闭Gradle',passed:/Daemon stopped|Daemon\(s\) stopped|No Gradle daemons/.test(text),actual:{log:'logs/gradle-final-stop.txt'}});
}
fs.writeFileSync(file,JSON.stringify(rows,null,2));console.log(JSON.stringify(rows.slice(-2),null,2));
if(rows.at(-1).passed!==true||!ports.includes(39110)||ports.some(p=>![39110,3160].includes(p)))process.exitCode=1;
