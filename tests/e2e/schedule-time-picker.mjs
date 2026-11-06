import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { spawn, spawnSync } from 'node:child_process';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import { startLayoutBackend, installLayoutBridge } from './fixtures/desktop-layout-backend.mjs';

const root = fileURLToPath(new URL('../../', import.meta.url));
const front = path.join(root, 'frontend');
const out = path.resolve(root, process.env.SCHEDULE_PICKER_OUTPUT || '.artifacts/schedule-time-picker');
const archive = path.join(root, 'docs/testing/archive/会议预定时间选择');
const ui = 'http://localhost:3159';
const sizes = [{ width: 1280, height: 800 }, { width: 520, height: 760 }];
fs.mkdirSync(path.join(out, 'screenshots'), { recursive: true });
const read = file => JSON.parse(fs.readFileSync(path.join(out, file), 'utf8'));
const write = (file, data) => fs.writeFileSync(path.join(out, file), JSON.stringify(data, null, 2));
const pause = ms => new Promise(resolve => setTimeout(resolve, ms));

function report(base = out) {
  const r = read('results.json');
  const reviews = fs.existsSync(path.join(out, 'visual-reviews.json')) ? read('visual-reviews.json') : {};
  const checks = fs.existsSync(path.join(out, 'checks.json')) ? read('checks.json') : [];
  const rows = r.steps.filter(s => s.phase === 'assertions');
  const images = r.steps.filter(s => s.screenshot);
  const history = fs.existsSync(path.join(out, 'history')) ? fs.readdirSync(path.join(out, 'history')) : [];
  const historyAnalysis = fs.existsSync(path.join(out, 'history-analysis.json')) ? read('history-analysis.json') : {};
  const historicalFailures = history.flatMap(name => JSON.parse(fs.readFileSync(path.join(out, 'history', name, 'results.json'), 'utf8')).steps.filter(s => !s.pass).map(s => ({ ...s, name })));
  const link = target => path.relative(base, path.join(root, target)).replaceAll('\\', '/');
  const md = value => String(value).replaceAll('|', '/').replaceAll('\n', ' ');
  const lines = [
    '# 会议预定日期与时间选择测试报告', '',
    '分级：局部表单组件调整，执行受影响日期/时间交互与登录→创建预定→失败恢复→修改预定的成功冒烟。真实 Next 开发页面与生产组件使用项目已有显式 HTTP/IPC/IM/RTC 测试夹具；不代表真实后端、原生三端或 IM/RTC 验收。无 in-app browser，使用 Playwright 无头 Chromium。', '',
    `最终功能断言：${rows.filter(s => s.pass).length} 通过、${rows.filter(s => !s.pass).length} 失败。截图阶段复核：${r.steps.filter(s => s.phase === 'screenshots' && s.pass).length} 通过。代码检查：${checks.filter(s => s.pass).length} 通过、${checks.filter(s => !s.pass).length} 失败。`, '',
    ...(r.error ? ['运行错误（不得计为通过）：' + md(r.error), ''] : []),
    `本轮开始 ${r.started}；累计 E2E 调试预算 30 分钟，不重置。固定浏览器本地时间 2026-10-26 15:30（Asia/Shanghai），保证过去日期与未来预定稳定。`, '',
    '启动方式：先运行 `node tests/e2e/schedule-time-picker.mjs --smoke` 单独验证预定失败/延迟/恢复与修改夹具；再运行无参数同一脚本，自动启动隔离 Next :3159（OPENMEETING_NEXT_DIST_DIR=.next-e2e-schedule、OPENMEETING_E2E_DESKTOP_LAYOUT=1）及随机回环 HTTP 夹具。`--checks` 执行 TypeScript。', '',
    '已有环境：' + JSON.stringify(r.probe) + '。保留日常 3118/39110 与原生客户端；既有 CDP 未开放时不读取或更改登录态，使用独立夹具会话登录。', '',
    '| 阶段/视口 | 操作 | 预期 | 实际 | 结果 | 截图 |', '|---|---|---|---|---|---|',
    ...r.steps.map(s => `| ${s.phase}/${s.viewport} | ${s.operation} | ${s.expected} | ${md(s.actual)} | ${s.pass ? '通过' : '失败'} | ${s.screenshot ? `[截图](${s.screenshot})` : '—'} |`), '',
    `最终截图 ${images.length} 张，实际查看 ${images.filter(s => reviews[s.screenshot]).length} 张，视觉通过 ${images.filter(s => reviews[s.screenshot]?.pass).length} 张。未查看的不标记为通过。`, '',
    '| 截图 | 实际视觉检查 |', '|---|---|',
    ...images.map(s => `| [${path.basename(s.screenshot)}](${s.screenshot}) | ${reviews[s.screenshot] ? `${reviews[s.screenshot].pass ? '通过' : '未通过'}：${reviews[s.screenshot].notes}` : '待实际查看'} |`), '',
    '| 独立代码检查 | 预期 | 实际 | 结果 |', '|---|---|---|---|',
    ...checks.map(s => `| ${s.operation} | ${s.expected} | ${s.actual} | ${s.pass ? '通过' : '失败'} |`), '',
    '[夹具冒烟](smoke.json) · [原始结果](results.json) · [检查结果](checks.json) · [逐图记录](visual-reviews.json)', '',
    ...history.map(name => `历史尝试（含实际失败及截图，不并入最终通过数）：[${name}](history/${name}/results.json)`), '',
    `历史调试失败 ${historicalFailures.length} 项，保留失败结论与对应截图：`, '',
    '| 操作 | 原因 | 修复/重跑 | 失败截图 |', '|---|---|---|---|',
    ...historicalFailures.map(s => `| ${s.operation} | ${md(historyAnalysis[s.name]?.cause || s.actual.split('\n')[0])} | ${md(historyAnalysis[s.name]?.resolution || '未记录，不能推断通过')} | ${s.screenshot ? `[失败截图](history/${s.name}/${s.screenshot})` : '无截图'} |`), '',
    '清理：' + JSON.stringify(r.cleanup) + '。隔离开发缓存保留，未删除已有构建缓存。', '',
    '边界与风险：本轮不验收真实业务网络、IM/RTC、系统通知、系统时区切换、夏令时跳变或所有平台/DPI；日期与 ISO 传输验证基于 Asia/Shanghai。历史已有英文编辑标题等未翻译文案不在本次时间控件范围。本轮没有新增表格或权限接口；禁选过去日期、空时间、非法值、列表空选与保存错误按实际路径验证。', '',
    `[开发文档](${link('docs/development/schedule-time-picker.md')}) · [E2E 脚本](${link('tests/e2e/schedule-time-picker.mjs')})`, '',
  ];
  fs.writeFileSync(path.join(base, '测试报告.md'), lines.join('\n'));
  if (base === archive) {
    for (const name of ['results.json', 'smoke.json', 'checks.json', 'visual-reviews.json', 'history-analysis.json', 'budget.json', 'check-typescript.txt']) {
      if (fs.existsSync(path.join(out, name))) fs.copyFileSync(path.join(out, name), path.join(base, name));
    }
    for (const name of ['screenshots', 'history']) if (fs.existsSync(path.join(out, name))) fs.cpSync(path.join(out, name), path.join(base, name), { recursive: true });
  }
  console.log(JSON.stringify({ report: path.join(base, '测试报告.md'), assertionsPassed: rows.filter(s => s.pass).length, failed: rows.filter(s => !s.pass).length, error: r.error || null, screenshots: images.length }));
}
if (process.argv.includes('--report') || process.argv.includes('--archive')) {
  const base = process.argv.includes('--archive') ? archive : out;
  fs.mkdirSync(base, { recursive: true }); report(base); process.exit(0);
}
if (process.argv.includes('--checks')) {
  const result = spawnSync(process.execPath, ['node_modules/typescript/bin/tsc', '--noEmit'], { cwd: front, encoding: 'utf8', windowsHide: true });
  fs.writeFileSync(path.join(out, 'check-typescript.txt'), (result.stdout || '') + (result.stderr || ''));
  write('checks.json', [{ operation: 'TypeScript', expected: 'exit 0', actual: result.status, pass: result.status === 0 }]);
  console.log(JSON.stringify(read('checks.json'))); process.exit(result.status === 0 ? 0 : 1);
}

