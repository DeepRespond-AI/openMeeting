// Build the report from executed assertions, logs and explicitly reviewed screenshots.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

const output = path.resolve(process.env.MEETING_SEARCH_OUTPUT ?? '.artifacts/mobile-history-search-gateway-20261029');
const json = name => JSON.parse(fs.readFileSync(path.join(output, name), 'utf8'));
const log = name => {
  const bytes = fs.readFileSync(path.join(output, name));
  return bytes[0] === 0xff && bytes[1] === 0xfe ? bytes.subarray(2).toString('utf16le') : bytes.toString('utf8');
};
const rows = json('results.json');
const reviews = json('visual-reviews.json');
const execution = json('execution-finished.json');
const cleanup = json('cleanup.json');
const preflight = json('preflight.json');
const history = ['history/ui-01-results.json', 'history/ui-02-results.json']
  .filter(name => fs.existsSync(path.join(output, name)))
  .flatMap(name => json(name).filter(row => !row.pass).map(row => ({ ...row, evidence: name })));
const assertions = rows.filter(r => r.phase === 'assertions');
const smoke = rows.filter(r => r.phase === 'fixture-smoke');
const replay = rows.filter(r => r.phase === 'screenshots');
const pictures = replay.filter(r => r.screenshot);
const unit = log('unit.log');
const unitPassed = Number(unit.match(/\+(\d+): All tests passed!/)?.[1] ?? 0);
const staticClean = log('analyze-01.log').includes('No issues found!') &&
  log('analyze-final.log').includes('No issues found!');
const suite = log('backend.xml').match(/<testsuite\b[^>]*>/)?.[0] ?? '';
const attribute = name => Number(suite.match(new RegExp(`${name}="(\\d+)"`))?.[1] ?? 0);
const backend = { executed: !!suite, passed: attribute('tests') - attribute('failures') - attribute('errors') - attribute('skipped'),
  failed: attribute('failures') + attribute('errors'), skipped: attribute('skipped') };
const visual = pictures.map(row => {
  const bytes = fs.readFileSync(path.join(output, row.screenshot));
  const hash = crypto.createHash('sha256').update(bytes).digest('hex');
  const review = reviews.find(r => r.screenshot === row.screenshot && r.sha256 === hash);
  return { ...row, review, pass: !!review?.viewed && review?.pass === true };
});
const count = group => ({ passed: group.filter(r => r.pass).length, failed: group.filter(r => !r.pass).length });
const summary = { unitPassed, unitPassedLog: unit.includes('All tests passed!'), assertions: count(assertions),
  fixture: count(smoke), screenshotReplay: count(replay), visual: count(visual), staticClean,
  backend, historicalFailures: history.length,
  elapsedMs: execution.elapsedMs, budgetLimitMs: execution.limitMs, cleanup, preflight };
