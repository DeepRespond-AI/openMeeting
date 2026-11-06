const { testAdb, testDevice } = require('../local-tools.cjs');
// Local bridge for a real Android integration test. Credentials stay in memory.
const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const cp = require('node:child_process');
const root = process.env.OPENMEETING_PARITY_ARTIFACTS || path.resolve(__dirname, '../../../.artifacts/mobile-desktop-parity');
const adb = testAdb();
const device = testDevice();
const gateway = process.env.OPENMEETING_GATEWAY || 'http://127.0.0.1:3160';
const meeting = process.env.OPENMEETING_MEETING_MS || 'http://127.0.0.1:3167';
const rows = fs.existsSync(path.join(root,'steps.json')) ? JSON.parse(fs.readFileSync(path.join(root,'steps.json'),'utf8')) : [];
let attempt = Math.max(0,...rows.map(r=>r.attempt || 1));
fs.mkdirSync(path.join(root, 'screenshots'), {recursive:true});
fs.mkdirSync(path.join(root, 'logs'), {recursive:true});
function run(args) { return cp.execFileSync(adb, ['-s', device, ...args], {timeout:30000, maxBuffer:20*1024*1024}); }
const server = http.createServer(async (req, res) => {
  const reply = (status, value) => { res.writeHead(status, {'content-type':'application/json'}); res.end(JSON.stringify(value)); };
  try {
    if (req.url === '/asset') { res.writeHead(200,{'content-type':'video/mp4'});return res.end(fs.readFileSync(path.join(root,'fixture-video.mp4'))); }
    if (req.url === '/session') {
      const accounts = JSON.parse(fs.readFileSync(path.join(root,'accounts.private.json'),'utf8'));
      const login = async (account,index) => {
        const r=await fetch(gateway+'/api/v1/auth/login', {method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({phone:account.phone,password:account.password,client:{client_id:'mobile-parity-'+index}})});
        if(!r.ok) throw new Error('isolated_login_failed');
        const value=await r.json(); return {token:value.token,user:value.user};
      };
      const host=await login(accounts[0],0), member=await login(accounts[1],1);
      return reply(200,{...host,peerId:member.user.id,peerToken:member.token});
    }
    let body=''; for await (const chunk of req) body += chunk;
    const data = body ? JSON.parse(body) : {};
    if (req.url === '/recording-state') {const r=await fetch(meeting+'/__e2e/recording/'+encodeURIComponent(data.roomId));return reply(r.status,await r.json());}
    if (req.url === '/start') {
      const budget=path.join(root,'e2e-budget.json');
      if (!fs.existsSync(budget)) fs.writeFileSync(budget, JSON.stringify({firstAttempt:new Date().toISOString(),limitMinutes:30},null,2));
      if (Date.now()-Date.parse(JSON.parse(fs.readFileSync(budget)).firstAttempt)>30*60000) return reply(408,{error:'E2E budget exhausted'});
      attempt = Number(data.attempt) || attempt + 1;
      return reply(200,{ok:true});
    }
    if (req.url === '/permissions') {
      for (const permission of ['android.permission.RECORD_AUDIO','android.permission.CAMERA']) run(['shell','pm','grant','cn.deeprespond.meeting.parity',permission]);
      return reply(200,{granted:['RECORD_AUDIO','CAMERA']});
    }
    if (req.url === '/viewport') {
      run(['shell','settings','put','system','accelerometer_rotation','0']);
      run(['shell','settings','put','system','user_rotation',data.wide?'1':'0']);
      run(['shell','wm','size',data.wide?'1200x1920':'720x1280']);
      run(['shell','wm','density','320']);
      return reply(200, {size:run(['shell','wm','size']).toString(), density:run(['shell','wm','density']).toString()});
    }
    if (req.url === '/step') {
      if (data.capture) {
        const name = `${String(rows.filter(r=>r.screenshot).length+1).padStart(2,'0')}-${data.action.replace(/[^\p{L}\p{N}-]/gu,'-')}.png`;
        fs.writeFileSync(path.join(root,'screenshots',name),run(['exec-out','screencap','-p']));
        data.screenshot = `screenshots/${name}`;
      }
      delete data.capture;
      rows.push({...data, attempt, at:new Date().toISOString()});
      fs.writeFileSync(path.join(root,'steps.json'),JSON.stringify(rows,null,2));
      console.log(JSON.stringify(rows.at(-1)));
      return reply(200,{ok:true});
    }
    return reply(404,{error:'unknown action'});
  } catch (e) { return reply(500,{error:e.code || e.name}); }
});
server.listen(39331,'127.0.0.1',()=>console.log(JSON.stringify({event:'bridge_ready',pid:process.pid,port:39331})));
