// Assemble evidence only. This command never starts tests or changes pass/fail.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const out = path.resolve(__dirname, '../../../.artifacts/mobile-desktop-parity');
const read = file => JSON.parse(fs.readFileSync(path.join(out, file), 'utf8'));
const sha = file => crypto.createHash('sha256').update(fs.readFileSync(path.join(out, file))).digest('hex');
const count = rows => ({passed: rows.filter(r => r.passed === true).length, failed: rows.filter(r => r.passed === false).length});
const cell = value => (typeof value === 'string' ? value : JSON.stringify(value)).replaceAll('|', '\\|').replace(/[\r\n]+/g, ' ');
const link = file => `[${file}](${encodeURI(file)})`;
const decode = file => {
  const b = fs.readFileSync(file);
  return b[0] === 255 && b[1] === 254 ? b.subarray(2).toString('utf16le') : b.toString('utf8').replace(/^\uFEFF/, '');
};

// PowerShell redirects may be UTF-16. Normalize local logs and redact credentials
// before linking them. Private account files remain ignored and are never quoted.
const secrets = fs.existsSync(path.join(out, 'accounts.private.json'))
  ? read('accounts.private.json').flatMap(a => [a.password, a.token]).filter(s => typeof s === 'string' && s.length > 5) : [];
for (const dir of [out, path.join(out, 'logs')]) {
  for (const name of fs.readdirSync(dir).filter(n => /\.(txt|log)$/.test(n))) {
    const file = path.join(dir, name);
    let text = decode(file);
    for (const secret of secrets) text = text.split(secret).join('[REDACTED]');
    text = text.replace(/Bearer\s+[A-Za-z0-9._~+\/-]+=*/gi, 'Bearer [REDACTED]')
      .replace(/eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+/g, '[JWT REDACTED]')
      .replace(/https?:\/\/[^\s"'<>]+\?(?=[^\s"'<>]*(?:signature|token|credential|X-Amz|X-Goog|jwt)=)[^\s"'<>]+/gi, url => url.split('?')[0] + '?[SIGNED QUERY REDACTED]');
    fs.writeFileSync(file, text);
  }
}

