"""从 JUnit、逐步 JSON、截图人工检查记录及清理结果生成中文报告。"""
import hashlib
import json
from pathlib import Path
import re
import socket
import subprocess
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[2]
out = root / '.artifacts/minio-object-storage'


def load(name):
    raw = (out / name).read_bytes()
    return raw.decode('utf-16') if raw.startswith(b'\xff\xfe') else raw.decode('utf-8-sig')


def data(name):
    return json.loads(load(name))


groups = []
for filename in ['contract-tests.xml', 'meeting-tests.xml', 'user-tests.xml']:
    suite = ET.fromstring(load(filename)).find('testsuite')
    failures = int(suite.get('failures', 0)) + int(suite.get('errors', 0))
    skipped = int(suite.get('skipped', 0))
    groups.append((filename, int(suite.get('tests')) - failures - skipped, failures, skipped))
api, browser, persistence = data('api-results.json'), data('browser-results.json'), data('persistence-results.json')
for name, source in [('真实 MinIO/API', api), ('真实管理端 E2E', browser), ('独立容器/具名卷持久化', persistence)]:
    groups.append((name, sum(row['pass'] for row in source['checks']), sum(not row['pass'] for row in source['checks']), 0))
flutter = [json.loads(line) for line in load('flutter-tests.jsonl').splitlines() if line.strip()]
completed = [row for row in flutter if row.get('type') == 'testDone' and not row.get('hidden')]
groups.append(('移动端音频播放/下载兼容回归', sum(row['result'] == 'success' and not row['skipped'] for row in completed),
               sum(row['result'] != 'success' for row in completed), sum(row['skipped'] for row in completed)))
verification = data('verification.json')
groups.append(('管理端类型/Compose 校验', sum(row['pass'] for row in verification[:2]), sum(not row['pass'] for row in verification[:2]), 0))

visual = data('visual-review.json')
for picture in visual:
    picture['unchanged_since_review'] = hashlib.sha256((out / picture['path']).read_bytes()).hexdigest() == picture['sha256']
    picture['visual_pass'] = picture['inspected'] and picture['unchanged_since_review']

probe = subprocess.run(['docker', 'ps', '-a', '--filter', 'name=openmeeting-minio-test-postgres-20261103', '--format', '{{.Names}}'], capture_output=True, text=True)
with socket.socket() as connection:
    connection.settimeout(1)
    pg_stopped = connection.connect_ex(('127.0.0.1', 55464)) != 0
cleanup = api['cleanup'] + browser['cleanup'] + persistence['cleanup'] + [
    {'service': '独立 PostgreSQL 测试容器/端口', 'stopped': probe.returncode == 0 and not probe.stdout.strip() and pg_stopped}]
running = subprocess.run(['docker', 'ps', '--filter', 'name=openmeeting-split-', '--format', '{{.Names}} {{.Status}}'], capture_output=True, text=True)
(out / 'cleanup.json').write_text(json.dumps({'test_resources': cleanup, 'running_services': running.stdout.strip().splitlines()}, ensure_ascii=False, indent=2), encoding='utf-8')

# 早期 HTTPX 日志可能包含临时对象的签名 URL，移除所有 URL 查询串后再作为报告证据。
for filename in ['api.log', 'api-attempt-01.log']:
    path = out / filename
    if path.exists():
        cleaned = re.sub(r'(https?://[^\s?"<>]+)\?[^\s"<>]+', r'\1?[query-redacted]', load(filename))
        path.write_text(cleaned, encoding='utf-8')

history = [
    {'stage': 'MinIO 镜像', 'result': '官方 registry 拉取返回未授权；依据官方发布说明改为固定 release 源码构建。Go 官方模块代理首次下载中断，改用可配置 GOPROXY 后构建成功，保留 Go 校验机制。'},
    {'stage': '应用镜像', 'result': '官方 Debian 源下载出现延迟项循环；新增可选 HTTPS 镜像参数，配置中科大镜像后正常构建。没有关闭 Debian 签名或 TLS 校验。'},
    {'stage': 'OSS 对照回归', 'result': '首轮 2 条断言失败：错误文案兼容及转存后的空目录清理。保留具体后端名称，并区分会议私有目录与旧共享根目录音频后通过；另加共享目录不被误删回归。'},
    {'stage': '首次真实 MinIO API', 'result': '仅内部网络无法发布客户端下载端口，首次连接被拒绝。增加独立下载网络后，真实上传、权限、Range、EXE、合成录音和切换验收均通过。', 'evidence': 'api-attempt-01.log'},
    {'stage': '首轮视觉检查', 'result': '行为断言通过，但实际查看发现窄屏表单过窄、存储卡片标题竖排。修复标签上下布局及标题换行后重新截图；最终 12 张均已查看。', 'evidence': 'screenshots-initial/'},
]
(out / 'debug-history.json').write_text(json.dumps(history, ensure_ascii=False, indent=2), encoding='utf-8')

lines = ['# MinIO 对象存储测试报告', '',
    '分级：服务端存储与部署变更，执行真实 MinIO、出站代理、数据库及管理端流程，覆盖成功和关键失败路径。API 使用独立 PostgreSQL 与私有临时 Bucket；身份和服务间 HTTP 是明确的进程内边界夹具。管理端运行真实部署版本，错误和加载状态使用浏览器拦截；相关真实失败已先单独冒烟。', '',
    '安装包及音频为合成夹具；不把上传成功记作真实 RTC 采集、模型识别、APK/EXE 安装或 Tauri 签名验收。移动端只运行已有播放/下载适配回归，本次不启动真机或模拟器。', '',
    '## 结果', '', '| 组别 | 通过 | 失败 | 跳过 |', '|---|---:|---:|---:|']
