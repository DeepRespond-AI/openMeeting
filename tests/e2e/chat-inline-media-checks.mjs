import {createRequire} from 'node:module';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
import fs from 'node:fs';
import {spawnSync} from 'node:child_process';
const root=fileURLToPath(new URL('../../',import.meta.url)),front=path.join(root,'frontend');
const out=path.resolve(root,process.env.CHAT_INLINE_MEDIA_OUTPUT||'.artifacts/聊天图片视频直接展示');
fs.mkdirSync(out,{recursive:true});
const require=createRequire(path.join(front,'package.json')),config=path.join(front,'tsconfig.json'),before=fs.readFileSync(config),rows=[];
try{
  for(const [operation,args] of [
    ['typecheck',[require.resolve('typescript/bin/tsc'),'--noEmit','--incremental','false']],
    ['frontend-unit',['scripts/test-unit.mjs']],
    ['production-build',[require.resolve('next/dist/bin/next'),'build']],
  ]){
    const result=spawnSync(process.execPath,args,{cwd:front,env:{...process.env,OPENMEETING_NEXT_DIST_DIR:'.next-e2e-inline-media-production',OPENMEETING_BUN_BIN:process.env.OPENMEETING_BUN_BIN||'bun'},windowsHide:true,encoding:'utf8',maxBuffer:10*1024*1024});
    const output=(result.stdout||'')+(result.stderr||''),log=`${operation}.log`;
    fs.writeFileSync(path.join(out,log),output);
    const row={operation,expected:'退出码0',actual:{exitCode:result.status,passed:operation==='frontend-unit'?[...output.matchAll(/\n\s*(\d+) pass\b/g)].reduce((n,m)=>n+Number(m[1]),0):undefined},pass:result.status===0,log};
    rows.push(row);fs.writeFileSync(path.join(out,'checks.json'),JSON.stringify(rows,null,2));console.log(JSON.stringify(row));if(!row.pass)process.exitCode=1;
  }
}finally{fs.writeFileSync(config,before);}
