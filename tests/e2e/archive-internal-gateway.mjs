// Copy a curated acceptance record; raw sessions, databases and network traces stay local.
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {copyFileSync,existsSync,mkdirSync,readFileSync,readdirSync,statSync,writeFileSync} from 'node:fs';
import {execFileSync} from 'node:child_process';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const root=fileURLToPath(new URL('../../',import.meta.url));
const out=process.env.GATEWAY_TEST_OUTPUT||path.join(root,'.artifacts/internal-gateway-routing');
const dest=path.join(root,'docs/testing/archive/内部网关与独立数据库');
const json=f=>JSON.parse(readFileSync(path.join(out,f),'utf8').replace(/^\uFEFF/,''));
const result=json('results.json'),reviews=json('visual-reviews.json'),checks=json('checks.json');
assert.ok(!result.error&&result.steps.every(x=>x.pass),'Do not archive an incomplete final run as passing');
assert.ok(result.steps.filter(x=>x.screenshot).every(x=>reviews[x.screenshot]),'Every final screenshot needs an actual review');
assert.ok(checks.backendPassed>0&&checks.commands.every(x=>x.exitCode===0));
const databases=json('database-cleanup.json');
assert.ok(databases.length===3&&databases.every(x=>x.endsWith(' false')),'Test databases must be stopped');
if(!result.cleanup.some(x=>x.operation==='database containers'))result.cleanup.push({operation:'database containers',states:databases,closed:true,volumesPreserved:true});
writeFileSync(path.join(out,'results.json'),JSON.stringify(result,null,2));
const traces=readdirSync(out).filter(f=>f.endsWith('.zip')).map(name=>{const file=path.join(out,name),buffer=readFileSync(file);return {name,bytes:buffer.length,sha256:createHash('sha256').update(buffer).digest('hex'),archived:false};});
writeFileSync(path.join(out,'trace-manifest.json'),JSON.stringify(traces,null,2));
execFileSync(process.execPath,[path.join(root,'tests/e2e/internal-gateway.mjs'),'--report'],{cwd:root,env:process.env,stdio:'inherit',windowsHide:true});
mkdirSync(dest,{recursive:true});
const selected=['results.json','smoke.json','checks.json','topology.json','visual-reviews.json','database-cleanup.json','trace-manifest.json','测试报告.md','gateway-requests.jsonl','gateway.log','meeting.log','user.log','stt.log','vite.log'];
for(const name of selected)copyFileSync(path.join(out,name),path.join(dest,name));
for(const sub of ['screenshots','checks']){
  mkdirSync(path.join(dest,sub),{recursive:true});
  for(const name of readdirSync(path.join(out,sub))){
    if(statSync(path.join(out,sub,name)).isFile()){
      // Normalize padding in JUnit's captured failure text; the byte-exact original stays in .artifacts.
      if(name.endsWith('.xml'))writeFileSync(path.join(dest,sub,name),readFileSync(path.join(out,sub,name),'utf8').split('\n').map(line=>line.trimEnd()).join('\n'));
      else copyFileSync(path.join(out,sub,name),path.join(dest,sub,name));
    }
  }
}
mkdirSync(path.join(dest,'scripts'),{recursive:true});
for(const name of ['internal-gateway.mjs','internal-gateway-topology.mjs','archive-internal-gateway.mjs','fixtures/internal-gateway-services.py'])copyFileSync(path.join(root,'tests/e2e',name),path.join(dest,'scripts',path.basename(name)));
console.log(JSON.stringify({archive:dest,passedSteps:result.steps.filter(x=>x.pass).length,failedSteps:result.steps.filter(x=>!x.pass).length,screenshots:result.steps.filter(x=>x.screenshot).length,reviewed:result.steps.filter(x=>x.screenshot&&reviews[x.screenshot]).length,backendPassed:checks.backendPassed}));
