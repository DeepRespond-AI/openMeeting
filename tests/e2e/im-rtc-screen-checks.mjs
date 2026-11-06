import {createRequire} from 'node:module';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {mkdirSync,readFileSync,writeFileSync} from 'node:fs';
const root=fileURLToPath(new URL('../../',import.meta.url)),frontend=path.join(root,'frontend'),require=createRequire(path.join(frontend,'package.json'));
const out=path.resolve(process.env.IM_RTC_SCREEN_OUTPUT||path.join(root,'.artifacts/IM第二视频轨道共享'));mkdirSync(out,{recursive:true});
const tsconfig=path.join(frontend,'tsconfig.json'),before=readFileSync(tsconfig),checks=[];
try{
  for(const [name,args] of [
    ['types',[require.resolve('typescript/bin/tsc'),'--noEmit']],
    ['screen',['tests/contracts/im-rtc-screen.mjs']],
    ['camera',['tests/contracts/camera-preview.mjs']],
    ['audio',['tests/contracts/meeting-audio.mjs']],
    ['resilience',['tests/contracts/meeting-resilience.mjs']],
    ['recording',['tests/contracts/room-recording.mjs']],
    ['im-engine',['scripts/build-im-engine.mjs']],
    ['production-build',[require.resolve('next/dist/bin/next'),'build']],
  ]){
    const result=spawnSync(process.execPath,args,{cwd:frontend,env:{...process.env,OPENMEETING_NEXT_DIST_DIR:'.next-e2e-im-rtc-production'},encoding:'utf8',windowsHide:true,maxBuffer:20*1024*1024});
    writeFileSync(path.join(out,`${name}.log`),(result.stdout||'')+(result.stderr||''));
    const stdout=result.stdout||'';
    const summaries=stdout.split('\n').flatMap(line=>{try{return [JSON.parse(line)];}catch{return [];}});
    const summary=summaries.findLast(row=>typeof row.passed==='number');
    const plain=stdout.match(/(\d+)\s+(?:meeting\s+)?(?:(?:audio|camera)\s+)?contracts passed/i);
    const passLines=stdout.split('\n').filter(line=>line.startsWith('PASS ')||line.trim().endsWith(': PASS')).length;
    const count=summary?.passed??(plain?Number(plain[1]):passLines||undefined);
    const row={name,exitCode:result.status??1,count,log:`${name}.log`};checks.push(row);console.log(JSON.stringify(row));writeFileSync(path.join(out,'checks.json'),JSON.stringify(checks,null,2));
    if(row.exitCode!==0)process.exitCode=1;
  }
}finally{writeFileSync(tsconfig,before);}