const backend = await startLayoutBackend();
async function control(session, patch = {}) {
  const response = await fetch(backend.base + '/control', { method: 'POST', body: JSON.stringify({ session, patch }) });
  assert.equal(response.status, 200); return response.json();
}
async function rpc(session, command, args = {}) {
  const response = await fetch(backend.base + '/invoke', { method: 'POST', body: JSON.stringify({ session, command, args }) });
  return { status: response.status, body: await response.json() };
}
if (process.argv.includes('--smoke')) {
  const steps = [];
  try {
    const input = { title: 'fixture smoke', startAt: '2026-10-26T08:07:00.000Z', durationMin: 60, remind: false };
    await control('smoke', { scheduleError: true });
    assert.equal((await rpc('smoke', 'sched_create', input)).status, 503);
    steps.push({ operation: 'create failure', expected: 503, actual: 503, pass: true, screenshot: null });
    await control('smoke', { scheduleError: false, delay: 180 });
    const tick = Date.now(); const created = await rpc('smoke', 'sched_create', input);
    assert.equal(created.status, 200); assert.ok(Date.now() - tick >= 170); assert.equal(created.body.value.startAt, input.startAt); assert.ok(created.body.value.host.name);
    steps.push({ operation: 'delayed create recovery with timestamp and host', expected: '200 after >=170ms', actual: created.status, pass: true, screenshot: null });
    await control('smoke', { scheduleError: true, delay: 0 });
    assert.equal((await rpc('smoke', 'sched_update', { id: 'schedule-layout' })).status, 503);
    steps.push({ operation: 'update failure', expected: 503, actual: 503, pass: true, screenshot: null });
    await control('smoke', { scheduleError: false });
    assert.equal((await rpc('smoke', 'sched_update', { id: 'schedule-layout', startAt: '2026-10-26T09:42:00.000Z' })).status, 200);
    assert.equal((await control('smoke')).scheduled[0].startAt, '2026-10-26T09:42:00.000Z');
    steps.push({ operation: 'update recovery persists', expected: '200 and saved time', actual: '200 and persisted', pass: true, screenshot: null });
    write('smoke.json', steps); console.log(JSON.stringify(steps));
  } finally { await backend.close(); }
  process.exit(0);
}

