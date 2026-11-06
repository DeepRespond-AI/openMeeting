// Loopback-only fault proxy. Normal traffic goes to the existing real gateway.
// No production code or data source is substituted. Never log auth headers.
const http = require('node:http');
const upstream = new URL(process.env.OPENMEETING_GATEWAY || 'http://127.0.0.1:3160');
const port = Number(process.env.OPENMEETING_FIXTURE_PORT || 39330);
let mode = {};
const sockets = new Set();
const server = http.createServer(async (req, res) => {
  const pathname = new URL(req.url, 'http://fixture').pathname;
  const json = (status, body) => {
    res.writeHead(status, {'content-type': 'application/json; charset=utf-8'});
    res.end(JSON.stringify(body));
  };
  if (pathname === '/__fixture/mode') {
    if (req.method === 'POST') {
      let body = '';
      for await (const chunk of req) body += chunk;
      try { mode = JSON.parse(body); } catch { return json(400, {detail: 'invalid fixture mode'}); }
    }
    return json(200, mode);
  }
  if (pathname === '/api/v1/scheduled-meetings' && req.method === 'GET') {
    if (mode.schedules === 'error') return json(503, {detail: '测试夹具：日程服务暂不可用'});
    if (mode.schedules === 'empty') return json(200, []);
    if (mode.schedules === 'delay') await new Promise(resolve => setTimeout(resolve, 2000));
  }
  if (pathname === '/api/v1/rooms/join' && mode.join === 'delay') {
    await new Promise(resolve => setTimeout(resolve, 2000));
  }
  if (/^\/api\/v1\/rooms\/[^/]+$/.test(pathname) && req.method === 'PATCH' && mode.settings === 'forbidden') {
    return json(403, {detail: '测试夹具：当前用户没有主持人权限'});
  }
  if (pathname === '/api/v1/im/ticket' && mode.im === 'error') {
    return json(503, {detail: '测试夹具：IM 服务暂不可用'});
  }
  if (/\/chat-session$/.test(pathname) && mode.chat === 'error') return json(503, {detail:'测试夹具：会议聊天暂不可用'});
  if (/\/recording\/control$/.test(pathname) && mode.recording === 'forbidden') return json(403, {detail:'测试夹具：仅主持人可以开始录制'});
  if (/\/recording\/chunks$/.test(pathname) && mode.upload === 'error') return json(503, {detail:'测试夹具：音频上传暂不可用'});
  if (/\/end$/.test(pathname) && mode.end === 'error') return json(503, {detail:'测试夹具：结束会议暂不可用'});
  if (/^\/api\/v1\/meetings\/[^/]+\/audio$/.test(pathname) && req.method === 'GET') {
    if (mode.download === 'error') return json(503, {detail:'测试夹具：录音下载暂不可用'});
    if (mode.download === 'delay') await new Promise(resolve => setTimeout(resolve, 2000));
  }
  const target = http.request({
    hostname: upstream.hostname, port: upstream.port, path: req.url, method: req.method,
    headers: {...req.headers, host: upstream.host},
  }, response => {
    res.writeHead(response.statusCode, response.headers);
    response.pipe(res);
  });
  target.on('error', () => { if (!res.headersSent) json(502, {detail: '测试网关不可达'}); else res.destroy(); });
  req.pipe(target);
});
server.on('connection', socket => { sockets.add(socket); socket.on('close', () => sockets.delete(socket)); });
server.on('upgrade', (req, downstream, head) => {
  const target = http.request({hostname: upstream.hostname, port: upstream.port, path: req.url,
    method: req.method, headers: {...req.headers, host: upstream.host}});
  target.on('upgrade', (response, socket, upstreamHead) => {
    downstream.write(`HTTP/1.1 ${response.statusCode} Switching Protocols\r\n`);
    for (const [key, value] of Object.entries(response.headers)) downstream.write(`${key}: ${value}\r\n`);
    downstream.write('\r\n');
    if (upstreamHead.length) downstream.write(upstreamHead);
    if (head.length) socket.write(head);
    socket.on('error', () => downstream.destroy());
    downstream.on('error', () => socket.destroy());
    downstream.on('close', () => socket.destroy());
    socket.pipe(downstream); downstream.pipe(socket);
  });
  target.on('response', response => { downstream.end(`HTTP/1.1 ${response.statusCode} Rejected\r\nConnection: close\r\n\r\n`); });
  target.on('error', () => downstream.destroy());
  target.end();
});
for (const signal of ['SIGINT', 'SIGTERM']) process.on(signal, () => {
  for (const socket of sockets) socket.destroy();
  server.close(() => process.exit(0));
});
server.listen(port, '127.0.0.1', () => console.log(JSON.stringify({event: 'fixture_ready', port, pid: process.pid})));
