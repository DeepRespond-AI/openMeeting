import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
const root=fileURLToPath(new URL('../../',import.meta.url));
const out=path.resolve(root,process.env.MEETING_READY_OUTPUT||'.artifacts/meeting-recording-controls');
const rows=[];
const save=()=>fs.writeFileSync(path.join(out,'checks.json'),JSON.stringify({rows},null,2));
const evidenceOnly=process.argv.includes('--evidence-only');
if(evidenceOnly)rows.push(...JSON.parse(fs.readFileSync(path.join(out,'checks.json'),'utf8')).rows.filter(r=>['typescript','recording-contract','im-contract'].includes(r.operation)&&r.pass));
for(const [name,args] of evidenceOnly?[]:[['typescript',['node_modules/typescript/bin/tsc','--noEmit']],['recording-contract',['tests/contracts/room-recording.mjs']],['im-contract',['tests/contracts/meeting-im-chat.mjs']]]){
 const result=spawnSync(process.execPath,args,{cwd:path.join(root,'frontend'),encoding:'utf8',windowsHide:true});
 fs.writeFileSync(path.join(out,name+'.txt'),(result.stdout||'')+(result.stderr||''));
 const row={operation:name,expected:'exit 0',actual:{exitCode:result.status,log:name+'.txt'},pass:result.status===0,screenshot:null};rows.push(row);save();console.log(JSON.stringify(row));
}
const xml=fs.readFileSync(path.join(out,'backend-regression.xml'),'utf8');
const suite=xml.match(/<testsuite\s[^>]*>/)?.[0]||'';
const values=Object.fromEntries(['tests','failures','errors','skipped'].map(k=>[k,Number(suite.match(new RegExp(k+'="(\\d+)"'))?.[1]??-1)]));
rows.push({operation:'backend regression',expected:'all real isolated DB tests pass',actual:{...values,log:'backend-regression.txt'},pass:values.tests>0&&values.failures===0&&values.errors===0,screenshot:null});
const buildBytes=fs.readFileSync(path.join(out,'build.txt'));
const build=buildBytes.toString(buildBytes[0]===255&&buildBytes[1]===254?'utf16le':'utf8').split('\n').filter(l=>l.startsWith('{"action":"build"')).map(l=>JSON.parse(l));
rows.push({operation:'new native builds',expected:'all three Tauri executables built with recording control IPC',actual:{clients:build.map(r=>r.client),log:'build.txt'},pass:build.length===3&&build.every(r=>r.pass),screenshot:null});
save();for(const r of rows.slice(-2))console.log(JSON.stringify(r));if(rows.some(r=>!r.pass))process.exitCode=1;
