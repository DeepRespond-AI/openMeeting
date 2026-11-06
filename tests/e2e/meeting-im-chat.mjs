// Compatibility entry: smoke the deterministic fixture before full page validation.
import {spawn} from 'node:child_process';
import {fileURLToPath} from 'node:url';
const script=fileURLToPath(new URL('./meeting-im-integration.mjs',import.meta.url));
const code=await new Promise((resolve,reject)=>{
  const child=spawn(process.execPath,[script,'--smoke'],{stdio:'inherit',windowsHide:true});
  child.on('error',reject);child.on('exit',resolve);
});
if(code)process.exit(code);
await import('./meeting-im-integration.mjs');
