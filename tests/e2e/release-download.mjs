import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { createRequire } from 'node:module';
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const root = fileURLToPath(new URL('../../', import.meta.url));
const require = createRequire(path.join(root, 'frontend/package.json'));
const { chromium } = require('playwright');
const base = process.env.RELEASE_ADMIN_URL || 'http://localhost:5173';
const out = path.join(root, '.artifacts/release-download');
mkdirSync(path.join(out, 'screenshots'), { recursive: true });
const report = { scope: '小范围下载入口修改：真实网关与对象存储下载，安装包为显式测试文本，不执行安装。复用现有服务，验证不存在的文件及未上传状态。', checks: [], screenshots: [], cleanup: [] };
function check(operation, expected, actual) {
  const row = { operation, expected, actual, pass: true, screenshot: null };
  report.checks.push(row);
  console.log(JSON.stringify(row));
}
const browser = await chromium.launch({ headless: true });
const context = await browser.newContext({ viewport: { width: 1440, height: 960 }, locale: 'zh-CN', acceptDownloads: true });
const releaseIds = [];
try {
  const password = execFileSync(path.join(root, 'server/.venv/Scripts/python.exe'), ['-X', 'utf8', '-c', "from dotenv import dotenv_values;print(dotenv_values('.env')['OPENMEETING_ADMIN_PASSWORD'])"], { cwd: path.join(root, 'server') }).toString('utf8').trim();
  assert.equal((await context.request.post(base + '/admin/api/login', { data: { password } })).status(), 200);
  check('登录复用的开发服务', '200，不保存登录凭据', '200');
  const missing = await context.request.get(base + '/api/v1/updates/download/nonexistent-e2e-artifact');
  assert.equal(missing.status(), 404);
  assert.equal((await missing.json()).detail, '安装包不存在');
  check('下载失败入口先冒烟', '不存在的安装包稳定返回404', '404 安装包不存在');

  const version = `99.0.${Math.floor(Date.now() / 1000) % 1000000}`;
  const payload = Buffer.from('Explicit E2E download fixture, not an executable installer.\n');
  const cases = [];
  for (const platform of ['windows', 'android']) {
    const created = await context.request.post(base + '/admin/api/releases', { data: { platform, version, notes: 'E2E 临时下载验证，结束后自动删除' } });
    assert.equal(created.status(), 201);
    const release = await created.json();
    releaseIds.push(release.id);
    const arches = platform === 'windows' ? ['x86_64', 'aarch64'] : ['any'];
    for (const arch of arches) {
      const name = `e2e-${arch}.${platform === 'windows' ? 'exe' : 'apk'}`;
      const multipart = { arch, file: { name, mimeType: 'application/octet-stream', buffer: payload } };
      if (platform === 'windows') multipart.signature = { name: name + '.sig', mimeType: 'text/plain', buffer: Buffer.from('explicit-e2e-signature-fixture') };
      const uploaded = await context.request.post(`${base}/admin/api/releases/${release.id}/artifacts`, { multipart });
      assert.equal(uploaded.status(), 201);
      const artifact = (await uploaded.json()).artifacts.find(a => a.arch === arch);
      cases.push({ platform, name, artifact });
    }
  }
  check('真实上传下载夹具', 'Windows两种架构、Android各自独立安装包', cases.map(c => ({ platform: c.platform, name: c.name, storage: c.artifact.storage })));

  const page = await context.newPage();
  page.setDefaultTimeout(15000);
  const errors = [];
  page.on('pageerror', e => errors.push(e.message));
  await page.goto(base + '/admin/releases');
  await page.getByRole('heading', { name: '版本发布', exact: true }).waitFor();
  for (const item of cases) {
    await page.getByRole('tab', { name: item.platform === 'windows' ? 'Windows' : 'Android', exact: true }).click();
    const link = page.getByRole('link', { name: `下载 ${item.name}`, exact: true });
    await link.waitFor();
    assert.equal(await link.getAttribute('href'), `/api/v1/updates/download/${item.artifact.id}`);
    const [download] = await Promise.all([page.waitForEvent('download'), link.click()]);
    assert.equal(await download.failure(), null);
    assert.deepEqual(readFileSync(await download.path()), payload);
    assert.equal(download.suggestedFilename(), item.name);
    assert.equal(new URL(page.url()).pathname, '/admin/releases');
    check(`页面下载 ${item.platform}/${item.artifact.arch}`, '文件名、字节正确，版本发布页面保留', download.suggestedFilename());
  }
  await Promise.all([
    page.waitForResponse(r => r.url().includes('/admin/api/releases?') && r.status() === 200),
    page.getByRole('button', { name: '刷新', exact: true }).click(),
  ]);
  const releases = await (await context.request.get(base + '/admin/api/releases?platform=android')).json();
  assert.equal(releases.find(r => r.id === releaseIds[1]).artifacts[0].download_count, 1);
  check('下载次数', '下载一次增加1次', '1');
  const empty = await context.request.post(base + '/admin/api/releases', { data: { platform: 'windows', version: `99.1.${Math.floor(Date.now() / 1000) % 1000000}` } });
  assert.equal(empty.status(), 201);
  const emptyRelease = await empty.json();
  releaseIds.push(emptyRelease.id);
  await page.getByRole('tab', { name: 'Windows', exact: true }).click();
  const emptyRow = page.locator('.el-table__row').filter({ hasText: emptyRelease.full_version });
  await emptyRow.getByText('未上传', { exact: true }).waitFor();
  assert.equal(await emptyRow.getByRole('link', { name: /^下载 / }).count(), 0);
  check('未上传版本', '未上传提示，不显示无效下载按钮', '符合预期');
  assert.deepEqual(errors, []);
  check('浏览器运行时异常', '0', errors.length);

  // 断言通过后统一截图。视觉结论在实际查看后单独记录。
  for (const [index, width] of [1440, 390].entries()) {
    await page.setViewportSize({ width, height: 960 });
    await page.reload();
    await page.getByRole('link', { name: `下载 ${cases[0].name}`, exact: true }).waitFor();
    await page.locator('.el-table__body-wrapper .el-scrollbar__wrap').evaluate((el, left) => { el.scrollLeft = left; }, width < 500 ? 620 : 0);
    if (width < 500) {
      const [download] = await Promise.all([
        page.waitForEvent('download'),
        page.getByRole('link', { name: `下载 ${cases[0].name}`, exact: true }).click(),
      ]);
      assert.deepEqual(readFileSync(await download.path()), payload);
      check('窄视口横向滚动后下载', '下载按钮可点击，文件内容正确', '符合预期');
    }
    const file = `screenshots/0${index + 1}-${width}-版本发布.png`;
    await page.screenshot({ path: path.join(out, file), fullPage: true });
    report.screenshots.push({ path: file, viewport: page.viewportSize(), inspected: false });
  }
} catch (e) {
  report.checks.push({ operation: '执行异常', expected: '所有断言通过', actual: e.message, pass: false, screenshot: null });
  process.exitCode = 1;
} finally {
  for (const id of releaseIds) {
    const res = await context.request.delete(`${base}/admin/api/releases/${id}`);
    report.cleanup.push({ release: id, deleted: res.status() === 204 });
    if (res.status() !== 204) process.exitCode = 1;
  }
  await browser.close();
  report.cleanup.push({ browserClosed: true, services: '复用已有服务，未启动或停止服务' });
  writeFileSync(path.join(out, 'results.json'), JSON.stringify(report, null, 2));
  console.log(JSON.stringify({ passed: report.checks.filter(c => c.pass).length, failed: report.checks.filter(c => !c.pass).length, cleanup: report.cleanup }));
}
