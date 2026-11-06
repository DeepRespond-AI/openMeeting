import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
const root=fileURLToPath(new URL('../../',import.meta.url));
const out=path.resolve(root,process.env.MEETING_READY_OUTPUT||'.artifacts/chat-sender-avatar-settings');
fs.mkdirSync(out,{recursive:true});
const rows=[];
for(const [name,args] of [
 ['typescript',['node_modules/typescript/bin/tsc','--noEmit']],
 ['im-avatar',['tests/contracts/im-avatar.mjs']],
 ['im-provider-lifecycle',['tests/contracts/im-provider-lifecycle.mjs']],
 ['meeting-im-chat',['tests/contracts/meeting-im-chat.mjs']],
]){
 const r=spawnSync(process.execPath,args,{cwd:path.join(root,'frontend'),encoding:'utf8',windowsHide:true});
 const log=`checks-${name}.txt`;fs.writeFileSync(path.join(out,log),(r.stdout||'')+(r.stderr||'')+(r.error?String(r.error):''));
 const row={operation:name,expected:'exit 0',actual:{exitCode:r.status,log},pass:r.status===0};rows.push(row);
 fs.writeFileSync(path.join(out,'checks.json'),JSON.stringify({rows},null,2));console.log(JSON.stringify(row));
}
if(rows.some(r=>!r.pass))process.exitCode=1;