assert.ok(read('smoke.json').every(s => s.pass), 'Run --smoke before browser E2E');
if (fs.existsSync(path.join(out, 'results.json'))) {
  const history = path.join(out, 'history', String(Date.now())); fs.mkdirSync(history, { recursive: true });
  fs.copyFileSync(path.join(out, 'results.json'), path.join(history, 'results.json'));
  fs.cpSync(path.join(out, 'screenshots'), path.join(history, 'screenshots'), { recursive: true });
  if (fs.existsSync(path.join(out, 'visual-reviews.json'))) fs.renameSync(path.join(out, 'visual-reviews.json'), path.join(history, 'visual-reviews.json'));
}
const budget = fs.existsSync(path.join(out, 'budget.json')) ? read('budget.json') : { started: Date.now(), limitMs: 30 * 60_000 };
write('budget.json', budget);
const r = { started: new Date().toISOString(), steps: [], probe: [], cleanup: {} };
const save = () => write('results.json', r);
const require = createRequire(path.join(front, 'package.json'));
const { chromium } = require('playwright');
const tsconfig = path.join(front, 'tsconfig.json'), tsconfigBefore = fs.readFileSync(tsconfig);
let next, browser, page, phase = 'assertions', sequence = 0;
async function step(operation, expected, action, shot) {
  if (Date.now() - budget.started > budget.limitMs) throw Error('30 minute E2E budget exhausted; use API verification');
  const row = { phase, viewport: `${page.viewportSize().width}x${page.viewportSize().height}`, operation, expected, actual: '', pass: false, screenshot: null };
  r.steps.push(row);
  try {
    row.actual = await action() || '符合预期';
    if (phase === 'screenshots' && shot) {
      row.screenshot = `screenshots/${String(++sequence).padStart(2, '0')}-${row.viewport}-${shot}.png`;
      await page.screenshot({ path: path.join(out, row.screenshot), animations: 'disabled' });
    }
    row.pass = true;
  } catch (error) {
    row.actual = String(error.stack || error); row.screenshot = `screenshots/failure-${Date.now()}-${row.viewport}.png`;
    await page.screenshot({ path: path.join(out, row.screenshot) }).catch(() => {}); throw error;
  } finally { save(); console.log(JSON.stringify(row)); }
}
async function layout() {
  const issues = await page.evaluate(() => {
    const issues = [];
    if (document.documentElement.scrollWidth > innerWidth + 1) issues.push('document overflow');
    for (const el of document.querySelectorAll('[role=dialog], [data-testid=schedule-date-time]')) {
      if (!el.getClientRects().length) continue;
      const b = el.getBoundingClientRect();
      if (b.left < -1 || b.right > innerWidth + 1 || (el.getAttribute('role') === 'dialog' && (b.top < -1 || b.bottom > innerHeight + 1))) issues.push('dialog/control outside viewport');
      if (el.scrollWidth > el.clientWidth + 1) issues.push('control horizontal overflow');
    }
    return issues;
  }); assert.deepEqual(issues, []); return '无横向溢出，弹层位于视口内';
}
async function dismissToasts() {
  const close = page.locator('[data-sonner-toast][data-removed="false"] [data-close-button]');
  for (let i = 0; i < 10 && await close.count(); i++) await close.first().click();
  await page.waitForFunction(() => document.querySelectorAll('[data-sonner-toast]').length === 0);
}
async function flow(size, locale = 'zh-CN') {
  const session = `${phase}-${size.width}-${locale}`;
  await control(session, { loggedIn: false, scheduled: [], scheduleError: false, delay: 0 });
  const context = await browser.newContext({ viewport: size, locale, timezoneId: 'Asia/Shanghai' });
  await context.addInitScript(installLayoutBridge, { base: backend.base, session, locale });
  page = await context.newPage(); page.setDefaultTimeout(12_000);
  await page.clock.setFixedTime(new Date('2026-10-26T07:30:00.000Z'));
  const errors = []; page.on('pageerror', error => errors.push(error.message));
  const hour = () => page.getByRole('textbox', { name: locale === 'en' ? 'Hour' : '小时', exact: true });
  const minute = () => page.getByRole('textbox', { name: locale === 'en' ? 'Minute' : '分钟', exact: true });
  const date = () => page.getByTestId('schedule-date');
  const timeButton = () => page.getByRole('button', { name: locale === 'en' ? 'Choose time' : '选择时间', exact: true });
  const dialog = () => page.getByRole('dialog', { name: locale === 'en' ? 'Schedule meeting' : '预定会议', exact: true });
  const submit = () => page.locator('form button[type=submit]');
  try {
    await step('登录并打开预定表单', '独立日期与时间，冒号不可编辑，今日为空态', async () => {
      await page.goto(ui, { waitUntil: 'domcontentloaded' });
      await page.locator('#phone-auth-phone').fill('13800138000'); await page.locator('#phone-auth-password').fill('LayoutTest123!'); await submit().click();
      await page.getByRole('button', { name: locale === 'en' ? /Schedule.*upcoming/ : /预定会议.*未来/ }).waitFor();
      await dismissToasts();
      await page.getByRole('button', { name: locale === 'en' ? /Schedule.*upcoming/ : /预定会议.*未来/ }).click();
      await hour().waitFor(); assert.equal(await hour().inputValue(), '16'); assert.equal(await minute().inputValue(), '30');
      assert.equal(await page.getByTestId('schedule-time-colon').textContent(), ':');
      assert.equal(await hour().getAttribute('maxlength'), '2'); assert.equal(await minute().getAttribute('maxlength'), '2');
      return layout();
    }, locale === 'en' ? '英文预定表单' : '预定表单');
    if (locale === 'en') {
      await step('英文日历与校验', '新增日期、时间、错误文案均为英文', async () => {
        await date().click(); await page.getByRole('button', { name: 'Next month', exact: true }).click(); await page.getByTestId('schedule-calendar').getByRole('button', { name: 'Tomorrow', exact: true }).click();
        await hour().fill('99'); await minute().fill('88'); await page.getByRole('alert').filter({ hasText: 'Enter hours 00–23 and minutes 00–59' }).waitFor();
        assert.ok(await submit().isDisabled()); return layout();
      }, '英文时间错误');
      assert.deepEqual(errors, []); return;
    }
    await page.locator('#sched-title').fill('预定时间控件验收会议');
    await step('月历打开与过去日期禁选', '日历独立显示，昨天不可选，当前日可选', async () => {
      await date().click(); const calendar = page.getByTestId('schedule-calendar'); await calendar.waitFor();
      assert.ok(await calendar.locator('[data-date="2026-10-25"]').isDisabled());
      assert.ok(await calendar.locator('[data-date="2026-10-26"]').isEnabled()); return layout();
    }, '日历与禁选日期');
    await step('月份切换', '下一月十一月，再上一月回十月，时间不变', async () => {
      await page.getByRole('button', { name: '下一月', exact: true }).click(); await page.getByText('2026年11月', { exact: true }).waitFor();
      await page.getByRole('button', { name: '上一月', exact: true }).click(); await page.getByText('2026年10月', { exact: true }).waitFor();
      await page.getByRole('button', { name: '下一月', exact: true }).click(); return layout();
    }, '日历跨月');
    await step('选择日期自动关闭', '十一月一日生效，保留16:30', async () => {
      await page.getByTestId('schedule-calendar').locator('[data-date="2026-11-01"]').click(); await page.getByTestId('schedule-calendar').waitFor({ state: 'hidden' });
      assert.match(await date().textContent(), /2026\/11\/01/); assert.equal(await hour().inputValue(), '16'); assert.equal(await minute().inputValue(), '30'); return layout();
    }, '日期已选择');
    await step('时间列表定位当前值', '15分钟间隔，当前16:30可见', async () => {
      await timeButton().click(); const list = page.getByTestId('schedule-time-options'); await list.waitFor();
      const option = list.getByRole('option', { name: '16:30', exact: true }); assert.equal(await option.getAttribute('aria-selected'), 'true');
      await page.waitForFunction(() => { const list = document.querySelector('[data-testid=schedule-time-options]'), option = list?.querySelector('[aria-selected=true]'); return option && option.getBoundingClientRect().top >= list.getBoundingClientRect().top && option.getBoundingClientRect().bottom <= list.getBoundingClientRect().bottom; });
      assert.equal(await list.getByRole('option').count(), 96); return layout();
    }, '时间列表');
    await step('时间列表真实滚动', '鼠标滚动至末端，23:45可见', async () => {
      const list = page.getByTestId('schedule-time-options'); const before = await list.evaluate(el => el.scrollTop);
      await list.hover(); await page.mouse.wheel(0, 3000);
      await page.waitForFunction(before => document.querySelector('[data-testid=schedule-time-options]').scrollTop > before, before);
      assert.ok(await list.getByRole('option', { name: '23:45', exact: true }).isVisible()); return layout();
    }, '时间列表滚动');
    await step('时间选择与键盘边界', '选中23:45关闭列表，Home/End/Enter可选择，日期保持', async () => {
      await page.getByRole('option', { name: '23:45', exact: true }).click(); await page.getByTestId('schedule-time-options').waitFor({ state: 'hidden' });
      assert.equal(await hour().inputValue(), '23'); assert.equal(await minute().inputValue(), '45');
      await timeButton().click(); const list = page.getByTestId('schedule-time-options'); await list.press('Home'); await list.press('ArrowDown'); await list.press('ArrowUp'); await list.press('End'); await list.press('Enter');
      assert.equal(await minute().inputValue(), '45'); assert.match(await date().textContent(), /2026\/11\/01/); return '23:45，日期保持十一月一日';
    });
    await step('手动输入与两位限制', '小时分钟各最多两位，冒号固定，9:7补零为09:07，Enter不保存', async () => {
      await hour().fill('123'); assert.equal((await hour().inputValue()).length, 2);
      await hour().fill('9'); await hour().press(':'); assert.ok(await minute().evaluate(el => el === document.activeElement));
      await minute().fill('7'); await minute().press('Enter'); assert.equal(await hour().inputValue(), '09'); assert.equal(await minute().inputValue(), '07');
      assert.equal((await control(session)).scheduled.length, 0); assert.equal(await page.getByTestId('schedule-time-colon').textContent(), ':'); return layout();
    }, '自定义时间补零');
    await step('自定义分钟回显与Escape关闭', '09:07加入选中项；Escape仅关闭时间列表', async () => {
      await timeButton().click(); const option = page.getByRole('option', { name: '09:07', exact: true }); assert.equal(await option.getAttribute('aria-selected'), 'true');
      await page.getByTestId('schedule-time-options').press('Escape'); await page.getByTestId('schedule-time-options').waitFor({ state: 'hidden' }); await hour().waitFor(); return '自定义分钟精确保留，预定弹窗仍打开';
    });
    await step('非法时间阻止保存', '99:88显示范围错误，保存禁用，没有创建请求', async () => {
      const count = backend.calls.filter(c => c.session === session && c.command === 'sched_create').length;
      await hour().fill('99'); await minute().fill('88'); await minute().press('Enter'); await page.getByRole('alert').filter({ hasText: '小时请输入' }).waitFor();
      assert.ok(await submit().isDisabled()); assert.equal(backend.calls.filter(c => c.session === session && c.command === 'sched_create').length, count); return layout();
    }, '非法时间');
    await step('空值与范围边界恢复', '空时间不可保存；00:00和23:59有效，恢复16:07并选择今天', async () => {
      await hour().fill(''); assert.ok(await submit().isDisabled());
      await hour().fill('00'); await minute().fill('00'); await minute().press('Enter'); assert.ok(await submit().isEnabled());
      await hour().fill('23'); await minute().fill('59'); await minute().press('Enter'); assert.ok(await submit().isEnabled());
      await hour().fill('16'); await minute().fill('7'); await minute().press('Enter');
      await date().click(); await page.getByTestId('schedule-calendar').getByRole('button', { name: '今天', exact: true }).click();
      assert.equal(await minute().inputValue(), '07'); assert.match(await date().textContent(), /2026\/10\/26/); return '16:07，空值和边界已验证';
    });
    await step('保存加载态', '异步保存期间禁用按钮及日期时间输入', async () => {
      await control(session, { scheduleError: true, delay: 1500 }); await submit().click(); await page.getByRole('button', { name: '正在保存…', exact: true }).waitFor();
      assert.ok(await hour().isDisabled()); assert.ok(await date().isDisabled()); return layout();
    }, '保存加载');
    await step('保存错误保留输入并滚动', '长错误可阅读，标题与16:07保持，可滚动到重试按钮', async () => {
      await page.getByRole('alert').filter({ hasText: '预定服务暂不可用' }).waitFor();
      assert.equal(await page.locator('#sched-title').inputValue(), '预定时间控件验收会议'); assert.equal(await hour().inputValue(), '16'); assert.equal(await minute().inputValue(), '07');
      const formDialog = dialog(); await formDialog.evaluate(el => el.scrollTop = el.scrollHeight); assert.ok(await formDialog.evaluate(el => el.scrollTop > 0)); return layout();
    }, '保存失败保留输入');
    await step('恢复重试成功', '弹窗关闭，首页出现预定，ISO精确到分钟', async () => {
      await control(session, { scheduleError: false, delay: 0 }); await submit().click(); await hour().waitFor({ state: 'hidden' });
      await page.getByTestId('desktop-content').getByText('预定时间控件验收会议', { exact: true }).waitFor(); await dismissToasts();
      const saved = (await control(session)).scheduled[0]; assert.equal(saved.startAt, '2026-10-26T08:07:00.000Z'); assert.equal(saved.durationMin, 60); return layout();
    }, '预定成功');
    await step('编辑预定复用输入', '16:07回填，修改成17:42', async () => {
      await page.getByRole('button', { name: '修改 预定时间控件验收会议', exact: true }).click(); assert.equal(await hour().inputValue(), '16'); assert.equal(await minute().inputValue(), '07');
      await hour().fill('17'); await minute().fill('42'); await minute().press('Enter'); return layout();
    }, '修改预定时间');
    await step('编辑保存与再次回填', '修改请求持久化17:42，再打开仍显示17:42，取消可关闭', async () => {
      await submit().click(); await hour().waitFor({ state: 'hidden' }); assert.equal((await control(session)).scheduled[0].startAt, '2026-10-26T09:42:00.000Z');
      await dismissToasts(); await page.getByRole('button', { name: '修改 预定时间控件验收会议', exact: true }).click();
      assert.equal(await hour().inputValue(), '17'); assert.equal(await minute().inputValue(), '42');
      await page.getByRole('button', { name: '取消', exact: true }).click(); await hour().waitFor({ state: 'hidden' }); return layout();
    }, '修改成功与弹窗关闭');
    await step('新建重置与日历取消', '重新新建恢复16:30，Escape关闭日历不修改日期，取消关闭弹窗', async () => {
      await page.getByRole('button', { name: /预定会议.*未来/ }).click(); assert.equal(await hour().inputValue(), '16'); assert.equal(await minute().inputValue(), '30');
      const before = await date().textContent(); await date().click(); await page.getByTestId('schedule-calendar').press('Escape'); await page.getByTestId('schedule-calendar').waitFor({ state: 'hidden' }); assert.equal(await date().textContent(), before);
      await page.getByRole('button', { name: '取消', exact: true }).click(); await hour().waitFor({ state: 'hidden' }); assert.deepEqual(errors, []); return '表单重置、Escape及关闭成功，无pageerror';
    });
  } finally { await context.close(); }
}

