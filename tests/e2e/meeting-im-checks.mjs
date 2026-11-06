import {spawn} from 'node:child_process';
import {mkdirSync,writeFileSync} from 'node:fs';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
const root=fileURLToPath(new URL('../../',import.meta.url)),out=path.join(root,'.artifacts/meeting-im-integration');
mkdirSync(out,{recursive:true});
const python=process.env.OPENMEETING_TEST_PYTHON;
if(!python)throw Error('Set OPENMEETING_TEST_PYTHON to an existing server virtualenv Python');
const checks=[];
async function run(name,command,args,cwd,env={}){
  const started=Date.now(),log=path.join(out,name+'.log');writeFileSync(log,'');
  const code=await new Promise((resolve,reject)=>{
    const child=spawn(command,args,{cwd,env:{...process.env,...env},windowsHide:true,stdio:['ignore','pipe','pipe']});
    for(const stream of [child.stdout,child.stderr])stream.on('data',data=>writeFileSync(log,data,{flag:'a'}));
    child.on('error',reject);child.on('exit',resolve);
  });
  const row={name,command:[command,...args].join(' '),pass:code===0,exitCode:code,elapsedMs:Date.now()-started,log:path.basename(log)};checks.push(row);
  writeFileSync(path.join(out,'checks.json'),JSON.stringify(checks,null,2));console.log(JSON.stringify(row));if(code!==0)process.exitCode=1;
}
await run('python',python,['-m','pytest','tests/test_meeting_im_contract.py','tests/test_rtc_integration.py','meeting_ms/tests/test_im_notifications.py','meeting_ms/tests/test_meeting_im_chat.py','meeting_ms/tests/test_rooms.py','meeting_ms/tests/test_rooms_ws.py','meeting_ms/tests/test_room_resilience.py','meeting_ms/tests/test_room_recording.py','meeting_ms/tests/test_room_feature_merge.py','meeting_ms/tests/test_scheduled.py','-q',`--junitxml=${path.join(out,'pytest.xml')}`],path.join(root,'server'),{OPENMEETING_TEST_DATABASE_URL:'postgresql+asyncpg://openmeeting:openmeeting@127.0.0.1:55439/openmeeting_im_chat_test',HTTP_PROXY:'',HTTPS_PROXY:'',ALL_PROXY:''});
await run('typescript',process.execPath,[path.join(root,'frontend/node_modules/typescript/bin/tsc'),'--noEmit','--incremental','false'],path.join(root,'frontend'));
await run('sdk-contract',process.execPath,['tests/contracts/meeting-im-chat.mjs'],path.join(root,'frontend'));
await run('im-engine',process.execPath,['scripts/build-im-engine.mjs'],path.join(root,'frontend'));
