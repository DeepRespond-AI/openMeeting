"""从本轮测试的 XML / JSON 产物组装报告，不把未执行项目记为通过。"""
import json
from pathlib import Path
import xml.etree.ElementTree as ET

out = Path(__file__).resolve().parents[2] / '.artifacts/pcm-object-storage'
checks = []
for filename in ('meeting-final.xml', 'storage-contracts.xml'):
    tree = ET.parse(out / filename)
    for case in tree.iter('testcase'):
        skipped = case.find('skipped') is not None
        failed = case.find('failure') is not None or case.find('error') is not None
        checks.append({'operation': case.attrib.get('name'), 'source': filename,
                       'result': '跳过' if skipped else '失败' if failed else '通过'})
for filename in ('migration-results.json', 'roundtrip/api-results.json'):
    data = json.loads((out / filename).read_text(encoding='utf-8'))
    for item in data if isinstance(data, list) else data['checks']:
        checks.append({'operation': item['operation'], 'source': filename,
                       'result': '通过' if item.get('pass', item.get('pass_', False)) else '失败'})
cleanup = json.loads((out / 'cleanup.json').read_text(encoding='utf-8'))
counts = {label: sum(c['result'] == label for c in checks) for label in ('通过', '失败', '跳过')}
report = [
    '# 会中 PCM 对象存储测试报告', '',
    '分级：后端存储和数据库迁移变更，客户端协议与界面不变。本轮执行 API / 服务集成验证，无浏览器页面或截图，不标记视觉验收。', '',
    '启动与复用：复用现有 Docker MinIO（39120），新建独立 PostgreSQL 测试容器 openmeeting-pcm-tests（55452）和 openmeeting-pcm-proxy-tests（55464）。ASGI 服务使用本次源码；MinIO 综合验证另启动临时认证出站代理，结束后关闭。业务数据库、客户端及业务容器未更新。', '',
    '流程：先冒烟确定性错误凭据、缺失配置、上传失败和对象校验失败，再验证幂等、失败重试、分片到完整录音 / 转写 / 总结、清理策略、真实代理与对象存储、数据库升级。音频为合成 PCM，STT/LLM 使用显式夹具，不代表真实 RTC 或生产模型验收。', '',
    f"最终结果：通过 {counts['通过']}，失败 {counts['失败']}，跳过 {counts['跳过']}。", '',
    '| 检查 | 结果 | 证据 |', '|---|---|---|',
    *[f"| {c['operation']} | {c['result']} | [{c['source']}]({c['source']}) |" for c in checks], '',
    '## 调试记录', '',
    '首次全量回归发生 23 项失败：模拟对象存储把长对象 key 映射成本地路径，超出 Windows 路径限制。已缩短测试存储根路径并改用单个摘要 key，最终全量回归通过。首次日志保留在 [meeting-tests.log](meeting-tests.log)，不计为通过。', '',
    '代理验证首次 PowerShell 重定向把预期的错误凭据 stderr 记作命令失败；改用子进程捕获并检查实际退出码后，最终退出 0、11 项断言通过。首次记录见 [roundtrip-attempt-01.log](roundtrip-attempt-01.log)，最终记录见 [roundtrip.log](roundtrip.log)。', '',
    '## 清理', '',
    *[f'- {json.dumps(row, ensure_ascii=False)}' for row in cleanup], '',
    '真实 MinIO 用例清理随机对象前缀；代理综合用例清理本轮临时 Bucket。原有服务保持运行。', '',
    '## 部署与剩余边界', '',
    '- 未对业务环境执行迁移。部署时在 server/ 执行 docker compose up -d --build meeting_ms，启动自动执行迁移。',
    '- 按用户要求只保留对象存储策略，迁移永久清理旧 PCM 并移除字段。完整录音、转写、纪要保留；未合成的旧源分片不可恢复。',
    '- 新分片需要 MinIO / OSS。成功任务默认保留 3 天，每 60 秒每批最多清理 100 个；失败 / 取消 / 排队 / 运行中的新任务保留。',
    '- 临时磁盘需容纳分片与 WAV。对象上传成功但数据库提交前崩溃可能留下无引用对象；相同分片重试复用 key，不可对整个前缀设置短期统一过期删除。',
    '- 阿里云 OSS 使用已有适配器；本轮未使用真实阿里云账号验收。未运行真机与真实模型流程。', '',
]
(out / 'verification.json').write_text(json.dumps({'counts': counts, 'checks': checks, 'cleanup': cleanup}, ensure_ascii=False, indent=2), encoding='utf-8')
(out / '测试报告.md').write_text('\n'.join(report), encoding='utf-8')
print(json.dumps(counts, ensure_ascii=False))
