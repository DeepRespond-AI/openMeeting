// Real admin UI -> isolated API/PostgreSQL -> direct MinIO PUT. No production accounts.
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { mkdirSync, readFileSync, writeFileSync, existsSync, renameSync } from 'node:fs';
import path from 'node:path';
const root = process.cwd();
const require = createRequire(path.join(root, 'frontend/package.json'));
const { chromium } = require('playwright');
const base = process.env.DIRECT_UPLOAD_WEB || 'http://127.0.0.1:5186';
const fixture = 'http://127.0.0.1:39362';
const out = path.join(root, '.artifacts/direct-upload-20261105');
mkdirSync(path.join(out, 'screenshots'), { recursive: true });
if (existsSync(path.join(out, 'browser-results.json'))) renameSync(path.join(out, 'browser-results.json'), path.join(out, `browser-attempt-${Date.now()}.json`));
const report = { started: new Date().toISOString(), budgetMinutes: 30, scope: '完整上传流程；真实 MinIO/PG，合成安装包，不执行安装或真实 ASR。先断言，再统一截图。', steps: [], screenshots: [] };
const save = () => writeFileSync(path.join(out, 'browser-results.json'), JSON.stringify(report, null, 2));
function check(operation, expected, actual, passed = true) {
  const row = { operation, expected, actual, passed, screenshot: null };
  report.steps.push(row); console.log(JSON.stringify(row)); save(); assert.ok(passed, operation);
}
const browser = await chromium.launch({ headless: true });
const context = await browser.newContext({ viewport: { width: 1440, height: 960 }, locale: 'zh-CN', acceptDownloads: true });
await context.tracing.start({ screenshots: true, snapshots: true });
const payload = Buffer.from('Explicit direct upload browser fixture, not an executable APK.\n'.repeat(20000));
const fileName = 'direct-upload-long-name-for-responsive-dialog-verification.apk';
const page = await context.newPage(); page.setDefaultTimeout(15000);
const errors = []; page.on('pageerror', e => errors.push(e.message));
const storageRequests = [];
const inspectedRequests = [];
page.on('request', req => {
  if (req.method() === 'PUT' && req.url().startsWith('http://127.0.0.1:39361/')) {
    inspectedRequests.push(req.allHeaders().then(h => storageRequests.push({ bytes: req.postDataBuffer()?.length, businessAuth: (h.authorization || '').startsWith('Bearer '), cookie: !!h.cookie })));
  }
});
const mode = async value => assert.equal((await context.request.post(fixture + '/__fixture/state', { data: { mode: value } })).status(), 200);
let version;
const dialog = () => page.getByRole('dialog', { name: /^上传安装包/ });
const row = () => page.locator('.el-table__row').filter({ hasText: version });
async function openUpload() {
  await row().getByRole('button', { name: '上传', exact: true }).click();
  await dialog().waitFor();
  await dialog().locator('input[type=file]').first().setInputFiles({ name: fileName, mimeType: 'application/vnd.android.package-archive', buffer: payload });
  await dialog().getByText(fileName, { exact: false }).waitFor();
}
async function failUpload(failure) {
  await mode(failure);
  await Promise.all([
    page.waitForResponse(r => failure === 'fail-put' ? r.url().endsWith('/__fixture/put-error') && r.status() === 503 : r.url().endsWith('/uploads/complete') && r.status() === 502),
    dialog().getByRole('button', { name: '上传', exact: true }).click(),
  ]);
  await page.locator('.el-message--error').last().waitFor();
  await page.waitForFunction(() => [...document.querySelectorAll('[role=dialog] button')].some(b => b.textContent.trim() === '上传' && !b.disabled));
  assert.ok(await dialog().getByRole('button', { name: '上传', exact: true }).isEnabled());
  assert.ok(await dialog().getByText(fileName, { exact: false }).isVisible());
}
async function withLoading(action) {
  await mode('normal');
  let entered; const requested = new Promise(resolve => entered = resolve);
  let release; const gate = new Promise(resolve => release = resolve);
  await page.route('http://127.0.0.1:39361/**', async route => { if (route.request().method() === 'PUT') { entered(); await gate; } await route.continue(); });
  try {
    await dialog().getByRole('button', { name: '上传', exact: true }).click();
    await Promise.race([requested, new Promise((_, reject) => setTimeout(() => reject(new Error('No direct PUT')), 15000))]);
    await action();
  } finally { release(); await page.unrouteAll({ behavior: 'wait' }); }
  await dialog().waitFor({ state: 'hidden' });
  await row().getByRole('link', { name: `下载 ${fileName}`, exact: true }).waitFor();
}
async function shot(name) {
  const relative = `screenshots/${String(report.screenshots.length + 1).padStart(2, '0')}-${name}.png`;
  await page.screenshot({ path: path.join(out, relative), fullPage: true, animations: 'disabled' });
  report.screenshots.push({ path: relative, viewport: page.viewportSize(), state: name, visuallyReviewed: false }); save();
}
try {
  // Fixture failure smoke was completed separately in direct-upload-checks.py before this browser run.
  const apiChecks = JSON.parse(readFileSync(path.join(out, 'api-results.json')));
  check('夹具先独立冒烟', 'API全部通过且包含两条确定性失败入口', { passed: apiChecks.passed, failed: apiChecks.failed }, apiChecks.failed === 0 && apiChecks.steps.some(s => s.operation === '确认失败夹具冒烟'));
  await page.goto(base + '/admin/releases');
  await page.getByPlaceholder('管理员密码').fill('direct-upload-e2e-admin');
  await page.getByRole('button', { name: '登录', exact: true }).click();
  await page.getByRole('heading', { name: '版本发布', exact: true }).waitFor();
  check('真实管理员登录', '进入版本发布', new URL(page.url()).pathname);
  await page.getByRole('tab', { name: 'Android', exact: true }).click();
  await page.getByRole('button', { name: '新建版本', exact: true }).click();
  version = `98.0.${Math.floor(Date.now() / 1000) % 1000000}`;
  const create = page.getByRole('dialog', { name: '新建Android版本' });
  await create.getByPlaceholder('如 1.2.0').fill(version);
  await create.getByPlaceholder('展示在客户端的升级提示里，每行一条').fill('直传验收：长文本换行与滚动。'.repeat(16));
  await create.getByRole('button', { name: '保存', exact: true }).click();
  await create.waitFor({ state: 'hidden' });
  await row().getByText('未上传', { exact: true }).waitFor();
  check('新建版本及空态', '保存成功、未上传、无下载链接', version, await row().getByRole('link').count() === 0);
  await openUpload(); await failUpload('fail-put');
  check('存储上传失败', '展示错误、保留文件与可操作重试入口', '503，弹窗保留');
  await failUpload('fail-complete');
  check('确认失败', '不展示上传成功、不关闭弹窗、不丢失文件', '502，弹窗保留');
  await withLoading(async () => {
    assert.ok(await dialog().getByRole('button', { name: '取消', exact: true }).isDisabled());
    await dialog().getByRole('progressbar').waitFor();
    assert.equal(await dialog().getByRole('button', { name: 'Close this dialog' }).count(), 0);
    check('异步上传中状态', '显示进度、禁止中途关闭，等待确认后成功', '符合预期');
  });
  check('失败后重试成功', '文件出现在安装包列表，弹窗关闭', fileName);
  await Promise.all(inspectedRequests);
  assert.ok(storageRequests.length >= 2);
  check('浏览器直传隔离凭据', '真实PUT到MinIO，不含业务Bearer和Cookie；流式请求内容由后续下载逐字节核对', storageRequests, storageRequests.every(r => (r.bytes === undefined || r.bytes === payload.length) && !r.businessAuth && !r.cookie));
  const [download] = await Promise.all([page.waitForEvent('download'), row().getByRole('link', { name: `下载 ${fileName}`, exact: true }).click()]);
  assert.equal(await download.failure(), null); assert.deepEqual(readFileSync(await download.path()), payload);
  check('页面下载完整性', '上传后的文件逐字节一致', download.suggestedFilename());
  await row().getByRole('button', { name: '发布', exact: true }).click();
  const confirm = page.getByRole('dialog');
  if (await confirm.count()) await confirm.getByRole('button', { name: /确定|发布/, exact: false }).click();
  await row().getByText('已发布', { exact: true }).waitFor();
  check('发布直传安装包', '版本成功发布', version);
  for (const width of [1440, 390]) {
    await page.setViewportSize({ width, height: width === 390 ? 844 : 960 });
    await openUpload();
    const box = await dialog().locator('.el-dialog').boundingBox();
    check(`上传弹窗响应式 ${width}`, '弹窗左右不超出视口，长文件名不撑开弹窗', box, box.x >= 0 && box.x + box.width <= width);
    await failUpload('fail-put');
    await dialog().getByRole('button', { name: '取消', exact: true }).click();
    await dialog().waitFor({ state: 'hidden' });
    check(`弹窗错误和关闭 ${width}`, '错误状态真实打开，取消可关闭', '通过');
  }
  check('运行时异常', '0', errors, errors.length === 0);
  // Assertions all passed. Now replay states solely for screenshots and actual visual review.
  for (const width of [1440, 390]) {
    await page.setViewportSize({ width, height: width === 390 ? 844 : 960 });
    await mode('normal');
    await page.locator('.el-message').last().waitFor({ state: 'hidden' });
    await page.locator('.main').evaluate(el => { el.scrollTop = 0; });
    await shot(`${width}-成功列表`);
    await openUpload(); await shot(`${width}-弹窗长文件名`);
    await failUpload('fail-put'); await shot(`${width}-上传失败`);
    await page.locator('.el-message').last().waitFor({ state: 'hidden' });
    await failUpload('fail-complete'); await shot(`${width}-确认失败`);
    await page.locator('.el-message').last().waitFor({ state: 'hidden' });
    await withLoading(async () => shot(`${width}-加载中`));
    await shot(`${width}-重试成功关闭弹窗`);
  }
  await context.clearCookies(); await page.reload(); await page.getByPlaceholder('管理员密码').waitFor();
  for (const width of [390, 1440]) { await page.setViewportSize({ width, height: width === 390 ? 844 : 960 }); await shot(`${width}-无登录权限`); }
  check('会话失效保护', '无登录态跳转登录页面', new URL(page.url()).pathname, new URL(page.url()).pathname === '/admin/login');
} catch (error) {
  report.steps.push({ operation: 'E2E中断', expected: '所有断言通过', actual: String(error), passed: false, screenshot: 'failure.png' });
  await page.screenshot({ path: path.join(out, 'failure.png'), fullPage: true }).catch(() => {});
  process.exitCode = 1;
} finally {
  await mode('normal').catch(() => {});
  report.finished = new Date().toISOString();
  report.passed = report.steps.filter(s => s.passed).length; report.failed = report.steps.filter(s => !s.passed).length;
  save(); await context.tracing.stop({ path: path.join(out, 'browser-trace.zip') }); await browser.close();
}
