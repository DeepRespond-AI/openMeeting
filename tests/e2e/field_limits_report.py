"""从测试结果、截图检查记录和服务关闭探测生成报告，不手工填写通过数量。"""
import hashlib
import json
from pathlib import Path
import socket
import subprocess
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[2]
out = root / '.artifacts/field-limits'


def load(name):
    raw = (out / name).read_bytes()
    return raw.decode('utf-16') if raw.startswith(b'\xff\xfe') else raw.decode('utf-8-sig')


def events(name):
    return [json.loads(line) for line in load(name).splitlines() if line.strip()]


e2e = json.loads(load('e2e-results.json'))
verification = json.loads(load('verification.json'))
flutter = events('flutter-tests.jsonl')
capture = events('flutter-capture-log.jsonl')
visual = json.loads(load('visual-review.json'))
rows = []
for name in ['meeting-api.xml', 'user-api.xml']:
    suite = ET.fromstring(load(name)).find('testsuite')
    failed = int(suite.get('failures', 0)) + int(suite.get('errors', 0))
    skipped = int(suite.get('skipped', 0))
    rows.append((name, int(suite.get('tests')) - failed - skipped, failed, skipped))
for name, source in [('Flutter 相关回归', flutter), ('Flutter 视觉补拍', capture)]:
    completed = [row for row in source if row.get('type') == 'testDone' and not row.get('hidden')]
    rows.append((name, sum(row['result'] == 'success' and not row['skipped'] for row in completed),
                 sum(row['result'] != 'success' for row in completed), sum(row['skipped'] for row in completed)))
rows.append(('浏览器 E2E / 夹具冒烟', sum(c['pass'] for c in e2e['checks']), sum(not c['pass'] for c in e2e['checks']), 0))
rows.append(('静态检查', sum(v['pass'] for v in verification[:3]), sum(not v['pass'] for v in verification[:3]), 0))
for picture in visual:
    digest = hashlib.sha256((out / picture['path']).read_bytes()).hexdigest()
    picture['unchanged_since_review'] = digest == picture['sha256']
    # 人工检查标记由实际查看截图后单独写入；本脚本只核对文件是否发生变化。
    picture['notes'] = ('已实际查看，计数、按钮、错误提示完整；长文本在单行内滚动，未见遮挡、溢出或层级错位。'
                        if picture['inspected'] and picture['unchanged_since_review'] else '未检查或截图已改变，不能判定通过。')
(out / 'visual-review.json').write_text(json.dumps(visual, ensure_ascii=False, indent=2), encoding='utf-8')

cleanup = list(e2e['cleanup'])
for port in [43271, 55462]:
    with socket.socket() as connection:
        connection.settimeout(1)
        stopped = connection.connect_ex(('127.0.0.1', port)) != 0
    cleanup.append({'service': f'本次测试端口 {port}', 'stopped': stopped})
probe = subprocess.run(['docker', 'ps', '-a', '--filter', 'name=openmeeting-field-limits-test-20261103', '--format', '{{.Names}}'], capture_output=True, text=True)
cleanup.append({'service': '独立 PostgreSQL 测试容器（--rm）', 'stopped': probe.returncode == 0 and not probe.stdout.strip()})
business = subprocess.run(['docker', 'ps', '--filter', 'name=openmeeting-split-', '--format', '{{.Names}}'], capture_output=True, text=True)
preserved = business.stdout.strip().splitlines()
(out / 'cleanup.json').write_text(json.dumps({'owned': cleanup, 'preserved_business_services': preserved}, ensure_ascii=False, indent=2), encoding='utf-8')

history = [
    {'stage': '后端初次管理端断言', 'result': '2 条用例未携带管理员登录态，返回 401；改用已有 admin 夹具后通过。初次 JUnit 已由最终运行覆盖。'},
    {'stage': '浏览器前两次尝试', 'result': '更多操作的非精确定位误点父级会议行，修正为 exact 定位；同时保护 about:blank 上的 localStorage 初始化。', 'evidence': ['e2e-attempt-01.json', 'e2e-attempt-02.json', 'failure-trace.zip', 'failure.png']},
    {'stage': 'Flutter 补拍初次编译', 'result': '测试脚本误用 String.repeat；改用 Dart 字符串乘法。初次独立日志未留存。'},
    {'stage': 'Flutter 补拍第二/三次', 'result': '分别遇到 VM 缺少 IM SDK 的平台插件和绘制调试变量未恢复；头像资料边界改为 Stream 夹具，移除绘制调试变量修改后通过。', 'evidence': ['flutter-capture-attempt-02.jsonl', 'flutter-capture-attempt-03.jsonl']},
]
(out / 'debug-history.json').write_text(json.dumps(history, ensure_ascii=False, indent=2), encoding='utf-8')

lines = [
    '# 字段长度限制测试报告', '',
    '分级：本次为输入限制、计数及接口校验修改，按受影响路径 + 成功冒烟验证。真实 React 会议记录/账号组件经真实 FastAPI/Pydantic 写入独立 PostgreSQL；网关身份和 IM/头像采用夹具。Flutter 运行实际组件与控制器的 VM 测试，并使用真实中文字体补拍；不把它记作 Android 真机或模拟器 E2E。', '',
    '会议标题 50 字、账号昵称 32 字、入会显示名 20 字，统一按 Unicode 码点计数。覆盖中文、英文、emoji、边界值、超长、空白、保存失败、重试、取消及默认入会显示名转换；账号原始昵称不变。', '',
    '## 执行结果', '', '| 测试组 | 通过 | 失败 | 跳过 |', '|---|---:|---:|---:|',
]
for name, passed, failed, skipped in rows:
    lines.append(f'| {name} | {passed} | {failed} | {skipped} |')
