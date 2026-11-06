import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
const base=process.env.IM_SDK_ROOT||fileURLToPath(new URL('../../node_modules/@deeprespond/im-web/',import.meta.url));
const source=fs.readFileSync(path.join(base,'dist/chunk-ZFSVU4RW.js'),'utf8');
const start=source.indexOf('function normalize(ranges) {');
const end=source.indexOf('function highestEnd(ranges)',start);
assert.ok(start>0&&end>start,'Pinned SDK layout changed; review patch and test');
const context=vm.createContext({});
vm.runInContext(source.slice(start,end),context);
let failed=0;
for(const [operation,input,seq,expected]of[
 ['first confirmed message in an empty conversation',[],1,[[1,1]]],
 ['new group member first visible live message',[],42,[[42,42]]],
 ['ack after a missing range retains only proven messages',[[1,3]],6,[[1,3],[6,6]]],
 ['contiguous live messages',[[1,3]],4,[[1,4]]],
 ['duplicate receive/ack is idempotent',[[1,3]],3,[[1,3]]],
]){
 const actual=JSON.parse(JSON.stringify(context.extendIfAdjacent(input,seq)));
 try{assert.deepEqual(actual,expected);console.log(JSON.stringify({operation,expected,actual,pass:true}));}
 catch{failed++;console.log(JSON.stringify({operation,expected,actual,pass:false}));}
}
process.exitCode=failed?1:0;
