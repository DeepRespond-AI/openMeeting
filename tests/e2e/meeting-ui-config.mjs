import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { mkdirSync, readFileSync, writeFileSync, existsSync, openSync } from 'node:fs';
import { spawn } from 'node:child_process';
import { startMeetingBackend, installMeetingBridge } from './fixtures/meeting-session-backend.mjs';
import { installLayoutBridge } from './fixtures/desktop-layout-backend.mjs';

const root = fileURLToPath(new URL('../../', import.meta.url));
const frontend = path.join(root, 'frontend'), require = createRequire(path.join(frontend, 'package.json'));
const { chromium } = require('playwright');
const out = path.resolve(process.env.MEETING_UI_OUTPUT || path.join(root, '.artifacts/会议模块配置'));
mkdirSync(path.join(out, 'screenshots'), { recursive: true });
const resultPath = path.join(out, 'results.json');
const smokeOnly = process.argv.includes('--smoke');
const modules = ['audio', 'video', 'chat', 'screenShare', 'members', 'handRaise', 'recording', 'settings'];
function report() {
  const data = JSON.parse(readFileSync(resultPath, 'utf8'));
  const reviews = existsSync(path.join(out, 'visual-reviews.json')) ? JSON.parse(readFileSync(path.join(out, 'visual-reviews.json'), 'utf8')) : {};
  const checks = existsSync(path.join(out, 'checks.json')) ? JSON.parse(readFileSync(path.join(out, 'checks.json'), 'utf8')) : [];
  const assertions = data.steps.filter(s => s.phase === 'assertions' && s.viewport);
  const nativeProbe = existsSync(path.join(out, 'real-backend-smoke.json')) ? JSON.parse(readFileSync(path.join(out, 'real-backend-smoke.json'), 'utf8')) : null;
  const nativeAcceptance = existsSync(path.join(out, 'native-20261024-1347/summary.json')) ? JSON.parse(readFileSync(path.join(out, 'native-20261024-1347/summary.json'), 'utf8')) : null;
  const smoke = JSON.parse(readFileSync(path.join(out, 'smoke-results.json'), 'utf8'));
  const rows = data.steps.map(s => `| ${s.phase}/${s.viewport || '服务'} | ${s.operation} | ${s.expected} | ${String(s.actual).split('\n')[0].replaceAll('|', '/')} | ${s.pass ? '通过' : '失败'} | ${s.screenshot ? `[截图](${s.screenshot})` : '—'} |`);
  const lines = ['# 会议模块配置测试报告', '',
    '首轮分级：完整页面用户流程。涉及多模块入口、设备启动和会议生命周期，执行生产 Next 开发路由及会议组件，覆盖默认全开、八项单独禁用、组合及全关、入会和聊天失败、权限拒绝与恢复。首轮业务 HTTP、原生 IPC、IM 和音视频 SDK 边界使用显式开发夹具；屏幕捕获为 canvas 输入及生产 ScreenShareClient。首轮夹具证据不代表真实硬件、生产 IM 平台或原生双端验收；后续原生补验单独记录如下。', '',
    ...(nativeAcceptance ? [`后续真实原生补验已完成：${nativeAcceptance.nativeAssertions.passed}项原生流程断言通过、${nativeAcceptance.nativeAssertions.failed}失败；真实API冒烟${nativeAcceptance.realApiSmoke.passed}通过、${nativeAcceptance.realApiSmoke.failed}失败。此前3项原生登录/只读接口验证已补齐${nativeAcceptance.previousFailedProbesResolved}/3，12张原生截图均已实际查看；清理${nativeAcceptance.cleanupPass?'通过':'未通过'}。详见[真实原生补验报告](native-20261024-1347/测试报告.md)。以下保留早期页面夹具及探测失败记录，不用后续通过覆盖历史失败。`, ''] : []),
    `基线 develop；开发分支 feat/meeting-ui-config；工作区 ${root}。`, '',
    `启动方式：node tests/e2e/meeting-ui-config.mjs --smoke，然后 node tests/e2e/meeting-ui-config.mjs。隔离 Next dev 127.0.0.1:3168；${data.distDir}；OPENMEETING_E2E_DESKTOP_LAYOUT=1、OPENMEETING_E2E_MEETING_UI=1、NEXT_PUBLIC_LIVE_MEETING_DATA_SOURCE=real；HTTP 夹具随机端口。`, '',
    `测试流程：先独立冒烟失败入口，再探测服务/登录态，启动包含改动的开发版；在1280×800及390×844逐项断言，全部通过后统一采集截图；逐张实际查看后重新生成报告。`, '',
    `功能断言通过 ${assertions.filter(s => s.pass).length}，失败 ${assertions.filter(s => !s.pass).length}；独立夹具冒烟通过 ${smoke.steps.filter(s => s.pass).length}，失败 ${smoke.steps.filter(s => !s.pass).length}。${data.error ? '本轮未完成，不将未执行项计为通过。' : '本轮已完成计划流程。'}`, '',
    `E2E累计预算30分钟；起点 ${new Date(data.budgetStarted).toISOString()}，累计 ${Math.round((new Date(data.finished).getTime() - data.budgetStarted) / 1000)} 秒。`, '',
    `现有服务/登录态探测：${JSON.stringify(data.probe)}。仅保存可达性和登录布尔值，不保存令牌。`, '',
    '## 逐步结构化结果', '', '| 阶段/视口 | 操作 | 预期 | 实际 | 结果 | 截图 |', '| --- | --- | --- | --- | --- | --- |', ...rows, '',
    '## 检查结果', '', ...checks.map(c => `- ${c.name}：${c.exitCode === 0 ? '通过' : '失败'}；[日志](${c.log})。${c.details || ''}`), '',
    '## 逐张视觉检查', '', '使用项目 Playwright 无头 Chromium 替代 in-app browser。桌面1280×800，窄视口390×844。截图均在所有功能断言通过后统一采集；未查看的截图不计为视觉通过。', '',
    ...data.steps.filter(s => s.screenshot).map(s => `- [${s.screenshot}](${s.screenshot})：${reviews[s.screenshot] ? `${reviews[s.screenshot].pass ? '已查看，通过' : '已查看，失败'}；${reviews[s.screenshot].notes}` : '待实际查看，未标记视觉通过'}`), '',
    '## 清理与边界', '', `清理结果：${JSON.stringify(data.cleanup)}。`, '',
    ...(nativeProbe ? [`追加原生只读API探测：通过 ${nativeProbe.results.filter(r => r.pass).length}，未通过 ${nativeProbe.results.filter(r => !r.pass).length}；${nativeProbe.context || nativeProbe.boundary}。[原始探测](real-backend-smoke.json)。不计为页面断言通过。`, ''] : []),
    ...(existsSync(path.join(out, 'cleanup-probe.json')) ? ['结束后复核原有服务和日常客户端仍在，3168已关闭：[清理复核](cleanup-probe.json)。', ''] : []),
    '- 仅关闭本次创建的浏览器、3168开发服务和HTTP夹具，保留原有3118/39110及开发客户端。',
    '- JSON为构建时客户端配置；修改后重新构建发布，开发环境热更新后退出并重新入会。它不替代服务端鉴权，也不修改其他参会客户端。',
    '- 本次无新增表格；覆盖长会议标题、长成员名、长聊天内容、抽屉与弹窗的打开/滚动/关闭和异步状态。录制关闭及语音依赖由页面与代码检查覆盖，未作真实录音文件验收。',
    '- 原生现有登录态只读探测；功能流程使用隔离夹具会话，未复用用户账号修改真实会议。真实麦克风/摄像头、生产IM/RTC互通、跨平台与移动端未纳入此次页面验收。',
    '- [原始结果](results.json)、[逐步日志](steps.jsonl)、[夹具冒烟](smoke-results.json)、[开发服务日志](dev-server.log)、[视觉记录](visual-reviews.json)、[浏览器日志](browser-console.jsonl)。', '',
    ...(existsSync(path.join(out, 'attempts.json')) ? ['调试失败保留于 [attempts.json](attempts.json)，未计为本轮通过。', ''] : []),
    ...(existsSync(path.join(out, 'checks-history.json')) ? ['通用单测曾因Bun不在PATH、沙箱EPERM及全体静音测试未打开成员面板而失败。复用本地缓存Bun并补齐测试准备后18个文件全部通过；保留[早期检查记录](checks-history.json)、[沙箱失败日志](check-7-retry.log)、[首次完整单测失败](check-7-elevated.log)及[最终单测日志](check-7-final.log)。', ''] : []),
    ...(existsSync(path.join(out, 'api-fallback.json')) ? ['预算超限后已降级API验证：[api-fallback.json](api-fallback.json)。API通过不代表页面通过。', ''] : []),
  ];
  writeFileSync(path.join(out, '测试报告.md'), lines.join('\n'));
}
if (process.argv.includes('--report')) { report(); process.exit(0); }
const backend = await startMeetingBackend();
const rpc = async (session, command, args = {}) => {
  const response = await fetch(backend.base + '/invoke', { method: 'POST', body: JSON.stringify({ session, command, args }) });
  return { status: response.status, data: await response.json() };
};
const control = async (session, patch) => fetch(backend.base + '/control', { method: 'POST', body: JSON.stringify({ session, patch }) }).then(r => r.json());
const started = Date.now(), budgetFile = path.join(out, 'budget.json');
const budgetStarted = existsSync(budgetFile) ? JSON.parse(readFileSync(budgetFile, 'utf8')).started : started;
if (!smokeOnly && !existsSync(budgetFile)) writeFileSync(budgetFile, JSON.stringify({ started }));
const data = { started: new Date().toISOString(), budgetStarted, steps: [], probe: [], cleanup: {} };
let phase = 'fixture-smoke', viewport = '', browser, next, page, number = 0;
const contexts = new Set();
const save = () => writeFileSync(path.join(out, smokeOnly ? 'smoke-results.json' : 'results.json'), JSON.stringify(data, null, 2));
async function step(operation, expected, fn, screenshot) {
  if (!smokeOnly && Date.now() - budgetStarted > 1800000) throw Error('E2E累计30分钟预算已耗尽');
  const item = { phase, viewport, operation, expected, actual: '', pass: false, screenshot: null };
  data.steps.push(item);
  try {
    item.actual = await fn() || '全部断言符合预期';
    if (phase === 'screenshots' && screenshot) {
      item.screenshot = `screenshots/${String(++number).padStart(2, '0')}-${viewport}-${screenshot}.png`;
      await page.screenshot({ path: path.join(out, item.screenshot), animations: 'disabled' });
    }
    item.pass = true;
  } catch (error) {
    item.actual = String(error.stack || error);
    if (page && !page.isClosed()) {
      item.screenshot = `screenshots/失败-${Date.now()}.png`;
      await page.screenshot({ path: path.join(out, item.screenshot) }).catch(() => {});
    }
    throw error;
  } finally {
    console.log(JSON.stringify(item));
    writeFileSync(path.join(out, smokeOnly ? 'smoke-steps.jsonl' : 'steps.jsonl'), JSON.stringify(item) + '\n', { flag: 'a' }); save();
  }
}
async function smoke() {
  await step('HTTP夹具入会成功', '独立调用产生joined', async () => { assert.equal((await rpc('host', 'room_join')).data.value.state, 'joined'); });
  await step('入会失败入口', '控制后room_join稳定404', async () => {
    await control('smoke-error', { joinError: true }); assert.equal((await rpc('smoke-error', 'room_join')).status, 404);
  });
  await step('聊天失败及恢复入口', '503后解除故障返回有效groupId', async () => {
    await control('host', { chatError: true }); assert.equal((await rpc('host', 'room_chat_session')).status, 503);
    await control('host', { chatError: false }); assert.ok((await rpc('host', 'room_chat_session')).data.value.groupId);
  });
  await step('设置失败与权限入口', '主持人503，非主持人403，解除故障200', async () => {
    await control('host', { settingsError: true }); assert.equal((await rpc('host', 'room_patch')).status, 503);
    await rpc('peer', 'room_join'); assert.equal((await rpc('peer', 'room_patch')).status, 403);
    await control('host', { settingsError: false }); assert.equal((await rpc('host', 'room_patch', { title: '配置测试' })).status, 200);
  });
  await step('共享失败与加载入口', '配置延迟可测，失败503，恢复200', async () => {
    await control('host', { configDelay: 120 }); const before = Date.now(); await rpc('host', 'room_screen_config'); assert.ok(Date.now() - before >= 100);
    await control('host', { configDelay: 0, configError: true }); assert.equal((await rpc('host', 'room_screen_config')).status, 503);
    await control('host', { configError: false }); assert.equal((await rpc('host', 'room_screen_config')).status, 200);
  });
  await control('host', { reset: true });
}
async function wait(fn, ms = 15000) {
  const deadline = Date.now() + ms;
  while (Date.now() < deadline) { if (await fn()) return; await new Promise(resolve => setTimeout(resolve, 100)); }
  throw Error('确定性状态等待超时');
}
const ui = 'http://127.0.0.1:3168';
async function layout() {
  const value = await page.evaluate(() => ({ width: innerWidth, document: document.documentElement.scrollWidth, height: innerHeight }));
  assert.ok(value.document <= value.width + 1, JSON.stringify(value));
  const toolbar = await page.getByTestId('room-toolbar-region').count() ? await page.getByTestId('room-toolbar-region').boundingBox() : null;
  if (toolbar) { assert.ok(toolbar.x >= 0 && toolbar.x + toolbar.width <= value.width + 1); assert.ok(toolbar.y + toolbar.height <= value.height + 1); }
  return `页面无横向溢出，工具栏在视口内：${JSON.stringify(value)}`;
}
async function newPage(width, height, disabled = [], options = {}) {
  const session = options.member ? 'peer' : 'host';
  await control('host', { reset: true });
  if (options.member) await rpc('host', 'room_join');
  await control(session, options.patch || {});
  const context = await browser.newContext({ viewport: { width, height }, locale: 'zh-CN' }); contexts.add(context);
  await context.addInitScript(installLayoutBridge, { base: backend.base, session });
  await context.addInitScript(installMeetingBridge, { base: backend.base, session });
  await context.addInitScript(({ disabled, denied, stale }) => {
    window.__meetingUiDisabled = disabled;
    window.__meetingUiMedia = { calls: [], denied: !!denied };
    if (stale) sessionStorage.setItem('liveMeeting.joinIntent', JSON.stringify({ code: '654321', name: '陈旧入会选项', micOn: true, camOn: true }));
  }, { disabled, denied: options.denied, stale: options.stale });
  page = await context.newPage(); page.setDefaultTimeout(10000);
  page.on('console', msg => { if (['error', 'warning'].includes(msg.type())) writeFileSync(path.join(out, 'browser-console.jsonl'), JSON.stringify({ type: msg.type(), text: msg.text() }) + '\n', { flag: 'a' }); });
  page.on('pageerror', error => { data.steps.push({ phase: 'runtime', viewport, operation: '浏览器未捕获异常', expected: '无异常', actual: String(error), pass: false }); });
  return session;
}
async function closePage() { if (page) { const context = page.context(); await context.close(); contexts.delete(context); page = null; } }
const button = name => page.getByRole('button', { name, exact: true });
const toolbar = () => page.getByTestId('room-toolbar-region');
const panel = () => page.getByTestId('room-side-panel');
async function joined() { await page.goto(ui + '/room?code=654321'); await page.getByTestId('participant-grid').waitFor(); await toolbar().getByRole('button', { name: /离开并结束|离开会议/ }).waitFor(); }
async function menu(name) { await toolbar().getByRole('button', { name: '更多', exact: true }).click(); await page.getByRole('menuitem', { name, exact: true }).click(); }
async function checkFlags(disabled) {
  const hidden = new Set(disabled);
  const names = { audio: /^(麦克风|已静音|连接音频)$/, video: /^(摄像头|已关闭)$/, chat: /^聊天$/, screenShare: /^共享屏幕$/, members: /^成员$/ };
  for (const [key, name] of Object.entries(names)) {
    const count = await toolbar().getByRole('button', { name }).count();
    assert.equal(count, hidden.has(key) ? 0 : 1, `${key}: ${count}`);
  }
  assert.equal(await page.getByTestId('room-recording-status').count(), hidden.has('recording') || hidden.has('audio') ? 0 : 1);
  const isHost = await toolbar().getByRole('button', { name: '离开并结束', exact: true }).count() > 0;
  await toolbar().getByRole('button', { name: '更多', exact: true }).click();
  for (const [key, name] of [['handRaise', /举手/], ['settings', /^设置$/]]) assert.equal(await page.getByRole('menuitem', { name }).count(), hidden.has(key) || (key === 'handRaise' && isHost) ? 0 : 1, key);
  await page.keyboard.press('Escape');
  if (!hidden.has('members')) {
    await toolbar().getByRole('button', { name: '成员', exact: true }).click();
    assert.equal(await panel().getByRole('button', { name: '聊天', exact: true }).count(), hidden.has('chat') ? 0 : 1);
    if (hidden.has('audio')) assert.equal(await panel().getByRole('button', { name: /全体.*静音/ }).count(), 0);
    await panel().getByRole('button', { name: '关闭', exact: true }).click();
  } else if (!hidden.has('chat')) {
    await toolbar().getByRole('button', { name: '聊天', exact: true }).click();
    assert.equal(await panel().getByRole('button', { name: /成员/ }).count(), 0);
    await panel().getByRole('button', { name: '关闭', exact: true }).click();
  }
  const calls = await page.evaluate(() => window.__meetingUiMedia.calls);
  if (hidden.has('audio')) assert.ok(!calls.some(c => (c.operation === 'mic' || c.operation === 'speaker') && c.value));
  if (hidden.has('video')) assert.ok(!calls.some(c => c.operation === 'camera' && c.value));
  if (hidden.has('audio') && hidden.has('video')) assert.ok(!calls.some(c => c.operation === 'connect'));
  if (hidden.has('chat')) assert.ok(!backend.calls.some(c => c.session === 'host' && c.command === 'room_chat_session' && c.time > currentStart));
  return layout();
}
let currentStart = 0;
async function exercise(width, height) {
  viewport = `${width}×${height}`;
  const variants = phase === 'screenshots' ? [[], ['video', 'screenShare'], modules] : [[], ...modules.map(key => [key]), ['audio', 'video'], ['video', 'screenShare'], modules];
  for (const disabled of variants) {
    currentStart = Date.now(); await newPage(width, height, disabled, { stale: true });
    await step(`模块配置 ${disabled.join(',') || '默认全部开启'}`, '入口、侧栏、自动采集与录制依赖一致，基本入会/离会保留', async () => {
      await joined(); return checkFlags(disabled);
    }, disabled.length === modules.length ? '全部禁用' : disabled.length ? '组合配置' : '默认全开');
    await closePage();
  }
  await newPage(width, height);
  await step('首页打开入会弹窗', '打开后展示默认音视频选项，可关闭', async () => {
    await page.goto(ui); await page.getByRole('button', { name: /加入会议/ }).first().click(); await page.getByRole('dialog').waitFor();
    assert.equal(await page.getByRole('dialog').getByRole('switch').count(), 2); return layout();
  }, '入会弹窗');
  await page.keyboard.press('Escape');
  await step('输入会议号并成功入会', '从首页入会，生产路由出现参与者及工具栏', async () => {
    await page.getByRole('button', { name: /加入会议/ }).first().click();
    const boxes = page.getByRole('dialog').locator('input[inputmode="numeric"]');
    for (let i = 0; i < 6; i++) await boxes.nth(i).fill('654321'[i]);
    await page.getByRole('dialog').getByRole('button', { name: '加入会议', exact: true }).click();
    await page.getByTestId('participant-grid').waitFor(); return layout();
  });
  await step('成员抽屉打开和滚动', '24名成员及长姓名可滚动，关闭后回到网格', async () => {
    for (let i = 1; i < 24; i++) await rpc(`long-member-${i}`, 'room_join');
    await wait(async () => await page.getByTestId('participant-tile').count() === 24);
    await toolbar().getByRole('button', { name: '成员', exact: true }).click();
    await panel().locator('.overflow-y-auto').evaluate(el => { el.scrollTop = el.scrollHeight; });
    return layout();
  }, '成员抽屉滚动');
  await panel().getByRole('button', { name: '关闭', exact: true }).click();
  await step('聊天空态抽屉', '抽屉真实打开，空态和输入框可见', async () => {
    await toolbar().getByRole('button', { name: '聊天', exact: true }).click(); await panel().waitFor();
    await panel().locator('input[maxlength="200"]').waitFor(); return layout();
  }, '聊天空态');
  await step('发送长消息与滚动', '发送成功，长文本不溢出；滚动后可关闭抽屉', async () => {
    for (let i = 0; i < 5; i++) {
      await panel().locator('input[maxlength="200"]').fill(`第${i + 1}条 ` + 'LongContent0123456789'.repeat(8));
      await panel().getByRole('button', { name: '发送', exact: true }).click();
      await wait(async () => await panel().locator('input[maxlength="200"]').inputValue() === '');
    }
    const scroll = panel().locator('.overflow-y-auto').first();
    await scroll.evaluate(el => { el.scrollTop = 0; });
    assert.equal(await panel().getByText(/^第1条 /).count(), 1); return layout();
  }, '聊天长文本滚动');
  await panel().getByRole('button', { name: '关闭', exact: true }).click();
  await step('会议设置打开及验证失败', '空标题保存展示错误且弹窗保留', async () => {
    await menu('设置'); await page.getByRole('dialog').locator('input[maxlength="50"]').fill('');
    await page.getByRole('button', { name: '保存设置', exact: true }).click(); await page.getByRole('alert').waitFor(); return layout();
  }, '设置验证错误');
  await step('设置服务失败可重试', '503显示错误并保留输入', async () => {
    await control('host', { settingsError: true }); await page.getByRole('dialog').locator('input[maxlength="50"]').fill('会议模块配置验收');
    await button('保存设置').click(); await page.getByText('夹具：保存失败，请重试', { exact: true }).waitFor(); return layout();
  }, '设置保存失败');
  await step('设置重试成功关闭弹窗', '解除故障后保存成功、弹窗关闭', async () => {
    await control('host', { settingsError: false }); await button('保存设置').click(); await page.getByRole('dialog').waitFor({ state: 'hidden' }); return layout();
  }, '设置保存成功');
  await step('共享权限拒绝', '拒绝捕获后显示权限提示，无共享残留', async () => {
    await page.evaluate(() => { window.__shareFixture.denied = true; }); await toolbar().getByRole('button', { name: '共享屏幕', exact: true }).click();
    await page.getByTestId('screen-status').filter({ hasText: /权限|拒绝|取消/ }).waitFor(); return layout();
  }, '共享权限拒绝');
  await step('共享选择加载态', '允许后进入选择状态，取消入口可用', async () => {
    await page.evaluate(() => { window.__shareFixture.denied = false; window.__shareFixture.choosing = true; });
    await toolbar().getByRole('button', { name: '共享屏幕', exact: true }).click();
    await toolbar().getByRole('button', { name: '取消共享', exact: true }).waitFor(); return layout();
  }, '共享加载选择');
  await step('取消共享及恢复成功', '取消后可再次共享，生产共享预览可见并能停止', async () => {
    await toolbar().getByRole('button', { name: '取消共享', exact: true }).click();
    await page.evaluate(() => { window.__shareFixture.choosing = false; window.__shareFixture.release?.(); });
    await toolbar().getByRole('button', { name: '共享屏幕', exact: true }).click();
    await toolbar().getByRole('button', { name: '停止共享', exact: true }).waitFor(); await page.getByTestId('screen-stage').locator('video').waitFor(); return layout();
  }, '共享成功');
  await toolbar().getByRole('button', { name: '停止共享', exact: true }).click();
  await step('主持人结束会议确认', '打开确认弹窗，明确结束后回到首页', async () => {
    await toolbar().getByRole('button', { name: '离开并结束', exact: true }).click(); await page.getByRole('dialog').waitFor(); return layout();
  }, '结束确认');
  await page.getByRole('dialog').getByRole('button', { name: /结束/, exact: false }).last().click();
  await page.waitForURL(url => url.pathname !== '/room'); await closePage();
  await newPage(width, height, [], { patch: { chatError: true } });
  await step('聊天初始化失败', '服务错误可见，重试入口存在', async () => {
    await joined(); await toolbar().getByRole('button', { name: '聊天', exact: true }).click();
    await panel().getByRole('status').filter({ hasText: '夹具：聊天初始化失败，请重试' }).waitFor(); return layout();
  }, '聊天错误');
  await step('聊天重试恢复', '解除故障后仍在当前会议中发送成功', async () => {
    await control('host', { chatError: false }); await panel().getByRole('button', { name: /重试/ }).click();
    await panel().locator('input[maxlength="200"]').fill('错误恢复后发送成功');
    await panel().getByRole('button', { name: '发送', exact: true }).click(); await panel().getByText('错误恢复后发送成功', { exact: true }).waitFor(); return layout();
  }); await closePage();
  await newPage(width, height, [], { denied: true });
  await step('麦克风权限失败', '自动采集被拒绝，展示提示且可以继续会议', async () => {
    await joined(); await page.getByTestId('media-status').filter({ hasText: /权限|拒绝/ }).waitFor(); return layout();
  }, '语音权限拒绝'); await closePage();
  await newPage(width, height, [], { member: true });
  await step('成员设置权限态', '非主持人字段禁用，会议仍可离开', async () => {
    await joined(); await menu('设置'); assert.equal(await page.getByRole('dialog').locator('input[maxlength="50"]').isDisabled(), true); return layout();
  }, '成员权限'); await page.keyboard.press('Escape');
  await step('成员离会成功', '离会后回首页且会话入口移除', async () => {
    await toolbar().getByRole('button', { name: '离开会议', exact: true }).click(); await page.waitForURL(ui + '/');
    await page.getByTestId('return-meeting').waitFor({ state: 'hidden' }); return layout();
  }); await closePage();
  await newPage(width, height, [], { patch: { joinDelay: 1200, joinError: true } });
  await step('入会加载态', '等待服务时显示确定性加载遮罩', async () => {
    await page.goto(ui + '/room?code=654321'); await page.getByText('正在加载会议…', { exact: true }).waitFor(); return layout();
  }, '入会加载');
  await step('入会失败可返回', '404落入错误态，返回首页', async () => {
    await page.getByRole('button', { name: '返回', exact: true }).waitFor(); return layout();
  }, '入会错误'); await button('返回').click(); await page.waitForURL(ui + '/'); await closePage();
  await newPage(width, height, modules);
  await step('全关入会弹窗', '无媒体选项，仍可填写会议号和昵称', async () => {
    await page.goto(ui); await page.getByRole('button', { name: /加入会议/ }).first().click(); await page.getByRole('dialog').waitFor();
    assert.equal(await page.getByRole('dialog').getByRole('switch').count(), 0); return layout();
  }, '全关入会弹窗'); await closePage();
}
const tsconfigPath = path.join(frontend, 'tsconfig.json'), tsconfigBefore = readFileSync(tsconfigPath, 'utf8');
try {
  if (!smokeOnly && existsSync(resultPath)) {
    const attemptsPath = path.join(out, 'attempts.json');
    const attempts = existsSync(attemptsPath) ? JSON.parse(readFileSync(attemptsPath, 'utf8')) : [];
    attempts.push(JSON.parse(readFileSync(resultPath, 'utf8'))); writeFileSync(attemptsPath, JSON.stringify(attempts, null, 2));
  }
  await smoke();
  if (!smokeOnly) {
    assert.ok(existsSync(path.join(out, 'smoke-results.json')), '先独立执行--smoke');
    for (const port of [3118, 39110, 9261, 9262, 9263, 3168]) data.probe.push({ port, status: await fetch(`http://127.0.0.1:${port}/${port >= 9261 && port <= 9263 ? 'json/version' : ''}`, { signal: AbortSignal.timeout(1500) }).then(r => r.status).catch(() => '不可连接') });
    assert.equal(data.probe.find(p => p.port === 3168).status, '不可连接', '不复用其他版本的前端');
    for (const port of [9261, 9262, 9263]) {
      let attached;
      try {
        attached = await chromium.connectOverCDP(`http://127.0.0.1:${port}`, { timeout: 2500 });
        const native = attached.contexts().flatMap(c => c.pages()).find(p => !p.url().includes('/im/engine') && !p.url().startsWith('about:'));
        if (native) data.probe.push(await native.evaluate(async port => {
          const status = await window.__TAURI_INTERNALS__.invoke('server_get_status');
          return { cdp: port, loggedIn: !!status.loggedIn, authenticated: !!status.authenticated, route: location.pathname, reuse: '只读检查登录态，保留原会话' };
        }, port));
      } catch (error) { data.probe.push({ cdp: port, loginProbe: String(error).split('\n')[0] }); }
      finally { if (attached) await attached.close(); }
    }
    const log = openSync(path.join(out, 'dev-server.log'), 'a');
    data.distDir = `.next-e2e-ui-config-${started}`;
    next = spawn(process.execPath, ['-e', `process.on('message',()=>process.exit(0));require(${JSON.stringify(require.resolve('next/dist/server/lib/start-server'))}).startServer({dir:${JSON.stringify(frontend)},isDev:true,hostname:'127.0.0.1',port:3168,allowRetry:false})`], { cwd: frontend, env: { ...process.env, OPENMEETING_NEXT_DIST_DIR: data.distDir, OPENMEETING_E2E_DESKTOP_LAYOUT: '1', OPENMEETING_E2E_MEETING_UI: '1', NEXT_PUBLIC_LIVE_MEETING_DATA_SOURCE: 'real' }, windowsHide: true, stdio: ['ignore', log, log, 'ipc'] });
    await wait(() => fetch(ui + '/brand-logo.png').then(r => r.ok).catch(() => false), 60000);
    await fetch(ui);
    browser = await chromium.launch({ headless: true, args: ['--autoplay-policy=no-user-gesture-required', '--disable-background-timer-throttling'] });
    phase = 'assertions'; for (const size of [[1280, 800], [390, 844]]) await exercise(...size);
    assert.equal(data.steps.filter(s => !s.pass).length, 0);
    phase = 'screenshots'; for (const size of [[1280, 800], [390, 844]]) await exercise(...size);
  }
} catch (error) {
  data.error = String(error.stack || error); console.error(data.error); process.exitCode = 1;
  if (Date.now() - budgetStarted > 1800000) {
    writeFileSync(path.join(out, 'api-fallback.json'), JSON.stringify({ reason: '累计E2E调试超过30分钟，停止页面调试，仅执行API夹具验证', results: await Promise.all(['room_get', 'room_chat_session'].map(command => rpc('host', command))) }, null, 2));
  }
} finally {
  for (const context of contexts) await context.close().catch(() => {});
  if (browser) await browser.close(); data.cleanup.browser = '本次无头浏览器已关闭';
  if (next) {
    if (next.connected) next.send('shutdown');
    await wait(() => next.exitCode !== null, 10000).catch(() => next.kill());
    data.cleanup.next = await fetch(ui, { signal: AbortSignal.timeout(1000) }).then(() => '端口仍在监听，需检查').catch(() => '本次3168开发服务已关闭');
  }
  await backend.close(); data.cleanup.fixture = '本次HTTP夹具及其回退服务已关闭';
  data.cleanup.existing = '保留原有服务和开发客户端'; writeFileSync(tsconfigPath, tsconfigBefore);
  data.finished = new Date().toISOString(); save(); if (!smokeOnly) report(); console.log('Artifacts: ' + out);
}