for name, passed, failed, skipped in groups:
    lines.append(f'| {name} | {passed} | {failed} | {skipped} |')
lines += ['', f'最终共 {sum(row[1] for row in groups)} 项通过，{sum(row[2] for row in groups)} 项失败。调试中的失败与修复单独列出，没有计作通过。', '',
    '## 启动方式', '',
    '复用原有 Docker 部署及业务数据库，新增 MinIO 和一次性 Bucket 初始化任务。服务重建只针对修改涉及的 user_ms / meeting_ms / gateway_ms；保留原有 STT 模型服务运行。真实数据库测试另外使用 127.0.0.1:55464 的专用 PostgreSQL，未对业务库执行 pytest 清理。管理端无头上下文登录现有服务，不发送短信，不保存登录 trace、storageState 或密码。', '',
    '当前 MinIO S3 API 为 `http://localhost:39120`，本机控制台为 `http://127.0.0.1:39121`。Bucket 默认私有，根凭据仅保存在未提交的 `server/.env`。`minio-init` 已成功退出 0。', '',
    '源码镜像固定 MinIO release，Go 从官方获取并校验 SHA-256；本机使用 GOPROXY 镜像完成构建。应用使用可配置的 HTTPS Debian 镜像完成重建。具体部署、网络与切换说明见 [对象存储指南](../../docs/object-storage.md)。', '',
    '```powershell', '# 在 server/，首次启动包含 MinIO 的开发服务',
    'docker compose up -d --build', '', '# 仅修改 .env 切换存储时，重新创建相关应用容器，无须重建镜像',
    'docker compose up -d --no-deps gateway_ms meeting_ms user_ms', '', '# 独立数据库准备好后，从 server/ 执行实际存储验收',
    r'.\.venv\Scripts\python.exe ../tests/e2e/minio-roundtrip.py', '', '# 仓库根目录执行管理端流程',
    'node tests/e2e/minio-admin.mjs', '```', '',
    '数据库验收需要专用 `storage_meeting`、`storage_user`、`storage_e2e_meeting`、`storage_e2e_user` 四个测试库；测试连接串固定为测试账号与 loopback 55464，不使用业务数据库。完整测试命令与实际退出码见 [verification.json](verification.json)。', '',
    '## 真实 API 与管理端步骤', '', '| 操作 | 预期 | 实际 | 结果 |', '|---|---|---|---|']
for record in api['checks'] + persistence['checks'] + browser['checks']:
    actual = record['actual'] if isinstance(record['actual'], str) else json.dumps(record['actual'], ensure_ascii=False)
    lines.append(f"| {record['operation']} | {record['expected']} | {actual} | {'通过' if record['pass'] else '失败'} |")
lines += ['', '## 截图及实际查看', '',
    'Chromium 1440×960 与 390×844，各 6 张；窄屏通过实际折叠导航、打开页面、连接测试、刷新和滚动完成。覆盖正常、环境变量只读状态、成功、加载、错误、长说明及录音统计。没有新增抽屉或弹窗，本次不把未执行的无关组件记作通过。两处首轮视觉问题的证据保存在 screenshots-initial。', '',
    '| 截图 | 视口 | 实际查看 | 结果 |', '|---|---|---|---|']
for picture in visual:
    lines.append(f"| [{Path(picture['path']).name}]({picture['path']}) | {picture['viewport']} | {'已查看且文件未变化' if picture['visual_pass'] else '未检查或图片已变更'} | {'未见遮挡、溢出、错位或关键信息截断' if picture['visual_pass'] else '不可判定通过'} |")
lines += ['', '## 调试失败和修复', '']
for record in history:
    evidence = record.get('evidence')
    lines.append(f"- {record['stage']}：{record['result']}" + (f' [证据]({evidence})' if evidence else ''))
lines += ['', '## 清理及保留服务', '']
for record in cleanup:
    success = record.get('stopped', record.get('removed', False))
    lines.append(f"- {record['service']}：{'已清理' if success else '未完成清理'}。")
lines += ['', 'MinIO、更新后的业务服务及原有数据库/STT 按用户部署目标保留运行；没有清空、批量迁移业务数据或删除业务卷。运行状态见 [cleanup.json](cleanup.json)。', '',
    '## 剩余范围', '',
    '阿里云尚未就绪，未请求真实 OSS；使用旧 OSS 对照用例及本地签名检查保持兼容，云端连接须凭实际 Bucket 和密钥另行验收。切换只影响新写入，读取旧 MinIO 对象仍须保留原配置及服务；本次不提供 MinIO → OSS 的历史对象批量迁移。MinIO 数据仍在 Docker 宿主机具名卷，需单独备份，不等同于异地对象存储。', '',
    '[API 结构化结果](api-results.json) · [管理端结果](browser-results.json) · [容器重建验证](persistence-results.json) · [会议回归](meeting-tests.xml) · [发布回归](user-tests.xml) · [契约测试](contract-tests.xml) · [移动端结果](flutter-tests.jsonl) · [截图检查](visual-review.json)', '',
    '报告由 tests/e2e/minio-report.py 读取结构化产物生成。', '']
(out / '测试报告.md').write_text('\n'.join(lines), encoding='utf-8')
print(json.dumps({'groups': groups, 'screenshots_inspected': sum(picture['visual_pass'] for picture in visual), 'report': str(out / '测试报告.md')}, ensure_ascii=True))
