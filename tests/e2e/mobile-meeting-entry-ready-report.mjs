import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';

const root = path.resolve(import.meta.dirname, '../..');
const out = path.join(root, '.artifacts/mobile-meeting-entry-ready');
const archive = path.join(root, 'docs/testing/archive/移动端初始化就绪后入会');
const read = name => JSON.parse(fs.readFileSync(path.join(out, name), 'utf8').replace(/^\uFEFF/, ''));
const checks = read('checks-summary.json'), smoke = read('smoke-summary.json');
const ui = read('ui-results.json'), visual = read('visual-results.json');
const analyze = read('analyze-summary.json'), reviews = read('visual-reviews.json');
const cleanup = read('cleanup.json'), budget = read('budget.json');
fs.mkdirSync(path.join(archive, 'screenshots'), {recursive: true});
for (const name of fs.readdirSync(out).filter(name => /\.(json|log)$/.test(name))) {
  if (name.endsWith('.log')) {
    fs.writeFileSync(path.join(archive, name), fs.readFileSync(path.join(out, name), 'utf8').replace(/[ \t]+$/gm, ''));
  } else fs.copyFileSync(path.join(out, name), path.join(archive, name));
}
for (const row of visual) {
  assert.ok(row.screenshot && reviews[row.screenshot]?.viewed, `未查看截图 ${row.screenshot}`);
  const bytes = fs.readFileSync(path.join(out, row.screenshot));
  assert.equal(createHash('sha256').update(bytes).digest('hex'), reviews[row.screenshot].sha256);
  fs.copyFileSync(path.join(out, row.screenshot), path.join(archive, row.screenshot));
}
const summary = {
  smokePassed: smoke.actual.passed, smokeFailed: smoke.actual.failed,
  testsPassed: checks.actual.passed, testsFailed: checks.actual.failed,
  uiPassed: ui.filter(row => row.pass).length, uiFailed: ui.filter(row => !row.pass).length,
  visualStepsPassed: visual.filter(row => row.pass).length,
  visualStepsFailed: visual.filter(row => !row.pass).length,
  analyze: analyze.pass, screenshots: visual.length,
  cleanup: cleanup.every(row => row.pass),
};
fs.writeFileSync(path.join(archive, 'summary.json'), JSON.stringify(summary, null, 2));
const esc = value => String(value ?? '').replaceAll('|', '\\|').replaceAll('\n', ' ');
const report = [
  '# 移动端初始化就绪后入会测试报告', '',
  '分级理由：本次仅调整首次入会及会中媒体重试的页面展示，使用真实 Flutter 页面、控制器和退出弹窗验证受影响流程及成功冒烟。业务接口和 SDK 为显式模拟接口；本轮属于无头页面交互验收，不是原生多端或真实 RTC 端到端验收。', '',
  '## 行为与范围', '',
  '首次业务入会后仍显示“正在加入会议”，业务信令和 RTC 均 connected 后显示正常会议，会议内移除“音视频正在后台连接，可先使用聊天和成员功能”。已进入的会议后续媒体重试保持会议可见。旧连接继续后台释放，创建下一业务房间不等旧连接；下一次 RTC 接入仍需等待释放，超时提供错误、重试和离会入口。', '',
  '## 启动与流程', '',
  '基于 develop 开发。先阅读 CLAUDE.md、mobile 开发/测试规则和项目启动说明，并探测既有 3118/39110 服务；本次无头 Flutter 测试不依赖真实登录态，因此保留既有服务和账号，不启动额外业务服务。使用仓库测试入口启动包含本次改动的 Flutter 页面。', '',
  '```powershell',
  "$env:MOBILE_RTC_RELEASE_OUTPUT='.artifacts/mobile-meeting-entry-ready'",
  'node tests/e2e/mobile-rtc-release-race.mjs smoke',
  'node tests/e2e/mobile-rtc-release-race.mjs checks',
  'node tests/e2e/mobile-rtc-release-race.mjs ui',
  'node tests/e2e/mobile-rtc-release-race.mjs visual',
  'node tests/e2e/mobile-rtc-release-race.mjs analyze',
  'node tests/e2e/mobile-meeting-entry-ready-report.mjs',
  '```', '',
  '先独立冒烟：用 Completer 控制 SDK 迟到、释放未完成及 leaving 状态，用测试配置确定性触发超时。成功后运行页面断言；断言通过后统一截图并逐张查看。测试脚本逐步输出操作、预期、实际、是否通过和截图路径，报告从这些产物组装。', '',
  `E2E 累计预算 ${budget.limitMs / 60000} 分钟，起点 ${new Date(budget.started).toISOString()}，期间未重置。`, '',
  '## 结果', '',
  `夹具冒烟 ${summary.smokePassed} 通过 / ${summary.smokeFailed} 失败；定向回归 ${summary.testsPassed} 通过 / ${summary.testsFailed} 失败（包含前述冒烟，不重复相加）；页面 ${summary.uiPassed} 步通过 / ${summary.uiFailed} 步失败；截图轮 ${summary.visualStepsPassed} 步通过 / ${summary.visualStepsFailed} 步失败；静态分析${summary.analyze ? '通过' : '失败'}。`, '',
  '定向回归还验证首次失败后重试保持初始化，成功进入后再次媒体失败/重试保持成员网格可见、没有加载遮挡或后台连接提示。', '',
  '| 视口 | 操作 | 预期 | 实际 | 结果 |', '|---|---|---|---|---|',
  ...ui.map(row => `| ${row.viewport} | ${esc(row.operation)} | ${esc(row.expected)} | ${esc(row.actual)} | ${row.pass ? '通过' : '失败'} |`), '',
  '## 截图与视觉检查', '',
  '使用 Flutter 无头渲染截图替代 in-app browser。390×800 为窄视口，1200×800 为同一移动页面的桌面宽度布局，不能代表 Tauri 桌面端验收。以下截图均已实际逐张查看并记录 SHA-256。', '',
  '| 截图 | 实际检查 |', '|---|---|',
  ...visual.map(row => `| [${row.screenshot}](${row.screenshot}) | ${esc(reviews[row.screenshot].notes)} |`), '',
  '正常、初始化、超时错误、退出弹窗及关闭后的画面均覆盖。稳定帧未发现文字溢出、按钮截断、明显遮挡或层级错位；3、10 是退出弹窗淡出的瞬时过渡，只作为异步切换证据，不标为稳定视觉通过。聊天文件、抽屉、表格和设备权限未改动，不在本轮范围。', '',
  '## 清理与剩余风险', '',
  ...cleanup.map(row => `- ${esc(row.operation)}：${row.pass ? '完成' : '未完成'}；实际 ${esc(JSON.stringify(row.actual))}`), '',
  '未创建真实会议、下载录音或改动个人登录态。未执行 Android/iOS 真机和真实 IM/RTC 验收；平台未释放会话时仍可能等待至超时，不能靠页面改动缩短平台清理时间。本次源码修改需更新开发客户端或重新构建安装包后才会显示。', '',
  '报告由 mobile-meeting-entry-ready-report.mjs 从结构化结果生成，归档日志仅移除行尾空白，原始日志保留在 .artifacts/mobile-meeting-entry-ready/。', '',
].join('\n');
fs.writeFileSync(path.join(archive, '测试报告.md'), report);
console.log(JSON.stringify({report: path.join(archive, '测试报告.md'), ...summary}));
