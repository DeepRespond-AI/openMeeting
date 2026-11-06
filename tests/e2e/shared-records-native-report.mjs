import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const root = fileURLToPath(new URL('../../', import.meta.url));
const out = path.resolve(root, process.env.MEETING_READY_OUTPUT || '.artifacts/shared-records-native-e2e');
const archive = path.join(root, 'docs/testing/archive/自动录音合并后桌面回归');
const read = name => JSON.parse(fs.readFileSync(path.join(out, name), 'utf8'));
const base = process.argv.includes('--archive') ? archive : out;
fs.mkdirSync(base, { recursive: true });
const stages = ['smoke.json', 'native.json', 'failure-paths.json', 'offline.json'];
const native = stages.slice(1).flatMap(name => read(name).rows.map(row => ({ ...row, source: name })));
const page = read('pages/results.json'), pageCases = page.steps.filter(r => r.phase === 'assertions');
const smoke = [...read('smoke.json').rows, ...read('pages/smoke.json')];
const captures = [...read('visual.json').rows, ...read('offline-visual.json').rows].filter(r => r.screenshot).map(r => ({ ...r, viewport: r.actual.viewport }));
const pageCaptures = page.steps.filter(r => r.screenshot).map(r => ({ ...r, screenshot: 'pages/' + r.screenshot }));
const reviews = fs.existsSync(path.join(out, 'visual-reviews.json')) ? read('visual-reviews.json') : {};
const checks = read('checks.json'), budget = read('budget.json'), pageBudget = read('pages/budget.json');
const summary = rows => `${rows.filter(r => r.pass).length} 通过 / ${rows.filter(r => !r.pass).length} 失败`;
const clean = value => String(value ?? '').replaceAll('|', '/').replaceAll('\n', ' ');
const shots = [...captures, ...pageCaptures];
const history = fs.readdirSync(out).filter(name => /^(native|offline)-\d+\.json$/.test(name) && read(name).rows.some(r => !r.pass));
const pageHistory = fs.existsSync(path.join(out, 'pages/history')) ? fs.readdirSync(path.join(out, 'pages/history')).filter(name => read(`pages/history/${name}/results.json`).steps.some(r => !r.pass)) : [];
function cause(row) {
  if (row.actual?.includes("'ongoing'")) return '脚本状态名写错，契约为 active；更正后通过。';
  if (row.operation === '快速会议自动启用录音') return '连续重入超过最初15秒等待；补拍成员实际已入会，等待45秒后通过。未认定或修复延迟根因。首张失败图是房主视角。';
  if (row.operation === 'IM离线前创建实际参会关系') return '脚本未等IM就绪便访问客户端；增加ready等待。';
  if (row.operation === 'IM恢复后收到离线会后入口') return '实际产品缺陷：SDK已存离线通知，但应用只订阅实时事件。9ad65cb复用SDK历史/read_seq补显，实际离线复测通过。';
  return '见逐步错误与截图。';
}
const repoLink = file => path.relative(base, path.join(root, file)).replaceAll('\\', '/');
const lines = ['# 自动录音合并后桌面回归', '',
  '分级：自动录音、会后共享与真实通知链路的完整受影响流程。Windows新编译Tauri三端（房主、提前离会成员、非参会账号），真实Rust/鉴权/独立业务服务/PostgreSQL/IM/RTC；麦克风输入为显式合成音轨。另用Playwright无头Chromium与显式HTTP/IPC/IM/RTC夹具覆盖双视口页面、长转写/纪要和确定性错误。未使用in-app browser；原生截图通过CDP采集。', '',
  '结论：发现并修复IM离线恢复后漏显会后入口。IM持久化本身正常，应用原先仅监听实时消息；现在复用SDK notice历史与read_seq，最多补显三个会议的最新状态，点击后同步已读，不另建本地通知库。', '',
  `最终原生功能 ${summary(native)}；页面功能 ${summary(pageCases)}；独立冒烟 ${summary(smoke)}。截图阶段为重复复核，不重复计入功能用例。单元与代码检查见下面结构化结果。`, '',
  `E2E累计预算30分钟未重置；原生最后执行 ${(budget.usedMs / 60000).toFixed(1)} 分钟，页面最后执行 ${(pageBudget.usedMs / 60000).toFixed(1)} 分钟，共用起点 ${new Date(budget.firstStartedAt).toISOString()}。`, '',
  '启动：`meeting-ready-services.py --env <已有server/.env>` 启动隔离3160/3161/3167与出网3163，专用PostgreSQL55439；`meeting-ready-desktops.mjs --build` / `--start` 编译并启动Next3162和CDP9261/9262/9263。`shared-records-native.mjs --smoke`先单独核验故障，再依次运行无参数、`--failure-paths`、`--offline`。功能通过后运行`--visual`和`--offline-visual`统一截图。页面另运行`meeting-shared-records.mjs --smoke`及无参数，Next3164。具体环境/命令见[说明](' + repoLink('docs/development/shared-records-native-e2e.md') + ')。', '',
  '原服务探测：仅39110运行；3118、测试端口及原生CDP未监听，无可复用CDP登录态。原39110保持运行，原3118保持关闭。专用客户端复用其测试身份空间，读取原登录身份后仅替换既有im-ready测试账号；不触碰日常客户端。', '',
  '实际RTC票据、房主自动采集/分片上传、后端合成WAV、真实IM在线/离线通知、成员磁盘下载和WebView播放均通过；主流程未注入PCM分片。API独立冒烟另使用显式PCM。真实硬件、跨设备远端混音、系统目录弹出和生产发布包未验收。', '',
  '真实转写/纪要未验收成功：隔离环境语音识别模型未就绪，后端正确显示失败且保留音频。夹具的成功转写/纪要页面不作为真实模型通过。连续重入曾超过15秒等待，45秒内成功；这次未修复RTC释放延迟。', '',
  '| 分组 | 操作 | 预期 | 实际 | 结果 |', '|---|---|---|---|---|',
  ...native.map(r => `| ${r.source} | ${r.operation} | ${r.expected} | ${clean(JSON.stringify(r.actual))} | ${r.pass ? '通过' : '失败'} |`), '',
  '| 页面视口 | 操作 | 预期 | 实际 | 结果 |', '|---|---|---|---|---|',
  ...pageCases.map(r => `| ${r.viewport} | ${r.operation} | ${r.expected} | ${clean(r.actual)} | ${r.pass ? '通过' : '失败'} |`), '',
  '| 检查 | 实际 | 结果 |', '|---|---|---|',
  ...checks.map(r => `| ${r.operation} | ${clean(JSON.stringify(r.actual))}${r.log ? ` [日志](${r.log})` : ''} | ${r.pass ? '通过' : '失败'} |`), '',
  `最终截图 ${shots.length} 张，实际查看 ${shots.filter(s => reviews[s.screenshot]).length} 张，视觉通过 ${shots.filter(s => reviews[s.screenshot]?.pass).length} 张。桌面1280×800、窄视口520×760，核对遮挡、溢出、错位、截断、层级与换行；弹窗实际打开/关闭，长内容实际滚动。`, '',
  '| 截图 | 实际视觉记录 |', '|---|---|',
  ...shots.map(s => `| [${path.basename(s.screenshot)}](${s.screenshot}) | ${reviews[s.screenshot] ? `${reviews[s.screenshot].pass ? '通过' : '未通过'}：${reviews[s.screenshot].notes}` : '未实际查看，不标通过'} |`), '',
  '原生04/13下载错误图是显式503夹具；03/12的模型未就绪是真实隔离环境状态；离线恢复截图是真实IM历史补显，不是消息注入。页面夹具图片统一置于pages/screenshots。', '',
  '| 历史失败 | 原因与处理 | 截图 |', '|---|---|---|',
  ...history.flatMap(name => read(name).rows.filter(r => !r.pass).map(r => `| [${name}](history/${name}) / ${r.operation} | ${cause(r)} | ${r.screenshot ? `[失败截图](${r.screenshot})` : '无'} |`)),
  ...pageHistory.flatMap(name => read(`pages/history/${name}/results.json`).steps.filter(r => !r.pass).map(r => `| [页面历史${name}](pages/history/${name}/results.json) | 首次在当前工作树冷编译详情耗时11.4秒，原12秒导航等待超时；将导航等待设30秒，保留累计预算并复跑。 | [失败截图](pages/history/${name}/${r.screenshot}) |`)), '',
  '重入超时另见[成员随后已入会画面](screenshots/member-after-join-timeout.png)；离线缺陷证据另见[SDK就绪与已持久化消息探测](im-offline-probe.json)。历史失败未改成通过。', '',
  '清理：原生首轮清理先GET已结束房间，被服务端拒绝，未执行退出登录和该轮文件删除；原生清理失败保留[native-cleanup.json](native-cleanup.json)，已改为幂等end供下次使用，本轮没有重跑该脚本。随后经真实API会议ID匹配专用索引，仅删除本轮生成的WAV单文件，见[audio-cleanup.json](audio-cleanup.json)；空目录和测试配置缓存保留。平台资源及端口关闭结果见[cleanup.json](cleanup.json)、[platform-cleanup.json](platform-cleanup.json)。', '',
  '产物：[原生步骤](native.json) · [原生下载错误恢复](failure-paths.json) · [离线步骤](offline.json) · [页面逐步结果](pages/results.json) · [视觉检查](visual-reviews.json) · [编译来源](provenance.json)。原始音频、账号密码、票据和完整客户端日志不入Git。', ''];