fs.writeFileSync(path.join(output, 'summary.json'), JSON.stringify(summary, null, 2));
const cell = value => String(typeof value === 'object' ? JSON.stringify(value) : value ?? '').replaceAll('|', '\\|').replaceAll('\n', ' ');
const resultTable = group => group.map(r => `| ${cell(r.viewport)} | ${cell(r.operation)} | ${cell(r.expected)} | ${cell(r.actual)} | ${r.pass ? '通过' : '失败'} |`).join('\n');
const report = `# 移动端历史会议搜索测试报告

验证分级：本次为搜索错误展示和网关漏配路由修复，执行生产页面/控制器的双视口无头 Flutter 流程，以及真实 ASGI 网关路由/流式代理测试。覆盖受影响成功、加载、空态、404/503 失败重试及导航冒烟。没有新增原生能力；本轮未在浏览器、Android 模拟器或真机运行 App。ASGI 测试的身份和下游数据是显式夹具，不将其称为真实账号或原生端到端验收。

## 改动与边界

根因：网关 CLIENT_ROUTES 缺少 /api/v1/transcripts，导致 /api/v1/transcripts/search 在认证前即返回 404。现场只读探测记录于 preflight.json：未认证搜索返回 ${preflight.searchStatus}，会议列表返回 ${preflight.meetingsStatus}。补齐转发至 meeting_ms 的受保护路由，不将 404 吞成空数组。

移动端仍按桌面端规则合并标题和转写命中。已有标题结果而内容搜索失败时，使用轻量、准确的内容搜索不可用说明和重试按钮，移除误导性的资源不存在大错误块；恢复后移除提示，结果始终可以打开。无任何结果且搜索失败时仍保留错误与重试，避免误报空态。

业务边界使用 FakeMeetingsRepository；404、503、加载门闩和重复转写响应均为确定夹具，先单独验证两类失败分别连续两次且可恢复。页面使用真实 MeetingsListPage、MeetingSearchController 和主题；详情落点为导航探针，仅验证解析的会议 ID，未验证详情页业务。心跳替换为空闲实现。后端采用生产 router 和 proxy_stream，验证英文/中文/百分号查询参数、身份头防伪、认证要求、200 结果/空数组、503 透传和前缀边界，不访问或清空任何数据库。

## 启动与复现

工作目录：\`<repo>\\mobile\`；分支：\`feat/mobile-home-grid\`。

启动前已探测现有 :39110 后端、:3118 前端与 emulator-5554，全部保留，不重装、不清理登录态。本次通过 Flutter 测试运行器启动包含修改的真实页面，后端通过 httpx ASGITransport 执行生产路由，不另起开发服务器。

\`\`\`powershell
$env:PUB_HOSTED_URL='https://pub.flutter-io.cn'
$env:FLUTTER_STORAGE_BASE_URL='https://storage.flutter-io.cn'
$env:Path='<flutter-sdk>\\bin;'+$env:Path
flutter test --no-pub test/features/meetings/meeting_search_test.dart test/features/meetings/meetings_list_controller_test.dart test/features/meetings/meetings_repository_impl_test.dart --reporter expanded
flutter test --no-pub test/acceptance/meeting_search_ui_test.dart --reporter expanded
dart analyze
cd ../server
<repo>\\server\\.venv\\Scripts\\python.exe -m pytest tests/test_transcript_search_proxy.py tests/test_room_proxy.py -q
\`\`\`

产物默认写入本目录。另起一次验证应设置 MEETING_SEARCH_OUTPUT 指向新目录，30 分钟累计预算不可在同轮调试中重置。断言全部通过后才进入截图重放阶段。重放用于截图，不重复计入功能通过数。

## 执行结果

- 单元/仓储契约测试：${unitPassed} 通过，日志整体通过=${summary.unitPassedLog}。
- 夹具独立冒烟：${summary.fixture.passed} 通过 / ${summary.fixture.failed} 失败。
- 网关/代理回归：${backend.passed} 通过 / ${backend.failed} 失败 / ${backend.skipped} 跳过，已执行=${backend.executed}。
- 页面功能断言：${summary.assertions.passed} 通过 / ${summary.assertions.failed} 失败。
- 截图阶段重放：${summary.screenshotReplay.passed} 通过 / ${summary.screenshotReplay.failed} 失败。
- 逐张视觉检查：${summary.visual.passed} 通过 / ${summary.visual.failed} 未通过，共 ${pictures.length} 张。
- 静态分析：${staticClean ? 'No issues found' : '未通过或缺少通过证据'}。
- E2E 调试累计 ${Math.round(execution.elapsedMs / 1000)} 秒，预算 ${execution.limitMs / 60000} 分钟。

证据：[单元测试](unit.log)、[网关日志](backend.log)、[网关 JUnit](backend.xml)、[最终页面运行](ui-03.log)、[静态分析](analyze-01.log)、[最终测试脚本分析](analyze-final.log)、[结构化步骤](results.json)、[视觉检查与哈希](visual-reviews.json)、[清理记录](cleanup.json)、[现场只读探测](preflight.json)。

历史失败 ${history.length} 条：首次新增英文记录后，旧脚本把列表最后一项当成长标题测试数据，断言失效；改为按 ID 定位后第二轮通过。第二轮截图在 history/ui-02-screenshots 保留；第三轮增加用户截图对应 m 搜索恢复后的无提示截图并完整通过。历史失败未计为通过。

${history.map(row => `- ${cell(row.operation)}：${cell(row.actual)}；[原始记录](${row.evidence})。`).join('\n')}

| 视口 | 操作 | 预期 | 实际 | 结果 |
|---|---|---|---|---|
${resultTable([...smoke, ...assertions])}

## 截图与视觉检查

视口：390×844 窄屏、1024×768 桌面/平板；Windows 字体加载微软雅黑与 MaterialIcons；无头截图替代 in-app browser。正常列表、标题匹配、加载进度、内容合并、高亮、m 搜索 404 的轻量降级、恢复后无提示状态、503、空态和长标题均逐张查看。窄屏长标题按既有样式省略，宽屏完整展示；检查卡片边界、搜索框、按钮可见性及层级。权限、抽屉、弹窗不属于本次新增或修改路径，未执行相应验收。

| 视口 | 状态 | 截图 | 视觉结果 | 实际检查记录 |
|---|---|---|---|---|
${visual.map(r => `| ${cell(r.viewport)} | ${cell(r.operation)} | [查看](${r.screenshot}) | ${r.pass ? '已查看，通过' : '未通过/未查看/哈希不匹配'} | ${cell(r.review?.notes)} |`).join('\n')}

## 清理与剩余风险

${cell(cleanup.result)}

日常 :39110 未切换到本分支网关，需部署或重启包含新增路由的网关，单独热重载移动端不能修复服务端 404。真实 Android 键盘、系统生命周期、真实网络和真实账号权限未在本轮重新验证。录音、RTC、共享、后台任务未纳入本次局部搜索回归。内容搜索不可用时无法获得内容命中，页面明确说明当前仅显示标题结果并提供重试。
`;
fs.writeFileSync(path.join(output, '测试报告.md'), report);
console.log(JSON.stringify(summary));
