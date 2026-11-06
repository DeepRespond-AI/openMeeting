import fs from 'node:fs';import path from 'node:path';import {spawn} from 'node:child_process';
const root=path.resolve(import.meta.dirname,'../..'),front=path.join(root,'frontend'),out=path.join(root,'.artifacts/same-account-entry-fix');fs.mkdirSync(out,{recursive:true});
const checks=[];
if(fs.existsSync(path.join(out,'checks.json')))fs.copyFileSync(path.join(out,'checks.json'),path.join(out,`checks-history-${Date.now()}.json`));
for(const [name,args]of [['rtc-contract',['tests/contracts/meeting-resilience.mjs']],['entry-contract',['tests/contracts/meeting-entry-ui.mjs']],['typescript',['node_modules/typescript/bin/tsc','--noEmit']]]){
 const started=Date.now();const child=spawn(process.execPath,args,{cwd:front,windowsHide:true,stdio:['ignore','pipe','pipe']});let output='';child.stdout.on('data',b=>output+=b);child.stderr.on('data',b=>output+=b);const code=await new Promise((ok,no)=>{child.on('error',no);child.on('exit',ok)});
 fs.writeFileSync(path.join(out,name+'.log'),output);checks.push({operation:name,expected:'All relevant checks pass',actual:{exitCode:code,durationMs:Date.now()-started,log:name+'.log',passedCases:name==='rtc-contract'?output.split('\n').filter(l=>l.startsWith('PASS ')).length:name==='entry-contract'?output.split('\n').filter(l=>{try{return JSON.parse(l).pass}catch{return false}}).length:null},pass:code===0,screenshot:null});fs.writeFileSync(path.join(out,'checks.json'),JSON.stringify(checks,null,2));console.log(JSON.stringify(checks.at(-1)));
}
if(checks.some(c=>!c.pass))process.exitCode=1;
