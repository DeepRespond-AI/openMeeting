// Read-only verification through existing Tauri sessions. Never exports credentials.
import { mkdirSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const root = fileURLToPath(new URL('../../', import.meta.url));
const out = path.resolve(process.env.MEETING_UI_OUTPUT || path.join(root, '.artifacts/会议模块配置'));
mkdirSync(out, { recursive: true });
const results = [];
for (const port of [9261, 9262, 9263]) {
  const item = { operation: `复用原生登录态及业务服务 ${port}`, expected: '保持当前页面；真实IPC确认登录并读取会议列表，仅保存布尔状态和记录数', actual: '', pass: false, screenshot: null };
  let socket;
  try {
    const pages = await fetch(`http://127.0.0.1:${port}/json/list`, { signal: AbortSignal.timeout(3000) }).then(r => r.json());
    const page = pages.find(p => p.type === 'page' && /^https?:/.test(p.url) && !p.url.includes('/im/engine'));
    if (!page) throw Error('未找到主窗口，保留现有客户端');
    socket = new WebSocket(page.webSocketDebuggerUrl);
    const result = await new Promise((resolve, reject) => {
      const timer = setTimeout(() => reject(Error('只读CDP探测超时')), 10000);
      socket.addEventListener('error', () => { clearTimeout(timer); reject(Error('CDP连接失败')); });
      socket.addEventListener('open', () => socket.send(JSON.stringify({ id: 1, method: 'Runtime.evaluate', params: { awaitPromise: true, returnByValue: true, expression: `(async()=>{const status=await window.__TAURI_INTERNALS__.invoke('server_get_status');const meetings=await window.__TAURI_INTERNALS__.invoke('api_get_meetings');return{loggedIn:!!status.loggedIn,authenticated:!!status.authenticated,meetingCount:Array.isArray(meetings)?meetings.length:null,route:location.pathname}})()` } })));
      socket.addEventListener('message', event => {
        const message = JSON.parse(event.data);
        if (message.id !== 1) return;
        clearTimeout(timer);
        if (message.error || message.result?.exceptionDetails) reject(Error('原生只读调用失败，未保存返回数据'));
        else resolve(message.result.result.value);
      });
    });
    item.actual = result;
    item.pass = result.loggedIn && result.authenticated && result.meetingCount !== null;
  } catch (error) { item.actual = String(error); }
  finally { socket?.close(); }
  results.push(item); console.log(JSON.stringify(item));
}
writeFileSync(path.join(out, 'real-backend-smoke.json'), JSON.stringify({ started: new Date().toISOString(), boundary: '真实现有原生客户端、真实Rust IPC和业务网关；只读API冒烟，不计为新配置的原生UI验收', results }, null, 2));
if (results.some(r => !r.pass)) process.exitCode = 1;
