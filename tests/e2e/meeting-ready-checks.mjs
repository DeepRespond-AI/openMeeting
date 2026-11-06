import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
const root=fileURLToPath(new URL('../../',import.meta.url)),front=path.join(root,'frontend'),out=path.resolve(root,process.env.MEETING_READY_OUTPUT||'.artifacts/meeting-ready-im-sync');
fs.mkdirSync(out,{recursive:true});const checks=[];
if(fs.existsSync(path.join(out,'checks.json'))){const history=path.join(out,`checks-history-${Date.now()}`);fs.mkdirSync(history);for(const name of fs.readdirSync(out).filter(n=>/^check-\d+\.log$/.test(n)||n==='checks.json'))fs.copyFileSync(path.join(out,name),path.join(history,name));}
for(const [name,args]of[
 ['typescript',['node_modules/typescript/bin/tsc','--noEmit']],
 ['SDK confirmed message ranges',['tests/contracts/im-live-ranges.mjs']],
 ['meeting IM transport and cancellation',['tests/contracts/meeting-im-chat.mjs']],
 ['IM authentication preserves active meeting',['tests/contracts/im-provider-lifecycle.mjs']],
 ['media session resilience',['tests/contracts/meeting-resilience.mjs']],
 ['meeting audio device regression',['tests/contracts/meeting-audio.mjs']],
 ['native preview format selection',['tests/contracts/attachment-format.mjs']],
 ['hidden native IM engine build',['scripts/build-im-engine.mjs']],
]){
 const r=spawnSync(process.execPath,args,{cwd:front,encoding:'utf8',windowsHide:true});
 const log=`check-${checks.length+1}.log`;fs.writeFileSync(path.join(out,log),(r.stdout||'')+(r.stderr||''));
 const row={operation:name,expected:'exit 0',actual:{exitCode:r.status},pass:r.status===0,log};checks.push(row);console.log(JSON.stringify(row));
}
const source=path.join(root,'../openmeeting/frontend/node_modules/@deeprespond/im-web');
if(fs.existsSync(source)){
 const r=spawnSync(process.execPath,['tests/contracts/im-live-ranges.mjs'],{cwd:front,encoding:'utf8',windowsHide:true,env:{...process.env,IM_SDK_ROOT:source}});
 fs.writeFileSync(path.join(out,'sdk-before-fix.jsonl'),r.stdout||'');
 checks.push({operation:'negative control: previous SDK',expected:'3 regression cases fail; two existing cases pass',actual:{exitCode:r.status},pass:r.status===1,log:'sdk-before-fix.jsonl'});
}
fs.writeFileSync(path.join(out,'checks.json'),JSON.stringify({checks},null,2));
if(checks.some(c=>!c.pass))process.exitCode=1;