fs.writeFileSync(path.join(base, '测试报告.md'), lines.join('\n'));
if (base === archive) {
  function copy(name, dest = name) { const target = path.join(base, dest); fs.mkdirSync(path.dirname(target), { recursive: true }); fs.copyFileSync(path.join(out, name), target); }
  for (const name of [...stages, 'visual.json', 'offline-visual.json', 'visual-reviews.json', 'budget.json', 'checks.json', 'cleanup.json', 'native-cleanup.json', 'audio-cleanup.json', 'platform-cleanup.json', 'im-offline-probe.json', 'provenance.json', 'pages/results.json', 'pages/smoke.json', 'pages/budget.json']) if (fs.existsSync(path.join(out, name))) copy(name);
  for (const name of ['unit.txt', 'typescript.txt', 'recording-contract.txt', 'im-contract.txt']) if (fs.existsSync(path.join(out, name))) fs.writeFileSync(path.join(base, name), fs.readFileSync(path.join(out, name), 'utf8').replace(/[\t ]+$/gm, ''));
  for (const s of shots) copy(s.screenshot);
  for (const name of history) { copy(name, 'history/' + name); for (const r of read(name).rows.filter(r => r.screenshot)) copy(r.screenshot); }
  copy('screenshots/member-after-join-timeout.png');
  for (const name of pageHistory) { copy(`pages/history/${name}/results.json`); for (const r of read(`pages/history/${name}/results.json`).steps.filter(r => r.screenshot)) copy(`pages/history/${name}/${r.screenshot}`); }
}
console.log(JSON.stringify({ report: path.join(base, '测试报告.md'), native: summary(native), pages: summary(pageCases), smoke: summary(smoke), screenshots: shots.length }));
