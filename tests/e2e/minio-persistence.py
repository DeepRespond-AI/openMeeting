"""独立 MinIO 容器重建验收，只操作带 UUID 的测试容器和测试卷。"""
import io
import json
from pathlib import Path
import subprocess
import time
import uuid

import httpx
from minio import Minio

out = Path(__file__).resolve().parents[2] / '.artifacts/minio-object-storage'
out.mkdir(parents=True, exist_ok=True)
name = 'openmeeting-minio-test-' + uuid.uuid4().hex[:10]
volume = name + '-data'
report = {'checks': [], 'cleanup': []}


def docker(*args, check=True):
    return subprocess.run(['docker', *args], capture_output=True, text=True, check=check)


def start():
    docker('run', '-d', '--name', name, '--label', 'openmeeting.test=minio-persistence',
           '-e', 'MINIO_ROOT_USER=fixture-key', '-e', 'MINIO_ROOT_PASSWORD=fixture-storage-password',
           '-p', '127.0.0.1::9000', '-v', volume + ':/data', 'openmeeting-split-minio')
    host = docker('port', name, '9000/tcp').stdout.strip()
    for attempt in range(80):
        try:
            if httpx.get('http://' + host + '/minio/health/ready', trust_env=False, timeout=1).status_code == 200:
                return Minio(host, access_key='fixture-key', secret_key='fixture-storage-password', secure=False, region='us-east-1')
        except httpx.HTTPError:
            pass
        time.sleep(0.25)
    raise RuntimeError('测试 MinIO 未就绪')


try:
    client = start()
    client.make_bucket('storage-fixture')
    payload = b'object survives container recreation'
    client.put_object('storage-fixture', 'test.bin', io.BytesIO(payload), len(payload))
    docker('rm', '-f', name)
    client = start()
    response = client.get_object('storage-fixture', 'test.bin')
    try:
        assert response.read() == payload
    finally:
        response.close()
        response.release_conn()
    report['checks'].append({'operation': 'MinIO 容器重建后读取对象', 'expected': '具名卷保留数据，字节一致', 'actual': len(payload), 'pass': True})
except Exception as error:
    report['checks'].append({'operation': 'MinIO 持久化测试', 'expected': '重建后可读', 'actual': type(error).__name__ + ': ' + str(error), 'pass': False})
    raise
finally:
    stopped = docker('rm', '-f', name, check=False).returncode == 0
    removed = docker('volume', 'rm', volume, check=False).returncode == 0
    report['cleanup'] = [{'service': 'isolated MinIO test container', 'stopped': stopped}, {'service': 'isolated MinIO test volume', 'removed': removed}]
    (out / 'persistence-results.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps(report, ensure_ascii=True))