const probe = read('probe.json'), budget = read('budget-outcome.json');
const api = read('api-results.json'), fixture = read('fixture-smoke.json');
const ui = read('ui-results.json'), extra = read('supplemental-capture.json');
const visual = read('visual-reviews.json'), cleanup = read('cleanup.json');
const platform = read('platform-cleanup.json');
const checks = read('checks.json');
// Derive text-based check outcomes from the actual completed logs, including the
// serial retry. A prior failed parallel run is separately retained below.
for (const row of checks) {
  if (row.file) {
    row.action = row.packageName.endsWith('.parity') ? '隔离应用 debug APK' : '日常应用 debug APK';
    row.log = row.packageName.endsWith('.parity') ? 'logs/android-build-final.txt' : 'logs/normal-android-build.txt';
    row.passed = /Built build/.test(decode(path.join(out, row.log))) && sha(row.file) === row.sha256;
  } else if (row.log === 'logs/analyze-final-pass.txt') {
    row.action = '最终静态检查'; row.passed = /No issues found!/.test(decode(path.join(out, row.log)));
  } else if (row.log === 'logs/all-unit-tests-serial.txt') {
    row.action = '最终串行全量 Flutter 测试';
    const match = /\+(\d+): All tests passed!/.exec(decode(path.join(out, row.log)));
    row.passed = !!match; row.passedCount = match ? Number(match[1]) : 0;
    row.failedCount = match ? 0 : null;
  } else {
    row.action = '注解代码生成'; row.passed = /succeeded|built with build_runner/i.test(decode(path.join(out, row.log)));
  }
}
fs.writeFileSync(path.join(out, 'checks.json'), JSON.stringify(checks, null, 2));
for (const review of visual) {
  if (review.inspected !== true || sha(review.screenshot) !== review.sha256) {
    throw Error('Missing/changed visual evidence: ' + review.screenshot);
  }
}
const summary = {
  generatedAt: new Date().toISOString(), branch: probe.branch, base: probe.base,
  primaryValidation: budget.primaryValidation, completedWithinE2eBudget: budget.assertionsCompletedAtDeadline,
  unit: {passed: checks.find(r => r.passedCount)?.passedCount ?? 0, failed: checks.find(r => r.passedCount)?.failedCount},
  fixture: count(fixture), api: count(api), uiSupplementalOutsideBudget: count(ui),
  componentVisualCapture: count(extra), inspectedScreenshots: visual.length, visual: count(visual),
  checks: count(checks), cleanup: count(cleanup), nativeDeviceE2eExecuted: false,
  syntheticPcm: true, nativeMicrophoneCaptureVerified: false,
  realModelVerified: false, applicationInstalledOrReplaced: false,
};
fs.writeFileSync(path.join(out, 'summary.json'), JSON.stringify(summary, null, 2));
const lines = [
  '# Flutter 桌面功能对齐测试报告', '',
  '> 本报告由 `node tests/e2e/mobile-parity/report.cjs` 根据结构化步骤、运行日志和实际看图记录生成。', '',
  '本次属于完整功能集成，目标包括录制控制、PCM 上传、会后录音、会议专属 IM、待开始列表和日期/时间选择。主断言未在累计 30 分钟预算内全部完成，已降级为 **API 级验证为主**。最后一次已经运行的 Flutter 页面任务随后完成，仅作为补充证据；本轮没有安装或启动新 APK 到平板，不能视为真机端到端通过。', '',
  `分支：\`${probe.branch}\`；基线：\`origin/develop@${probe.base}\`；worktree：\`${probe.worktree}\`。原主工作区及其未提交改动保留。`, '',
  '## 结果', '',
  '| 层级 | 通过 | 失败 | 说明 |', '|---|---:|---:|---|',
  `| 最终串行 Flutter 单元/组件测试 | ${summary.unit.passed} | ${summary.unit.failed} | 包括原有回归；显式 opt-in 的网络/原生脚本不在此数量中 |`,
  `| 失败夹具独立冒烟 | ${summary.fixture.passed} | ${summary.fixture.failed} | 先于页面运行，故障重复触发三次 |`,
  `| API 降级验证 | ${summary.api.passed} | ${summary.api.failed} | 真实隔离业务服务、数据库、平台 IM 和录音处理任务 |`,
  `| Flutter 页面补充证据 | ${summary.uiSupplementalOutsideBudget.passed} | ${summary.uiSupplementalOutsideBudget.failed} | 32 条主断言 + 32 条截图回放，最终完成已超预算 |`,
  `| 弹窗视觉补拍步骤 | ${summary.componentVisualCapture.passed} | ${summary.componentVisualCapture.failed} | 生产组件 + 静态状态，不补记为业务 E2E |`,
  `| 实际看图 | ${summary.visual.passed} | ${summary.visual.failed} | 共 ${visual.length} 张；原始 6 张未拍到目标弹窗，保留失败并另补拍 6 张 |`,
  `| 静态/生成/Android 构建 | ${summary.checks.passed} | ${summary.checks.failed} | 两个 APK 仅编译，均未安装 |`,
  `| 清理 | ${summary.cleanup.passed} | ${summary.cleanup.failed} | 隔离服务/数据库/守护进程已关闭，39110 日常网关保留 |`, '',
  '上述层级分别计数，不能相加为一套全端验收通过数。历史失败没有从记录中抹除。', '',
  '## 启动方式、隔离与预算', '',
  '先读取项目设计规范、启动说明和测试目录规则，探测 39110 网关、Docker 服务及无线 ADB。已有专用桌面测试登录态返回 401；没有覆盖平板原应用登录态。本次启动独立 PostgreSQL 容器 `openmeeting-mobile-parity-postgres`（55439）、3160 网关、3161 用户服务、3167 会议服务、3163 出站代理；配置复用已有 IM 平台，账号和业务库隔离。启动脚本：`tests/e2e/meeting-ready-services.py`。故障代理 39330、桥接 39331；源代码与复现前提见 [脚本说明](../../tests/e2e/mobile-parity/README.md)。', '',
  '日常在本分支启动开发版（本轮已验证编译，未执行下列真机启动）：', '',
  '```powershell',
  'cd <repo>\\mobile',
  'adb connect <device-id>',
  'adb reverse tcp:39110 tcp:39110',
  'flutter run -d <device-id> --dart-define=APP_ENV=dev --dart-define=OPENMEETING_SERVER_URL=http://127.0.0.1:39110',
  '```', '',
  '若终端没有 Flutter/ADB 的 PATH，使用 `<flutter-sdk>/bin/flutter.bat` 和 Android SDK 的 `platform-tools/adb.exe`。不设置 debug suffix 时应用 ID 仍为 `cn.deeprespond.meeting`。', '',
  `E2E 首次尝试：${budget.firstAttempt}；截止：${budget.deadline}（UTC）。${budget.observedAt} 只观测到 ${budget.mainAssertionsObservedThen}/32 条主断言。此后不再重试业务 E2E；已有任务收集完成结果后，执行 API 验证、静态/单元/构建检查及纯视觉补拍。没有重置预算。${link('e2e-budget.json')}、${link('budget-outcome.json')}。`, '',
  '页面由 Flutter 无头渲染器运行生产 App、路由和组件，连接真实 REST/WS/IM；VM 平台适配器替代原生 SDK 宿主，安全存储/偏好为测试适配器，音频播放器为显式 VmPlayback。它证明界面与网络流程，不能证明摄像头、麦克风、系统权限、原生音视频播放或后台通话。屏幕尺寸：390×844、1024×768，加载中文字体；无法使用 in-app browser，采用 Flutter 无头截图。', '',
  '## 构建与回归证据', '',
  '| 检查 | 结果 | 证据 |', '|---|---|---|',
  ...checks.map(r => `| ${cell(r.action)} | ${r.passed ? '通过' : '失败'}${r.packageName ? `；\`${r.packageName}\`；${r.bytes} bytes；未安装` : ''} | ${link(r.log)} |`), '',
  'APK 仅在忽略目录中，不纳入提交；SHA-256、包标识和体积见 checks.json。新依赖 video_player 已完成 Android 编译，但本轮未验证真机视频播放。', '',
  '## 失败夹具与 API 流程', '',
];
function table(rows) {
  lines.push('| 操作 | 预期 | 实际 | 结果 | 截图 |', '|---|---|---|---|---|');
  for (const row of rows) lines.push(`| ${cell(row.action)} | ${cell(row.expected ?? '')} | ${cell(row.actual)} | ${row.passed ? '通过' : '失败'} | ${row.screenshot ? link(row.screenshot) : '无'} |`);
  lines.push('');
}
lines.push('### 页面前独立冒烟', ''); table(fixture);
lines.push('### API 降级验证', ''); table(api);
lines.push(
  '**音频证据边界：** 输入为明确合成的 PCM 静音，不是真实麦克风。真实 worker 保存 48,044 字节 RIFF/WAV，metadata.has_audio=true。处理状态实际为 failed，原因是隔离测试环境没有可用语音识别模型；验证的是失败原因可见、录音仍保存，不是转写/纪要成功。真实模型效果和原生 PCM 回调均未通过本轮验收。', '',
  '## Flutter 页面流程（超预算补充证据）', '',
  '主断言先执行，完成后统一截图回放。覆盖首页、独立日期/时间选择、无效表单、未来一年预定搜索、搜索空态、日程错误恢复、入会媒体不可用、录制权限拒绝/开始等待音轨/停止、真实会议 IM 鉴权失败恢复与 SDK 文字发送、结束失败恢复、会后录音及处理失败状态。没有覆盖完整联系人/群管理、文件选择器、图片放大、视频播放、每种异步加载瞬间或系统权限拒绝恢复。', '',
); table(ui);
lines.push('### 弹窗视觉补拍', '', '原截图的日期、时间和结束确认共 6 张仅拍到过渡背景，组件存在断言不能代替可见性证据。下表是仅视觉的独立组件补拍，实际等待绘制完成后截图，再关闭弹窗。', ''); table(extra);
lines.push('## 逐图视觉检查', '', '全部实际查看：原 32 张通过 8 张 2×2 联系表逐图检查；补拍 6 张逐张查看完整原图。检查布局、文字、滚动区域、弹层层级与响应式。SHA-256 校验保证报告对应已查看文件。Flutter 测试默认关闭阴影造成的黑色描边是测试渲染差异；补拍壳右上角调试条也不是生产 App 页面。', '',
  '| 图片 | 视口 | 实际查看方法 | 结果 | 观察 |', '|---|---|---|---|---|',
  ...visual.map(r => `| ${link(r.screenshot)} | ${r.viewport.join('×')} | ${cell(r.method)} | ${r.passed ? '通过' : '失败/采集不足'} | ${cell(r.notes)} |`), '',
  '## 失败历史与未执行项', '',
  '- 页面尝试 01：测试缺少 ClientInfo import；02：网络完成后测试未持续 pump 导致超时；03：搜索断言同时匹配输入框与卡片；04：工作目录不正确；05：弹层过渡尚未完成就点击；06：VM 缺少 just_audio 插件。均保留失败日志；修正的是测试适配器/同步，未伪造成功。最终尝试 07 完成，但已超累计预算。',
  '- 第一轮录音队列测试把重试次数限定为 2，实际自动重试加最终 flush 可能为 3；修正为检查全部尝试的 ID、字节、epoch 一致。最后并行全量运行曾有 3 个失败项：新增视觉测试缺少 unawaited import 导致加载失败，以及原有录音后台同步测试的时序失败。修正 import 后，最终串行全量 230 项通过；不能把先前并行结果写成通过。',
  '- Android 曾遇到 Gradle 下载中断、Kotlin DSL 缓存/插件解析失败及 sqlite3 下载中断。隔离 Gradle 缓存、复用并校验已有 sqlite3 构建资源后，两种 debug APK 构建成功；没有修改已安装的 Flutter SDK。缓存来源见 native-cache-provenance.json。',
  '- 静态检查中发现 provider 返回 ChangeNotifier 类型不受 Riverpod lint 支持，改为普通 ImVideoSession 包装；最终检查零问题。视频功能只有编译/静态证据，无原生播放结果。',
  '- 无线 ADB 曾离线，结束时恢复在线；本轮未安装新包、未改系统显示/旋转、未启动原生 integration_test。历史其他分支的真机通过不能替代本轮结果。',
  '- 仍未实现移动端独立屏幕共享、完整发言人/网络统计、后台推送和系统来电。iOS、长会、多机真实音画、OS 权限恢复、主持人退出后的录制接续、异常退出内存录音恢复及真实 STT/LLM 均未验收。', '',
  '历史证据：', '',
  ...['ui-attempt-01.txt','ui-attempt-02.txt','ui-attempt-03.txt','ui-attempt-04.txt','ui-attempt-05.txt','ui-attempt-06.txt','units-attempt-01.txt','all-unit-tests-final.txt','android-build-attempt-02.txt','android-build-attempt-03.txt','android-build-attempt-04.txt','android-build-attempt-05.txt','analyze-final.txt'].filter(f => fs.existsSync(path.join(out,'logs',f))).map(f => `- ${link('logs/'+f)}`), '',
  '## 结束与清理', '',
  '| 操作 | 结果 | 实际 |', '|---|---|---|',
  ...cleanup.map(r => `| ${cell(r.action)} | ${r.passed ? '通过' : '失败'} | ${cell(r.actual)} |`), '',
  `隔离 IM 平台清理：删除 ${platform.groupsDeleted} 个测试群、${platform.usersDeleted} 个测试用户，${platform.alreadyAbsent.length} 个用户原本已不存在；错误 ${platform.errors.length}。只按本轮所有权账本清理。日常网关、Docker 业务服务及平板原应用保留，已恢复 adb reverse 39110。`, '',
  '## 原始结构化产物', '',
  ...['summary.json','probe.json','checks.json','fixture-smoke.json','api-results.json','ui-results.json','supplemental-capture.json','visual-reviews.json','budget-outcome.json','cleanup.json','platform-cleanup.json','native-cache-provenance.json'].map(link), '',
);
fs.writeFileSync(path.join(out, '测试报告.md'), lines.join('\n'));
console.log(JSON.stringify(summary, null, 2));
