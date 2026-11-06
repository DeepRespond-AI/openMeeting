/** Check local Markdown/HTML links in current docs; --archives includes historical reports. */
import {execFileSync} from 'node:child_process';
import {existsSync,readFileSync,statSync} from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const root=fileURLToPath(new URL('../',import.meta.url));
const archives=process.argv.includes('--archives');
const files=[...new Set(execFileSync('git',['ls-files','-z','--cached','--others','--exclude-standard'],{cwd:root,encoding:'utf8'}).split('\0'))]
 .filter(name=>name.endsWith('.md')&&!name.startsWith('legacy/')&&(archives||!name.startsWith('docs/testing/archive/')))
 .filter(name=>existsSync(path.join(root,name))&&statSync(path.join(root,name)).isFile());
let checked=0;const errors=[];
for(const file of files){
 const text=readFileSync(path.join(root,file),'utf8').replace(/^```[^\n]*\n[\s\S]*?^```[^\n]*$/gm,'');
 const targets=[...text.matchAll(/\]\((<[^>\n]+>|[^)\n]+)\)/g)].map(match=>match[1]);
 targets.push(...[...text.matchAll(/(?:src|href)=["']([^"']+)["']/g)].map(match=>match[1]));
 for(let href of targets){
  href=href.startsWith('<')?href.slice(1,-1):href.replace(/\s+["'][^"']*["']$/,'');
  if(/^(?:[a-z][\w+.-]*:|\/|#)/i.test(href))continue;
  href=decodeURIComponent(href.split(/[?#]/)[0]);if(!href)continue;
  checked++;if(!existsSync(path.resolve(root,path.dirname(file),href)))errors.push({file,href});
 }
}
for(const error of errors)console.error(`${error.file}: missing ${error.href}`);
console.log(`${files.length} documents, ${checked} local links, ${errors.length} missing`);
if(errors.length)process.exitCode=1;
