// Separate processes prevent Bun mock.module state leaking between unrelated suites.
import {readdirSync} from 'node:fs';
import {spawnSync} from 'node:child_process';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const root=fileURLToPath(new URL('../',import.meta.url));
const bun=process.env.OPENMEETING_BUN_BIN||(process.versions.bun?process.execPath:'bun');
function discover(directory){return readdirSync(directory,{withFileTypes:true}).flatMap(entry=>{
 const file=path.join(directory,entry.name);return entry.isDirectory()?discover(file):/\.test\.[jt]sx?$/.test(file)?[file]:[];
});}
const files=['tests/hooks','tests/lib'].flatMap(directory=>discover(path.join(root,directory))).sort();
let failures=0;
for(const file of files){
 const relative=path.relative(root,file);
 const result=spawnSync(bun,['test',relative],{cwd:root,stdio:'inherit'});
 if(result.error){console.error('Bun is required. Install it or set OPENMEETING_BUN_BIN to its executable path.');process.exit(1);}
 if(result.status!==0)failures++;
}
console.log(`${files.length} test files, ${failures} failed`);
if(failures)process.exitCode=1;