try {
  for (const port of [3118, 39110, 3159, 9222, 9261, 9262, 9263]) {
    const probe = await fetch(`http://127.0.0.1:${port}${port >= 9000 && port < 10000 ? '/json/version' : '/'}`, { signal: AbortSignal.timeout(1000) })
      .then(async response => { await response.body?.cancel(); return { port, listening: true, status: response.status }; }).catch(() => ({ port, listening: false }));
    r.probe.push(probe);
  }
  assert.equal(r.probe.find(p => p.port === 3159).listening, false, 'Preserve existing port 3159');
  const fd = fs.openSync(path.join(out, 'next.log'), 'a');
  next = spawn(process.execPath, [path.join(front, 'node_modules/next/dist/bin/next'), 'dev', '-p', '3159'], {
    cwd: front, env: { ...process.env, OPENMEETING_NEXT_DIST_DIR: '.next-e2e-schedule', OPENMEETING_E2E_DESKTOP_LAYOUT: '1', NEXT_PUBLIC_LIVE_MEETING_DATA_SOURCE: 'real' }, windowsHide: true, stdio: ['ignore', fd, fd],
  }); fs.closeSync(fd);
  const until = Date.now() + 90000;
  while (!await fetch(ui).then(async response => { await response.body?.cancel(); return response.ok; }).catch(() => false)) {
    if (Date.now() > until) throw Error('Next startup timed out'); await pause(500);
  }
  browser = await chromium.launch({ headless: true });
  for (phase of ['assertions', 'screenshots']) {
    for (const size of sizes) await flow(size);
    await flow(sizes[1], 'en');
  }
} catch (error) { r.error = String(error.stack || error); process.exitCode = 1; console.error(error); }
finally {
  await browser?.close(); r.cleanup.browserClosed = true;
  if (next) r.cleanup.nextStopped = spawnSync('taskkill.exe', ['/PID', String(next.pid), '/T', '/F'], { windowsHide: true }).status === 0;
  await backend.close(); r.cleanup.fixtureClosed = true;
  r.cleanup.nextPortClosed = await fetch(ui, { signal: AbortSignal.timeout(1000) }).then(() => false).catch(() => true);
  if (!next || r.cleanup.nextPortClosed) { fs.writeFileSync(tsconfig, tsconfigBefore); r.cleanup.tsconfigRestored = fs.readFileSync(tsconfig).equals(tsconfigBefore); }
  for (const port of [3118, 39110]) r.cleanup[`daily${port}Listening`] = await fetch(`http://127.0.0.1:${port}/`, { signal: AbortSignal.timeout(1000) }).then(async response => { await response.body?.cancel(); return true; }).catch(() => false);
  budget.usedMs = Date.now() - budget.started; write('budget.json', budget); save(); report();
}
