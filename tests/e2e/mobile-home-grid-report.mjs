// Assemble the report from executed steps, logs, cleanup and explicitly reviewed pixels.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../../', import.meta.url));
const out = path.resolve(root, process.argv[2] ?? '.artifacts/mobile-home-grid-20261028');
if (!out.startsWith(path.join(root, '.artifacts') + path.sep)) throw Error('Invalid evidence path');
const read = (name, fallback = null) => fs.existsSync(path.join(out, name))
  ? JSON.parse(fs.readFileSync(path.join(out, name), 'utf8').replace(/^\uFEFF/, '')) : fallback;
const log = name => {
  const bytes = fs.readFileSync(path.join(out, name));
  return bytes.toString(bytes[0] === 255 ? 'utf16le' : 'utf8');
};
const vm = read('vm-results.json', []), native = read('android-accepted-results.json', []);
const rows = [...vm, ...native], assertions = rows.filter(r => r.phase === 'assertions');
const reviews = read('visual-reviews.json', []);
const shots = fs.readdirSync(path.join(out, 'screenshots')).filter(f => f.endsWith('.png'));
for (const name of shots) {
  const file = `screenshots/${name}`, record = reviews.find(r => r.file === file);
  const hash = crypto.createHash('sha256').update(fs.readFileSync(path.join(out, file))).digest('hex');
  if (!record?.viewed || record.sha256 !== hash) throw Error(`Screenshot has not been reviewed: ${file}`);
}
const budget = read('budget.json'), finished = read('execution-finished.json');
const units = Number(/\+(\d+): All tests passed!/.exec(log('units-final-03.log'))?.[1] ?? 0);
const summary = {
  generatedAt: new Date().toISOString(), unitPassed: units,
  assertionPassed: assertions.filter(r => r.pass).length, assertionFailed: assertions.filter(r => !r.pass).length,
  replayPassed: rows.filter(r => r.phase === 'screenshots' && r.pass).length,
  nativePassed: /All tests passed/.test(log('android-04.log')),
  screenshots: shots.length, visualPassed: reviews.filter(r => r.pass && r.viewed).length,
  visualFailed: reviews.filter(r => r.viewed && !r.pass).length,
  acceptedNativeRun: 'android-04.log', supplementalCapturePassed: false,
  staticClean: /No issues found/.test(log('analyze-final.log')),
  elapsedMs: finished.finished - budget.started, budgetLimitMs: budget.limitMs,
};
fs.writeFileSync(path.join(out, 'summary.json'), JSON.stringify(summary, null, 2));
const cell = value => String(value ?? '').replaceAll('|', '\\|').replaceAll('\n', ' ');
let md = `# 移动端首页与会中自适应布局测试报告\n\n自动生成：${summary.generatedAt}。生成器：tests/e2e/mobile-home-grid-report.mjs。\n\n分级：页面结构与布局调整，采用完整受影响用户流程及关键失败恢复；无后端/媒体协议修改。实际生产首页、录音转写、录音/导入、预定表单、会中界面及路由参与执行，身份、业务仓库、媒体授权轨道及录音空闲状态为明确夹具。不是新的真实 RTC/硬件录音验收。\n\n`;
md += `结果：单元 ${units} 通过；页面断言 ${summary.assertionPassed} 通过 / ${summary.assertionFailed} 失败；截图复演 ${summary.replayPassed} 项通过（不重复累计）；第04次 Android 完整运行通过：${summary.nativePassed}。最终截图 ${summary.screenshots} 张全部实际查看，视觉通过 ${summary.visualPassed} 张，未通过 ${summary.visualFailed} 张。后续补拍未完成，不能称为整体视觉验收通过。静态分析：${summary.staticClean}。\n\n`;
md += '## 基线与启动\n\n阅读 CONTRIBUTING.md、quickstart.md、mobile/README.md、mobile/DESIGN.md 和桌面首页/网格实现。最新 origin/develop=d201c2f，新 worktree/分支为 openmeeting-mobile-home-grid / feat/mobile-home-grid。保留主目录已有未提交修改；保留 39110/3118 日常服务、原 Android 包与登录数据。探测记录见 [environment-before.json](environment-before.json)。\n\n';
md += '```powershell\n# mobile 目录；既有 Flutter 3.47 工具链、pub.flutter-io.cn 镜像，依赖锁不升级\n$env:HOME_GRID_CAPTURE="1"\nflutter test --no-pub test/acceptance/home_grid_ui_test.dart --reporter expanded\nflutter test --no-pub test/features/live_meeting/home_grid_test.dart test/features/live_meeting/schedule_filter_test.dart test/core/router/route_guard_test.dart --reporter expanded\n# 根目录，独立 loopback 39352 收集器；设备按实际连接填写\n$env:OPENMEETING_CORE_ARTIFACT_DIR=".artifacts/mobile-home-grid-20261028"\n$env:OPENMEETING_E2E_DEVICE="emulator-5582"\n$env:OPENMEETING_E2E_BRIDGE_PORT="39352"\n$env:OPENMEETING_E2E_PACKAGE="cn.deeprespond.meeting.homegridtest"\nnode tests/e2e/mobile-core-bridge.mjs\nadb -s emulator-5582 reverse tcp:39352 tcp:39352\n# mobile 目录；OPENMEETING_ANDROID_DEBUG_SUFFIX=.homegridtest\nflutter test --no-pub integration_test/home_grid_test.dart -d emulator-5582 --dart-define=APP_ENV=dev --reporter expanded\n```\n\nAndroid 构建使用 Android Studio jbr、GRADLE_USER_HOME=<gradle-cache>，子进程去除代理并设置 loopback NO_PROXY。ADB 映射在 Flutter 启动期间恢复。先独立两次触发列表/保存503，再恢复夹具，随后才运行页面。每个平台先完整断言，通过后复演截图。\n\n';
md += `## 逐步结果\n\n| 平台/视口/阶段 | 操作 | 预期 | 实际 | 通过 | 截图 |\n|---|---|---|---|---|---|\n`;
for (const r of rows) md += `| ${cell(r.platform)} ${cell(r.viewport)} ${cell(r.phase)} | ${cell(r.operation)} | ${cell(r.expected)} | ${cell(r.actual)} | ${r.pass ? '是' : '否'} | ${r.screenshot ? `[截图](${r.screenshot})` : '—'} |\n`;
md += '\n## 实际截图检查\n\n无 in-app browser，使用 Flutter 无头视口 390×844 / 1024×768 和 Android 原生 ADB 截图。覆盖加载、成功、空态、错误重试、长主题、预定弹层展开/关闭及滚动、录音转写入口、2/3/5/18 人舞台和多人滚动。网格断言另覆盖1/9人及组件身份保留。权限和真实摄像头视频帧未改动，未声明本轮已验收；邀请复制在无头环境为剪贴板夹具、Android 为系统剪贴板。\n\n| 截图 | PNG实际尺寸 | 视觉通过 | 逐张检查 |\n|---|---|---|---|\n';
for (const r of reviews) md += `| [${path.basename(r.file)}](${r.file}) | ${r.width}×${r.height} | ${r.pass ? '是' : '否'} | ${cell(r.note)} |\n`;
md += `\n## 失败历史及边界\n\n- 首轮网格单元发现3人竖屏被排成单列，已调整空位评分；最终单元全部通过。见 [units.log](units.log)。\n- 首轮页面脚本滚动后未等待布局，点击落在屏幕外；修正后通过。见 [ui-01.log](ui-01.log)、[ui-01-results.json](ui-01-results.json)。\n- 首轮功能断言虽通过，但实际截图发现新中文资源写成问号，视觉不通过；已保留 [历史截图和步骤](history/visual-01/)，修正UTF-8资源并增加明确中文断言，重新生成中英文资源、构建和验收，不将旧截图计入最终通过。\n- [android-02.log](android-02.log) 为重跑时原 emulator-5554 已退出，未执行页面，不能算通过。随后启动独立只读 Pixel_7 / emulator-5582，结束后仅关闭本轮实例；原应用数据不清除。\n- 代码生成初次遇到SQLite下载连接中断，使用已有镜像依赖重试成功；保留 [生成日志](codegen.log)。没有修改SDK/第三方缓存源码。\n- E2E累计 ${Math.round(summary.elapsedMs/1000)} / ${Math.round(summary.budgetLimitMs/1000)} 秒，失败和截图复查均使用原始预算，不重置。\n- 媒体来自显式无轨道业务夹具。真实摄像头填充使用既有 cover 渲染，真实采集、跨端RTC、屏幕共享像素及后台录音不在本轮结论内。\n\n`;
md += `补拍限制：Android 第5张图有输入法浮动栏遮住日期/时间局部，第12张图的系统剪贴板预览遮住部分底部导航，两张均标记视觉未通过。尝试收起输入法补拍时，[05](android-05.log) 出现 VmServiceDisappearedException，[06](android-06.log) 和 [07](android-07-drive.log) 连接等待后停止，[08](android-08-drive.log) 出现 DriverError，仅执行了5个步骤；[部分结果](android-08-partial-results.json) 不计作完整流程通过。保留第04次已完成的19个原生断言与截图复演，补拍策略未验证，已撤销该策略和替代启动脚本；交付脚本恢复为第04次实际通过的标准入口。预算内停止调试，无后续 E2E 重试。\n\n`;
md += `证据：[无头最终日志](ui-final-03.log)、[Android接受的完整运行](android-04.log)、[单元](units-final-03.log)、[静态分析](analyze-final.log)、[无头步骤](vm-results.json)、[Android完整步骤](android-accepted-results.json)、[最近尝试的原始步骤](android-results.json)、[截图SHA-256及检查记录](visual-reviews.json)。\n\n## 清理与恢复\n\n[cleanup.json](cleanup.json)\n\n\`\`\`json\n${JSON.stringify(read('cleanup.json', {}), null, 2)}\n\`\`\`\n`;
fs.writeFileSync(path.join(out, '测试报告.md'), md);
console.log(JSON.stringify(summary));
