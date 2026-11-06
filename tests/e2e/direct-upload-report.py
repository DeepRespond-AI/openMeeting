"""Assemble acceptance report from executed checks, traces and actual screenshot reviews."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser()
parser.add_argument('--out', type=Path, default=ROOT / '.artifacts/direct-upload-20261105')
args = parser.parse_args()
out = args.out
def load(name, default):
    file = out / name
    return json.loads(file.read_text(encoding='utf-8-sig')) if file.exists() else default
def log(name):
    file = out / name
    if not file.exists(): return ''
    raw = file.read_bytes()
    return raw.decode('utf-16' if raw.startswith(b'\xff\xfe') else 'utf-8-sig', errors='replace')
api = load('api-results.json', {})
web = load('browser-results.json', {})
reviews = load('visual-reviews.json', {})
cleanup = load('cleanup.json', {})
unit = ET.parse(out / 'unit-results.xml').getroot()
suites = list(unit.iter('testsuite'))
backend_failed = sum(int(s.get('failures', 0)) + int(s.get('errors', 0)) for s in suites)
backend_passed = sum(int(s.get('tests', 0)) - int(s.get('skipped', 0)) for s in suites) - backend_failed
mobile_events = [json.loads(line) for line in log('mobile-results.json').splitlines() if line.startswith('{')]
mobile_done = [r for r in mobile_events if r.get('type') == 'testDone' and not r.get('hidden') and not r.get('skipped')]
mobile_passed = sum(r['result'] == 'success' for r in mobile_done)
mobile_failed = sum(r['result'] != 'success' for r in mobile_done)
rust = re.search(r'test result: (\w+)\. (\d+) passed; (\d+) failed', log('rust-tests.log'))
rows = [('后端单元与存储回归', backend_passed, backend_failed, 'unit-results.xml'),
        ('桌面 Rust 传输契约', int(rust[2]) if rust else 0, int(rust[3]) if rust else 1, 'rust-tests.log'),
        ('移动端传输、导入、录音队列', mobile_passed, mobile_failed, 'mobile-results.json'),
        ('真实 API / PG / MinIO', api.get('passed', 0), api.get('failed', 1), 'api-results.json'),
        ('浏览器完整流程 / 两种视口', web.get('passed', 0), web.get('failed', 1), 'browser-results.json')]
checks = [('管理端类型检查及生产构建', 'built in' in log('admin-build.log'), 'admin-build.log'),
          ('移动端静态分析', 'No issues found!' in log('mobile-analyze.log'), 'mobile-analyze.log')]
total_pass = sum(r[1] for r in rows); total_fail = sum(r[2] for r in rows)
failures = []
for name in sorted(out.glob('*attempt-*.json')):
    attempt = load(name.name, {})
    failed = [s for s in attempt.get('steps', []) if not s.get('passed', s.get('pass', False))]
    if failed: failures.append((name.name, failed))
screens = web.get('screenshots', [])
reviewed = {s['path']: s for s in reviews.get('screenshots', [])}
lines = ['# 文件直传测试报告', '',
    '分级：跨端上传链路变更，执行完整用户流程及关键失败路径。真实运行独立 PostgreSQL、MinIO、修改后的 API 和 Vite 管理网页；合成 APK / WAV 仅用于字节校验，不执行安装。IM、STT 就绪检查和 ASR 任务调度为显式夹具。', '',
    f'最终执行结果：{total_pass} 项通过，{total_fail} 项失败；构建/静态检查 {sum(c[1] for c in checks)} 项通过、{sum(not c[1] for c in checks)} 项失败。前期失败单独保留，不计为通过。', '',
    '| 验证 | 通过 | 失败 | 原始产物 |', '|---|---:|---:|---|']
for label, passed, failed, artifact in rows: lines.append(f'| {label} | {passed} | {failed} | [{artifact}]({artifact}) |')
for label, passed, artifact in checks: lines.append(f'| {label} | {int(passed)} | {int(not passed)} | [{artifact}]({artifact}) |')
lines += ['', '## 环境与启动', '',
    '- 探测并保留日常 3118 / 39110 服务及登录态。本次使用隔离账号，无真实用户、业务数据库或 OSS 密钥。',
    '- PostgreSQL 16：127.0.0.1:35461，独立 direct_user / direct_meeting 数据库及临时卷；MinIO：39361，独立临时 Bucket。',
    '- `server/.venv/Scripts/python.exe tests/e2e/fixtures/direct-upload.py` 启动 API 39362；设置 `OPENMEETING_GATEWAY_URL=http://127.0.0.1:39362`，在 server/admin-web 用 `pnpm exec vite --host 127.0.0.1 --port 5186 --strictPort` 启动本次网页。',
    '- 先运行 `direct-upload-checks.py` 冒烟 PUT 503、确认 502；成功后运行 `node tests/e2e/direct-upload.mjs`。浏览器调试预算 30 分钟，本次未触发 API 降级。', '',
    '## 实际流程与证据', '']
for title, source in [('API', api), ('浏览器', web)]:
    lines += [f'### {title}', '', '| 操作 | 预期 | 实际 | 结果 |', '|---|---|---|---|']
    for step in source.get('steps', []):
        text = lambda value: str(value).replace('|', '\\|').replace('\n', ' ')
        lines.append(f"| {text(step['operation'])} | {text(step['expected'])} | {text(step['actual'])} | {'通过' if step['passed'] else '失败'} |")
lines += ['', '## 截图与人工视觉检查', '',
    '断言全部通过后统一截图，使用无头 Chromium；桌面 1440×960、窄窗口 390×844。实际检查弹层、加载、两类错误、重试成功、权限页面、长文件名省略、主区域和表格滚动；不把全页截图视为未滚动区域的通过证据。', '',
    '| 截图 | 视口 | 实际查看结论 |', '|---|---|---|']
for screen in screens:
    review = reviewed.get(screen['path'], {})
    verdict = review.get('result', '未查看，不标记视觉通过')
    lines.append(f"| [{screen['state']}]({screen['path']}) | {screen['viewport']['width']}×{screen['viewport']['height']} | {verdict} |")
lines += ['', '[视觉检查原始记录](visual-reviews.json) · [浏览器 trace](browser-trace.zip)', '', '## 前期失败与修正', '']
for name, steps in failures:
    lines.append(f'- [{name}]({name})：' + '; '.join(s['operation'] + '：' + str(s['actual']).replace('\n', ' ')[:300] for s in steps))
if (out / 'unit-head-fixture-failed.xml').exists():
    lines.append('- [OSS HEAD 异常夹具初次失败](unit-head-fixture-failed.xml)：测试构造 SDK NotFound 缺少 details 参数；补齐后 45 项全通过。')
if (out / 'mobile-duration-fixture-failed.json').exists():
    lines.append('- [移动端时长夹具初次失败](mobile-duration-fixture-failed.json)：给错误用例添加了 duration，成功用例未传测试值；修正夹具参数位置后重新执行通过。')
if (out / 'minio-startup-failure.log').exists():
    lines.append('- [MinIO 首次启动失败](minio-startup-failure.log)：非 root 用户无 tmpfs 写权限，改用 mode=1777 后真实 PUT/COPY/GET 通过。')
lines += ['- MinIO 原预签名 URL 不签元数据头，真实上传报错后改用 SDK 单请求头签名；最终覆盖元数据篡改拒绝和 MD5 内容不符拒绝。',
          '- 浏览器初次断言被上一次错误 toast 和流式 File 的空 postDataBuffer 干扰，已改为等待目标响应、检查完整请求头，并实际下载逐字节校验。旧失败结果保留。', '',
          '## 清理与验收边界', '', '```json', json.dumps(cleanup, ensure_ascii=False, indent=2), '```', '',
          '- 已验证对象内容绕过业务接口、确认前无索引、重复确认幂等、会话与资源范围、客户端失败保留源文件、本地/旧服务器回退。',
          '- 未执行生产 OSS PUT / CORS 验收、Android 真机或桌面安装版端到端，也未运行实际 ASR。两端为真实传输代码的定向契约测试，不能标为设备验收。',
          '- 未进行 2 GiB 边界文件、断点续传或长期弱网压测；整文件 PUT 最大 2 GiB，授权时限和临时前缀清理见对象存储指南。',
          '- 新版后端/管理网页及客户端需构建发布，目标 OSS 须配置 PUT CORS 和临时对象生命周期。本次没有部署生产或提交代码。', '', '## 脚本快照', '']
snapshot = out / 'scripts'; snapshot.mkdir(exist_ok=True)
for relative in ['tests/e2e/direct-upload.mjs', 'tests/e2e/direct-upload-checks.py', 'tests/e2e/direct-upload-report.py', 'tests/e2e/fixtures/direct-upload.py']:
    source = ROOT / relative; target = snapshot / source.name; shutil.copyfile(source, target)
    lines.append(f'- [{relative}](scripts/{source.name}) SHA-256 `{hashlib.sha256(target.read_bytes()).hexdigest()}`')
(out / '测试报告.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
print(json.dumps({'report': str(out / '测试报告.md'), 'passed': total_pass, 'failed': total_fail,
                  'screenshots': len(screens), 'reviewed': len(reviewed)}, ensure_ascii=False))