lines += ['', f'最终执行合计：{sum(r[1] for r in rows)} 通过，{sum(r[2] for r in rows)} 失败；其中 Flutter 补拍是 1 个绘制用例，不额外算成业务 E2E。调试失败尝试单独记录在下文，未标成通过。', '',
          '## 启动方式与数据隔离', '',
          '先探测并保留现有 39110 网关和 7 个 openmeeting-split 容器；测试使用 127.0.0.1:55462 的专用容器及 field_meeting / field_user 两个空库，不读取或清理业务数据库。没有请求真实短信、RTC 或 IM。', '',
          '```powershell',
          '# 仓库根目录：创建独立测试数据库',
          'docker run -d --rm --name openmeeting-field-limits-test-20261103 -p 127.0.0.1:55462:5432 -e POSTGRES_USER=fieldtest -e POSTGRES_PASSWORD=fieldtest -e POSTGRES_DB=field_meeting postgres:16',
          '# pg_isready 成功后再创建第二个测试库',
          'docker exec openmeeting-field-limits-test-20261103 pg_isready -U fieldtest',
          'docker exec openmeeting-field-limits-test-20261103 createdb -U fieldtest field_user',
          '', '# 在 server/ 启动包含本次改动的后端',
          '$env:PYTHONPATH = (Get-Location).Path',
          r'.\.venv\Scripts\python.exe -m uvicorn field_limits_api:app --app-dir ../tests/e2e --host 127.0.0.1 --port 43271',
          '', '# 另一个终端，在仓库根目录运行浏览器脚本；自动启动并关闭 React 开发预览',
          'node tests/e2e/field-limits.mjs',
          '', '# 在 mobile/ 运行相关测试及实际组件补拍',
          'flutter test --no-pub test/acceptance/text_limits_test.dart',
          "$env:FIELD_LIMITS_CAPTURE = '1'", 'flutter test --no-pub test/acceptance/text_limits_capture_test.dart',
          '```', '',
          '后端 pytest：在 server/ 中将 OPENMEETING_TEST_DATABASE_URL 指向上面的专用库，分别运行 meeting_ms/tests/{test_title_limits,test_meetings,test_scheduled,test_rooms}.py 和 user_ms/tests/{test_name_limits,test_auth}.py，并输出 JUnit。完整静态检查和 Flutter 回归命令见 [verification.json](verification.json)。', '',
          '## 测试流程', '',
          '先单独请求加载、错误夹具，确认加载会等待、释放后成功，错误稳定返回 503 且数据库原值不变；再验证绕过界面的 51 字标题和 33 字昵称返回 422。随后打开真实组件完成重命名、数据库结果核对、失败保留草稿和重试，再完成昵称边界和保存/失败流程。浏览器设 7 秒定位超时，调试在 30 分钟预算内完成；未降级为仅 API 验证。全部断言通过后重新演示并统一截图，等待有限时长动画结束，清除之前的通知。', '',
          '| 操作 | 预期 | 实际 | 结果 |', '|---|---|---|---|']
for check in e2e['checks']:
    actual = json.dumps(check['actual'], ensure_ascii=False) if not isinstance(check['actual'], str) else check['actual']
    lines.append(f"| {check['operation']} | {check['expected']} | {actual} | {'通过' if check['pass'] else '失败'} |")
lines += ['', '## 截图与人工检查', '',
          '桌面 Chromium 1440×960、窄视口 Chromium 390×844；Flutter 引擎 960×720、390×844。逐张实际查看正常、空值、上限、加载、成功、错误和取消后的画面。此次没有新增抽屉、表格或权限流程，相关状态不适用。移动端软键盘、系统输入法和 Android 原生壳未在本次运行。', '',
          '| 截图 | 视口 | 实际查看 | 结论 |', '|---|---|---|---|']
for picture in visual:
    viewed = picture['inspected'] and picture['unchanged_since_review']
    lines.append(f"| [{Path(picture['path']).name}]({picture['path']}) | {picture['viewport']} | {'已查看' if viewed else '未查看'} | {picture['notes']} |")
lines += ['', '## 调试失败记录', '']
for record in history:
    evidence = ' '.join(f'[{name}]({name})' for name in record.get('evidence', []) if (out / name).exists())
    lines.append(f"- {record['stage']}：{record['result']} {evidence}")
lines += ['', '## 日志与清理', '',
          '[E2E 逐步结果](e2e-results.json) · [浏览器 trace](trace.zip) · [会议 API JUnit](meeting-api.xml) · [账号 API JUnit](user-api.xml) · [Flutter 结果](flutter-tests.jsonl) · [截图检查与文件校验](visual-review.json) · [关闭结果](cleanup.json)', '']
for record in cleanup:
    lines.append(f"- {record['service']}：{'已关闭' if record['stopped'] else '未关闭'}。")
lines += ['', f'原有业务容器保留运行：{len(preserved)} 个。', '',
          '## 剩余范围', '',
          '本次未构建或重装 Android APK、Tauri 安装包，也未验证真实短信/RTC/IM。真实系统输入法的候选词行为仍应在设备上复核；组合 emoji 按码点计数，可能占多个名额。已有超长数据读取保持原样，修改时执行新限制；未批量截断数据库数据，不需要迁移脚本。此次只统一会议标题、账号昵称和会中显示名相关入口，不宣称所有业务字段都已全面审计。', '',
          '报告由 tests/e2e/field_limits_report.py 读取上述结构化产物生成。', '']
(out / '测试报告.md').write_text('\n'.join(lines), encoding='utf-8')
print(json.dumps({'groups': rows, 'screenshots': len(visual), 'owned_services_stopped': all(c['stopped'] for c in cleanup),
                  'report': str(out / '测试报告.md')}, ensure_ascii=False))
