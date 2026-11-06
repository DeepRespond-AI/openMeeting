// Assemble the report from step JSON, runner logs and reviewed image hashes.
import fs from 'node:fs';
import path from 'node:path';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
const root = fileURLToPath(new URL('../../', import.meta.url));
const out = path.resolve(root, process.env.OPENMEETING_RETURN_HOME_OUTPUT || '.artifacts/meeting-return-home');
const json = file => JSON.parse(fs.readFileSync(path.join(out, file), 'utf8'));
const log = file => {
  const bytes = fs.readFileSync(path.join(out, file));
  return bytes.subarray(0, 2).equals(Buffer.from([255, 254])) ? bytes.subarray(2).toString('utf16le') : bytes.toString('utf8');
};
const desktop = json('desktop-results.json'), mobile = json('mobile-results.json'), capture = json('mobile-results-capture.json');
const reviews = json('visual-reviews.json'), checks = json('checks.json');
for (const review of reviews) {
  const actual = createHash('sha256').update(fs.readFileSync(path.join(out, review.file))).digest('hex');
  if (review.sha256 !== actual) throw Error(`Image changed after review: ${review.file}`);
}
const counts = rows => ({ passed: rows.filter(x => x.pass).length, failed: rows.filter(x => !x.pass).length });
const runner = file => /All tests passed!/.test(log(file)) && !/Some tests failed\./.test(log(file));
const unitCount = Number(log('logs/units.txt').match(/\+(\d+): All tests passed!/)?.[1] ?? 0);
const summary = {
  generatedAt: new Date().toISOString(),
  desktop: counts(desktop.steps.filter(x => x.phase === 'assertions')),
  desktopReplay: counts(desktop.steps.filter(x => x.phase === 'screenshots')),
  desktopRunnerPassed: desktop.runnerPassed,
  mobile: counts(mobile), mobileReplay: counts(capture),
  mobileRunnerPassed: runner('logs/mobile-assertions-02.txt'),
  mobileCaptureRunnerPassed: runner('logs/mobile-capture-final.txt'),
  units: { passed: unitCount, failed: /All tests passed!/.test(log('logs/units.txt')) ? 0 : 1 },
  visual: { inspected: reviews.length, passed: reviews.filter(x => x.pass).length, failed: reviews.filter(x => !x.pass).length },
  checks, cleanup: desktop.cleanup,
  nativeHardwareExecuted: false, productionBackendExecuted: false,
};
fs.writeFileSync(path.join(out, 'summary.json'), JSON.stringify(summary, null, 2));
const escape = text => String(text ?? '').replaceAll('|', '\\|').replaceAll('\n', '<br>');
const table = rows => [
  '| 平台/阶段/视口 | 操作 | 预期 | 实际 | 结果 | 截图 |', '|---|---|---|---|---|---|',
  ...rows.map(r => `| ${escape([r.platform, r.phase, r.viewport].filter(Boolean).join(' / '))} | ${escape(r.operation)} | ${escape(r.expected)} | ${escape(r.actual)} | ${r.pass ? '通过' : '失败'} | ${(r.screenshots ?? []).map(f => `[图片](${f})`).join(' ')} |`),
].join('\n');
const report = [
  '# 会议结束直接返回首页：测试报告',
  '',
  '分级理由：本次是小范围导航交互调整，采用桌面端真实开发页面 E2E、移动端生产路由/房间组件验收和全量移动单元回归。显式替换 HTTP/Tauri/IM/媒体、身份等边界；没有把夹具、VM 组件验收写成真机或真实后端通过。本轮不等于所有功能均无问题。',
  '', `生成时间：${summary.generatedAt}。分支 feat/mobile-desktop-parity，基线 ae00f96。`,
  '', '## 启动与流程', '',
  '先检查项目移动/桌面设计规则、现有服务和既有登录态。39110 日常网关保留；使用独立 Next :3196 和随机端口 HTTP 夹具，不覆盖已有账户。先单独执行失败夹具冒烟，再进行所有逻辑断言，通过后统一回放截图。两端累计调试预算见 [budget.json](budget.json)，没有重置时间。',
  '', '```powershell',
  'node tests/e2e/meeting-return-home.mjs --smoke',
  'node tests/e2e/meeting-return-home.mjs',
  '# mobile 目录；配置本机 Flutter PATH 和中国镜像',
  "$env:MEETING_RETURN_UI='1'",
  'flutter test test/acceptance/meeting_return_home_test.dart --reporter expanded',
  "$env:MEETING_RETURN_CAPTURE='1' # 全部断言通过后再统一截图回放",
  'flutter test test/acceptance/meeting_return_home_test.dart --reporter expanded',
  '# 清除上述 opt-in 变量后运行 flutter test --concurrency=1',
  '```', '',
  '桌面使用 Playwright Chromium，视口1280×800、390×844；移动使用 Flutter VM 生产路由和组件，视口1024×768、390×844。所有16张最终截图均通过 view_image 实际打开查看；没有 in-app browser，使用无头截图代替。',
  '', '## 最终结果', '',
  `桌面定向E2E ${summary.desktop.passed}通过/${summary.desktop.failed}失败；截图回放 ${summary.desktopReplay.passed}通过/${summary.desktopReplay.failed}失败，运行器 ${desktop.runnerPassed ? '通过' : '失败'}。`,
  `移动定向验收 ${summary.mobile.passed}通过/${summary.mobile.failed}失败；截图回放 ${summary.mobileReplay.passed}通过/${summary.mobileReplay.failed}失败，两个视口运行器均 ${summary.mobileRunnerPassed && summary.mobileCaptureRunnerPassed ? '通过' : '失败'}。`,
  `移动全量单元 ${unitCount}通过/${summary.units.failed}失败；最终视觉 ${summary.visual.passed}通过/${summary.visual.failed}失败。`,
  '', ...checks.map(c => `- ${c.name}：${c.pass ? '通过' : '失败'}（${c.actual}）。`),
  '', '## 逐步证据', '', table(desktop.steps), '', table(mobile), '', table(capture),
  '', '## 实际看图记录', '', '| 图片 | 视口 | 观察 | 结果 |', '|---|---|---|---|',
  ...reviews.map(r => `| [${path.basename(r.file)}](${r.file}) | ${r.viewport} | ${escape(r.notes)} | ${r.pass ? '通过' : '失败'} |`),
  '', '桌面原有 Toast 短暂覆盖顶部标题/日期，未遮住本轮确认和重试按钮；窄视口首页纵向滚动、标题省略符合原样式。移动弹窗文案换行和抽屉层级正常。夹具不提供录音协议，因此桌面显示服务器版本提示、移动显示媒体不可用/录音未激活；这些仅是导航测试边界，不能当作录音或媒体验收。',
  '', '## 历史失败保留', '',
  '- [首次夹具失败](logs/desktop-smoke-01-failed.json)：reset后修改了已脱离映射的状态，导致故障未生效。修复夹具状态替换后连续三次503及恢复200冒烟通过。',
  '- [首次桌面失败](logs/desktop-results-01-failed.json)：测试定位使用“结束会议”，真实工具栏文案为“离开并结束”；修正定位后全流程通过。保留[失败截图](screenshots/failure-1793062853395.png)。',
  '- [首次移动运行器失败](logs/mobile-assertions-01.txt)：测试未恢复绘制调试开关；组件步骤通过但框架收尾失败，不计整轮通过。修复测试清理后运行器通过。',
  '- [首次静态检查](logs/analyze.txt)有导入排序及多余类型转换问题；已修复，见[最终结果](logs/analyze-final.txt)。',
  '- 首次移动截图的窄视口首页品牌图片尚未解码；保留[原图](history/capture-01/mobile-02-390-home.png)，增加资产预加载后重新截图并逐张查看。',
  '', '## 清理与边界', '',
  `本轮资源清理：${JSON.stringify(desktop.cleanup)}。已有39110网关保留；最终端口检查见 checks.json。VM 测试容器和路由已销毁，无设备安装或登录态修改。`,
  '本轮只证明结束/离会后的路由行为、失败保留/重试和弹层关闭。未执行原生硬件采集、系统权限、音频上传、生产IM/RTC、后台、iOS或完整业务后端回归；上一轮会中消息超时的最终E2E复验仍不在本次结论内。',
  '', '## 原始产物', '',
  '[桌面结构化结果](desktop-results.json) · [移动结果](mobile-results.json) · [移动截图回放](mobile-results-capture.json) · [桌面日志](logs/desktop-attempt-02.txt) · [移动最终日志](logs/mobile-capture-final.txt) · [单元日志](logs/units.txt) · [静态检查](logs/analyze-final.txt) · [TypeScript检查](logs/typescript.txt) · [截图目录](screenshots/) · [机器摘要](summary.json)', '',
].join('\n');
fs.writeFileSync(path.join(out, '测试报告.md'), report);
console.log(JSON.stringify(summary));
