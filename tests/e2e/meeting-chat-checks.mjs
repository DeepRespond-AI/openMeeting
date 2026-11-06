import { testPython } from './local-tools.cjs';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';
const root=fileURLToPath(new URL('../../',import.meta.url)),out=path.resolve(root,process.env.MEETING_CHAT_OUTPUT||'.artifacts/会议聊天生命周期与界面');
fs.mkdirSync(out,{recursive:true});const rows=[];
const python=process.env.OPENMEETING_TEST_PYTHON||testPython();
const db=`meeting_chat_contract_${Date.now()}`;
function run(operation,exe,args,cwd,env={}){
 const isolated={...process.env};
 if(operation==='backend-contracts'){
  for(const key of Object.keys(isolated))if(key.startsWith('OPENMEETING_')||['HTTP_PROXY','HTTPS_PROXY','ALL_PROXY','NO_PROXY'].includes(key.toUpperCase()))delete isolated[key];
  Object.assign(isolated,{OPENMEETING_ENV:'test',OPENMEETING_IM_ENABLED:'false',OPENMEETING_EGRESS_PROXY_URL:'',OPENMEETING_INTERNAL_SERVICE_TOKEN:''});
 }
 const r=spawnSync(exe,args,{cwd,env:{...isolated,...env},windowsHide:true,encoding:'utf8',maxBuffer:10*1024*1024});
 const log=`${operation}.log`,output=(r.stdout||'')+(r.stderr||'');fs.writeFileSync(path.join(out,log),output);
 const row={operation,expected:'退出码 0',actual:{exitCode:r.status,error:r.error?.message},pass:r.status===0,log};
 if(operation==='frontend-unit')row.actual.passed=[...output.matchAll(/\n\s*(\d+) pass\b/g)].reduce((n,m)=>n+Number(m[1]),0);
 if(operation==='backend-contracts')row.actual.passed=Number(output.match(/(\d+) passed/)?.[1]||0);
 rows.push(row);fs.writeFileSync(path.join(out,'checks.json'),JSON.stringify(rows,null,2));console.log(JSON.stringify(row));return row.pass;
}
run('typecheck',process.execPath,['node_modules/typescript/bin/tsc','--noEmit','--incremental','false'],path.join(root,'frontend'));
run('frontend-unit',process.execPath,['scripts/test-unit.mjs'],path.join(root,'frontend'),{OPENMEETING_BUN_BIN:process.env.OPENMEETING_BUN_BIN||'bun'});
const create="import asyncio,asyncpg,sys\nasync def main():\n c=await asyncpg.connect('postgresql://openmeeting:openmeeting@127.0.0.1:55439/postgres')\n name=sys.argv[1]\n assert name.startswith('meeting_chat_contract_') and name.replace('_','').isalnum()\n assert not await c.fetchval('SELECT 1 FROM pg_database WHERE datname=$1',name)\n await c.execute('CREATE DATABASE '+name)\n await c.close()\nasyncio.run(main())";
if(run('create-contract-db',python,['-c',create,db],root)){
 try{run('backend-contracts',python,['-m','pytest','-c',path.join(root,'server/pyproject.toml'),path.join(root,'server/tests/test_meeting_im_contract.py'),path.join(root,'server/meeting_ms/tests/test_meeting_im_chat.py'),'-q','--junitxml='+path.join(out,'backend.xml')],out,{PYTHONPATH:path.join(root,'server'),OPENMEETING_TEST_DATABASE_URL:`postgresql+asyncpg://openmeeting:openmeeting@127.0.0.1:55439/${db}`,HTTP_PROXY:'',HTTPS_PROXY:'',ALL_PROXY:''});}
 finally{
 const drop="import asyncio,asyncpg,sys\nasync def main():\n c=await asyncpg.connect('postgresql://openmeeting:openmeeting@127.0.0.1:55439/postgres')\n name=sys.argv[1]\n assert name.startswith('meeting_chat_contract_') and name.replace('_','').isalnum()\n await c.execute('DROP DATABASE '+name+' WITH (FORCE)')\n await c.close()\nasyncio.run(main())";
 run('drop-contract-db',python,['-c',drop,db],root);
 }
}
if(rows.some(r=>!r.pass))process.exitCode=1;
