import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import { spawn, spawnSync } from 'node:child_process';
import { startLayoutBackend, installLayoutBridge } from './fixtures/desktop-layout-backend.mjs';
const root = fileURLToPath(new URL('../../', import.meta.url)), front = path.join(root, 'frontend');
const out = path.join(root, '.artifacts/scheduled-meeting-not-started'); fs.mkdirSync(path.join(out, 'screenshots'), { recursive: true });
const write = (file, data) => fs.writeFileSync(path.join(out, file), JSON.stringify(data, null, 2));
const read = file => JSON.parse(fs.readFileSync(path.join(out, file), 'utf8'));
const decode = file => { const b = fs.readFileSync(path.join(out, file)); return b[0] === 255 && b[1] === 254 ? b.subarray(2).toString('utf16le') : b.toString('utf8'); };
function report() {
  const r = read('results.json'), smoke = read('smoke.json'), visual = fs.existsSync(path.join(out, 'visual-reviews.json')) ? read('visual-reviews.json') : {};
  const assertions = r.rows.filter(x => x.phase === 'assertions'), shots = r.rows.filter(x => x.screenshot);
  const checks = [['后端', 'backend.log', /27 passed/], ['移动端控制器', 'mobile.log', /All tests passed!/], ['TypeScript', 'typescript.log', /^\s*$/], ['错误分类契约', 'contract.log', /PASS ordinary 403\/409/]].map(([operation, file, pattern]) => ({ operation, file, pass: pattern.test(decode(file)) })); write('checks.json', checks);
  const lines = ['# 会议未开始提示测试报告', '', '分级：本次为入会错误分类与文案的小改动，定向验证未开始/不存在/预检查后入会失败及一条重试成功路径。桌面生产Next页面、真实错误适配器和无头Chromium；HTTP/IPC/IM/RTC为显式夹具，不代表原生媒体验收。后端另用真实隔离PostgreSQL，移动端使用生产控制器和仓库故障替身。', '',
    `页面功能 ${assertions.filter(x => x.pass).length} 通过、${assertions.filter(x => !x.pass).length + (r.error && assertions.every(x => x.pass) ? 1 : 0)} 失败；截图阶段 ${r.rows.filter(x => x.phase === 'screenshots' && x.pass).length} 通过；独立故障冒烟 ${smoke.filter(x => x.pass).length} 通过；代码检查 ${checks.filter(x => x.pass).length} 通过、${checks.filter(x => !x.pass).length} 失败。后端27项、移动端控制器8项。`, '',
    '启动：先 `node tests/e2e/meeting-not-started.mjs --smoke`，再不带参数运行。脚本启动独立Next :3197、OPENMEETING_E2E_DESKTOP_LAYOUT=1、NEXT_PUBLIC_LIVE_MEETING_DATA_SOURCE=real、.next-e2e-not-started（首次执行使用.next-not-started，结束后移动缓存到项目忽略的E2E目录，未清缓存）。探测保留原3118/39110和CDP登录态；无可复用CDP，采用隔离表单登录。后端测试容器openmeeting-not-started-test、PostgreSQL16 :55443/not_started_test，OPENMEETING_TEST_DATABASE_URL指定该库，执行meeting_ms/tests/test_scheduled_lifecycle.py和test_rooms.py。', '',
    `累计E2E预算30分钟，已用 ${(read('budget.json').usedMs / 60000).toFixed(1)} 分钟。运行错误：${r.error || '无'}。`, '',
    '| 阶段/视口/语言 | 操作 | 预期 | 实际 | 结果 | 截图 |', '|---|---|---|---|---|---|',
    ...r.rows.map(s => `| ${s.phase}/${s.viewport}/${s.locale} | ${s.operation} | ${s.expected} | ${String(s.actual).replaceAll('|', '/').replaceAll('\n', ' ')} | ${s.pass ? '通过' : '失败'} | ${s.screenshot ? `[截图](${s.screenshot})` : '—'} |`), '',
    ...checks.map(c => `- ${c.operation}：${c.pass ? '通过' : '失败'}，[日志](${c.file})。`), '',
    `先完成全部断言再统一截图。${shots.length}张图，实际查看${shots.filter(s => visual[s.screenshot]).length}张，视觉通过${shots.filter(s => visual[s.screenshot]?.pass).length}张；1280×800/520×760，中英文。无新表格/抽屉或权限策略；覆盖弹窗、错误、长英文换行、关闭加载及成功会中。`, '',
    '| 截图 | 实际查看结论 |', '|---|---|', ...shots.map(s => `| [${s.screenshot}](${s.screenshot}) | ${visual[s.screenshot] ? visual[s.screenshot].notes : '未实际查看，不标视觉通过'} |`), '',
    '探测：' + JSON.stringify(r.probe) + '。页面关闭结果：' + JSON.stringify(r.cleanup) + '。数据库清理：' + (fs.existsSync(path.join(out, 'cleanup.json')) ? JSON.stringify(read('cleanup.json')) : '待完成') + '。', '',
    '错误图是显式注入的确定性状态，不是生产IM故障。业务服务区分not_started与not_found，房客未开始前不创建Room资源；房主进入后可重新加入。移动端保留后端detail。桌面兼容旧服务的404/not_found加精确“会议尚未开始”详情，契约另验证兼容分支及普通403不误判。没有新增自动等待入会。成功会中“更新服务器”横幅来自显式夹具没有提供录音能力字段，不代表真实部署版本；真实IM/RTC、桌面原生包和Android真机/模拟器本轮未重验。', '',
    '历史调试失败见[history](history/)；首次清理错误通知时被仍打开的弹窗遮罩阻挡，属于脚本清理失败，未计通过；未保存该次失败截图，保留原始结果与日志。之后通过通知按钮的DOM事件完成测试清理，功能断言仍由真实页面操作触发。', '',
    '[页面结果](results.json) · [冒烟](smoke.json) · [检查](checks.json) · [视觉](visual-reviews.json) · [清理](cleanup.json)', '']; fs.writeFileSync(path.join(out, '测试报告.md'), lines.join('\n'));
  if (process.argv.includes('--archive')) { const archive = path.join(root, 'docs/testing/archive/会议未开始提示'); fs.mkdirSync(archive, { recursive: true }); for (const name of ['results.json', 'smoke.json', 'budget.json', 'checks.json', 'visual-reviews.json', 'cleanup.json', '测试报告.md', ...checks.map(c => c.file), 'backend.xml']) if (fs.existsSync(path.join(out, name))) fs.writeFileSync(path.join(archive, name), decode(name).replace(/[\t ]+$/gm, '')); fs.cpSync(path.join(out, 'screenshots'), path.join(archive, 'screenshots'), { recursive: true }); if (fs.existsSync(path.join(out, 'history'))) fs.cpSync(path.join(out, 'history'), path.join(archive, 'history'), { recursive: true }); }
  if (process.argv.includes('--archive')) {
    const normalize = dir => { for (const entry of fs.readdirSync(dir, { withFileTypes: true })) { const file = path.join(dir, entry.name); if (entry.isDirectory()) normalize(file); else if (/\.(json|log|md|xml)$/.test(entry.name)) { const b = fs.readFileSync(file); const text = b[0] === 255 && b[1] === 254 ? b.subarray(2).toString('utf16le') : b.toString('utf8'); fs.writeFileSync(file, text.replace(/[\t ]+$/gm, '')); } } }; normalize(path.join(root, 'docs/testing/archive/会议未开始提示'));
  }
  console.log(JSON.stringify({ passed: assertions.filter(x => x.pass).length, failed: assertions.filter(x => !x.pass).length + (r.error && assertions.every(x => x.pass) ? 1 : 0), shots: shots.length, checks }));
}
if (process.argv.includes('--report') || process.argv.includes('--archive')) { report(); process.exit(0); }
const backend = await startLayoutBackend();
const control = (session, patch) => fetch(backend.base + '/control', { method: 'POST', body: JSON.stringify({ session, patch }) });
if (process.argv.includes('--smoke')) {
  const rows = [];
  try { for (const code of ['not_started', 'not_found', null]) { await control('smoke', { entryCode: code }); const r = await fetch(backend.base + '/invoke', { method: 'POST', body: JSON.stringify({ session: 'smoke', command: 'room_get_code', args: { code: '654321' } }) }); const d = await r.json(); assert.equal(r.status, code ? 404 : 200); if (code) assert.equal(d.error.code, code); rows.push({ operation: '预检查 ' + code, expected: code || 'success', actual: d.error?.code || 'success', pass: true }); }
    await control('smoke', { joinDomainCode: 'not_started' }); const r = await fetch(backend.base + '/invoke', { method: 'POST', body: JSON.stringify({ session: 'smoke', command: 'room_join' }) }); assert.equal((await r.json()).error.code, 'not_started'); rows.push({ operation: 'POST入会未开始', expected: 'not_started', actual: 'not_started', pass: true }); write('smoke.json', rows); console.log(JSON.stringify(rows));
  } finally { await backend.close(); } process.exit(0);
}
assert.equal(read('smoke.json').length, 4);
const budget = fs.existsSync(path.join(out, 'budget.json')) ? read('budget.json') : { started: Date.now(), limitMs: 1800000 }; write('budget.json', budget);
const r = { rows: [], probe: [], cleanup: {} }; let browser, next, page, phase, locale, seq = 0;
const require = createRequire(path.join(front, 'package.json')), { chromium } = require('playwright'), tc = path.join(front, 'tsconfig.json'), tcBefore = fs.readFileSync(tc);
const save = () => write('results.json', r);
async function step(operation, expected, fn, label) { const row = { operation, expected, actual: '', pass: false, phase, locale, viewport: `${page.viewportSize().width}x${page.viewportSize().height}`, screenshot: null }; r.rows.push(row);
  try { if (Date.now() - budget.started > budget.limitMs) throw Error('30分钟预算耗尽'); await fn(); assert.equal(await page.evaluate(() => document.documentElement.scrollWidth > innerWidth + 1), false); row.actual = expected; if (phase === 'screenshots') { row.screenshot = `screenshots/${String(++seq).padStart(2, '0')}-${row.viewport}-${locale}-${label}.png`; await page.screenshot({ path: path.join(out, row.screenshot), animations: 'disabled' }); } row.pass = true; }
  catch (e) { row.actual = String(e.stack || e); row.screenshot = `screenshots/failure-${Date.now()}.png`; await page.screenshot({ path: path.join(out, row.screenshot) }); throw e; } finally { save(); console.log(JSON.stringify(row)); }
}
async function flow(size) {
  const session = phase + locale + size.width, zh = locale === 'zh-CN'; await control(session, { loggedIn: false, entryCode: 'not_started', joinDomainCode: null });
  const context = await browser.newContext({ viewport: size, locale }); await context.addInitScript(installLayoutBridge, { base: backend.base, session, locale });
  await context.addInitScript(({ base, session }) => { const original = window.__TAURI_INTERNALS__.invoke; window.__TAURI_INTERNALS__.invoke = async (command, args) => { if (!['room_get_code', 'room_join'].includes(command)) return original(command, args); const data = await (await fetch(base + '/invoke', { method: 'POST', body: JSON.stringify({ session, command, args }) })).json(); if (data.error) throw data.error; return data.value; }; }, { base: backend.base, session });
  page = await context.newPage(); page.setDefaultTimeout(15000); await page.goto('http://localhost:3197'); await page.locator('#phone-auth-phone').fill('13800138000'); await page.locator('#phone-auth-password').fill('LayoutTest123!'); await page.locator('form button[type=submit]').click();
  const homeJoin = () => page.getByRole('button', { name: zh ? /加入会议.*输入会议号/ : /Join meeting.*Enter a meeting code/ }); await homeJoin().waitFor();
  const open = async () => { await homeJoin().click(); const inputs = page.getByRole('dialog').locator('input[inputmode="numeric"]'); for (let i = 0; i < 6; i++) await inputs.nth(i).fill('654321'[i]); };
  const clickJoin = () => page.getByRole('dialog').getByRole('button', { name: zh ? '加入会议' : 'Join', exact: true }).click();
  const notStarted = zh ? '会议尚未开始，请等待房主进入后重试' : 'The meeting has not started. Wait for the host to enter, then try again.';
  const notFound = zh ? '会议不存在，请检查会议号' : 'Meeting not found — check the code';
  const dismiss = async () => { const close = page.locator('[data-sonner-toast][data-removed="false"] [data-close-button]'); for (let n = 0; n < 10 && await close.count(); n++) await close.first().evaluate(el => el.click()); await page.waitForFunction(() => document.querySelectorAll('[data-sonner-toast]').length === 0); };
  try {
    await open(); await step('房主未开始', '正确提示等待房主，保留号码，可重试', async () => { await clickJoin(); await page.getByText(notStarted, { exact: true }).waitFor(); assert.equal(await page.getByText(notFound, { exact: true }).count(), 0); assert.equal((await page.getByRole('dialog').locator('input[inputmode="numeric"]').evaluateAll(xs => xs.map(x => x.value))).join(''), '654321'); assert.equal(await page.getByTestId('meeting-entry-loading').count(), 0); }, '未开始'); await dismiss();
    await control(session, { entryCode: 'not_found' }); await step('未知会议号', '仍显示号码不存在，不混淆未开始', async () => { await clickJoin(); await page.getByText(notFound, { exact: true }).waitFor(); }, '号码不存在'); await dismiss();
    await control(session, { entryCode: null, joinDomainCode: 'not_started' }); await step('预检查后场次尚未开始', 'POST失败进入错误页，仍提示等待房主', async () => { await clickJoin(); await page.waitForURL(u => u.pathname === '/room'); await page.getByText(notStarted, { exact: true }).waitFor(); assert.equal(await page.getByTestId('meeting-entry-loading').count(), 0); }, '入会错误页');
    await page.getByRole('button', { name: zh ? '返回' : 'Back', exact: true }).click(); await homeJoin().waitFor(); await control(session, { joinDomainCode: null });
    await step('开始后重新加入', '保留原有重试入口，重新加入成功', async () => { await open(); await clickJoin(); await page.getByTestId('room-recording-status').waitFor(); }, '重试成功');
  } finally { await context.close(); }
}
try {
  for (const port of [3118, 39110, 3197, 9261, 9262, 9263]) r.probe.push({ port, listening: await fetch('http://127.0.0.1:' + port, { signal: AbortSignal.timeout(800) }).then(async x => { await x.body?.cancel(); return true; }).catch(() => false) }); assert.equal(r.probe.find(x => x.port === 3197).listening, false);
  const fd = fs.openSync(path.join(out, 'next.log'), 'a'); next = spawn(process.execPath, [path.join(front, 'node_modules/next/dist/bin/next'), 'dev', '-p', '3197'], { cwd: front, env: { ...process.env, OPENMEETING_NEXT_DIST_DIR: '.next-e2e-not-started', OPENMEETING_E2E_DESKTOP_LAYOUT: '1', NEXT_PUBLIC_LIVE_MEETING_DATA_SOURCE: 'real' }, windowsHide: true, stdio: ['ignore', fd, fd] }); fs.closeSync(fd);
  const until = Date.now() + 90000; while (!await fetch('http://localhost:3197').then(async x => { await x.body?.cancel(); return x.ok; }).catch(() => false)) { if (Date.now() > until) throw Error('Next startup timeout'); await new Promise(x => setTimeout(x, 500)); }
  browser = await chromium.launch({ headless: true }); for (phase of ['assertions', 'screenshots']) for (locale of ['zh-CN', 'en']) for (const size of [{ width: 1280, height: 800 }, { width: 520, height: 760 }]) await flow(size);
} catch (e) { r.error = String(e.stack || e); console.error(e); process.exitCode = 1; }
finally { await browser?.close(); if (next) r.cleanup.nextStopped = spawnSync('taskkill.exe', ['/PID', String(next.pid), '/T', '/F'], { windowsHide: true }).status === 0; await backend.close(); fs.writeFileSync(tc, tcBefore); r.cleanup.fixtureClosed = true; r.cleanup.tsconfigRestored = true; budget.usedMs = Date.now() - budget.started; write('budget.json', budget); save(); report(); }
