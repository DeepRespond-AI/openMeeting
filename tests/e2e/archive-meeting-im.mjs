// Preserve generated evidence; large traces stay in ignored local artifacts per repository rules.
import {createHash} from 'node:crypto';
import {copyFileSync,existsSync,mkdirSync,readFileSync,readdirSync,writeFileSync} from 'node:fs';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
const root=fileURLToPath(new URL('../../',import.meta.url));
const source=path.join(root,'.artifacts/meeting-im-integration');
const target=path.join(root,'docs/testing/archive/会议IM集成');
const result=JSON.parse(readFileSync(path.join(source,'results.json'),'utf8'));
if(result.error||result.steps.some(s=>!s.pass))throw Error('Preserve failures locally before publishing a final page validation archive');
mkdirSync(path.join(target,'screenshots'),{recursive:true});
for(const name of readdirSync(path.join(source,'screenshots')))copyFileSync(path.join(source,'screenshots',name),path.join(target,'screenshots',name));
let report=readFileSync(path.join(source,'测试报告.md'),'utf8');
for(const name of ['results.json','live-results.json','visual-reviews.json','smoke.json','pytest.xml','checks.json'])copyFileSync(path.join(source,name),path.join(target,name));
for(const name of readdirSync(source).filter(name=>name.endsWith('.log'))){
  const renamed=name.replace(/\.log$/,'-log.txt');
  // Keep raw logs locally; expand indentation only in the readable Git archive.
  const readable=readFileSync(path.join(source,name),'utf8').replace(/\t/g,'    ').split(/\r?\n/).map(line=>line.trimEnd()).join('\n');
  writeFileSync(path.join(target,renamed),readable);
  report=report.replaceAll(name,renamed);
}
const traces=[];
for(const name of ['trace.zip','failed-trace.zip']){
  if(!existsSync(path.join(source,name)))continue;
  const bytes=readFileSync(path.join(source,name));
  traces.push({name,bytes:bytes.length,sha256:createHash('sha256').update(bytes).digest('hex'),localPath:'.artifacts/meeting-im-integration/'+name,committed:false});
}
writeFileSync(path.join(target,'local-artifacts.json'),JSON.stringify(traces,null,2));
report=report.replace('[trace.zip](trace.zip)','[本地 trace 清单](local-artifacts.json)');
writeFileSync(path.join(target,'测试报告.md'),report+'\n\n本归档由 `tests/e2e/archive-meeting-im.mjs` 从结构化结果及逐图检查记录生成；大体积 trace 保留在本地，摘要见清单。\n');
console.log(JSON.stringify({archive:target,screenshots:readdirSync(path.join(target,'screenshots')).length,traces:traces.map(t=>({name:t.name,bytes:t.bytes}))}));
