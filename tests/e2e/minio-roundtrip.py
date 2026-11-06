"""真实 MinIO + 网关出站代理 + 服务路由 + 隔离 PostgreSQL 的存储验收。

只替换网关身份及服务间 HTTP 边界；音频和 EXE 为合成夹具，不代表真实 RTC/安装更新验收。
运行目录 server/，测试库默认位于 127.0.0.1:55464，凭据从未提交的 .env 读取。
"""
import asyncio
import io
import json
import logging
import os
from pathlib import Path
import sys
from types import SimpleNamespace
import uuid
import wave

root = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(root / 'server'))
from dotenv import dotenv_values

env = dotenv_values(root / 'server/.env')
out = Path(os.environ.get('MINIO_STORAGE_OUTPUT', str(root / '.artifacts/minio-object-storage'))).resolve()
out.mkdir(parents=True, exist_ok=True)
bucket = 'openmeeting-test-' + uuid.uuid4().hex[:12]
endpoint = 'http://127.0.0.1:' + (env.get('OPENMEETING_MINIO_API_PORT') or '39120')
public = env['OPENMEETING_MINIO_PUBLIC_ENDPOINT']
os.environ.update(OPENMEETING_ENV='test', OPENMEETING_LOG_LEVEL='ERROR', OPENMEETING_IM_ENABLED='false', OPENMEETING_STORAGE_PROVIDER='minio',
                  OPENMEETING_MINIO_ENDPOINT=endpoint, OPENMEETING_MINIO_PUBLIC_ENDPOINT=public,
                  OPENMEETING_MINIO_BUCKET=bucket, OPENMEETING_MINIO_REGION='us-east-1', OPENMEETING_MINIO_PREFIX='acceptance',
                  OPENMEETING_MINIO_ACCESS_KEY_ID=env['OPENMEETING_MINIO_ACCESS_KEY_ID'],
                  OPENMEETING_MINIO_ACCESS_KEY_SECRET=env['OPENMEETING_MINIO_ACCESS_KEY_SECRET'],
                  OPENMEETING_SECRET_KEY='storage-test-only', OPENMEETING_ADMIN_PASSWORD='storage-test-admin',
                  OPENMEETING_INTERNAL_SERVICE_TOKEN='storage-test-internal',
                  OPENMEETING_GATEWAY_MS_URL='http://127.0.0.1:9',
                  OPENMEETING_DATA_DIR=str(out / 'api-data'))

import httpx
import numpy as np
from asgi_lifespan import LifespanManager
from minio import Minio
from minio.deleteobjects import DeleteObject
from gateway_ms.infrastructure.egress import EgressProxy
from meeting_ms.config import get_settings as meeting_settings
from user_ms.config import get_settings as user_settings
from meeting_ms.main import app as meeting_app
from user_ms.main import app as user_app
from meeting_ms.db.models import Job, LiveRoom, Meeting, RoomRecordingChunk
from meeting_ms.db.session import session_factory
from meeting_ms.jobs import room_recording
from meeting_ms.storage import oss
from meeting_ms.storage.recording_chunks import cleanup_chunks, upload_pcm
from user_ms.storage import oss as release_oss
from service_net.minio_store import endpoint_parts

logging.basicConfig(level=logging.ERROR)
report = {'scope': __doc__, 'checks': [], 'cleanup': []}


def record(operation, expected, actual, passed=True):
    row = {'operation': operation, 'expected': expected, 'actual': actual, 'pass': passed, 'screenshot': None}
    report['checks'].append(row)
    (out / 'api-results.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps(row, ensure_ascii=True), flush=True)


async def main():
    host, secure = endpoint_parts(endpoint)
    control = Minio(host, secure=secure, region='us-east-1', access_key=env['OPENMEETING_MINIO_ACCESS_KEY_ID'],
                    secret_key=env['OPENMEETING_MINIO_ACCESS_KEY_SECRET'])
    control.make_bucket(bucket)
    proxy_settings = SimpleNamespace(internal_service_token='storage-test-internal', egress_host='127.0.0.1',
        egress_port=0, egress_allowed_hosts=['127.0.0.1'], egress_private_hosts=['127.0.0.1'],
        egress_allowed_ports=[int(endpoint.rsplit(':', 1)[1])], egress_connect_timeout=5,
        egress_idle_timeout=30, egress_max_connections=32)
    proxy = await EgressProxy(proxy_settings).start()
    proxy_port = proxy.server.sockets[0].getsockname()[1]
    for settings, database in [(meeting_settings(), 'storage_e2e_meeting'), (user_settings(), 'storage_e2e_user')]:
        settings.database_url = f'postgresql+asyncpg://storagetest:storagetest@127.0.0.1:55464/{database}'
        settings.egress_proxy_url = f'http://127.0.0.1:{proxy_port}'
    headers = {'X-Internal-Token': 'storage-test-internal', 'X-User-ID': 'storage-user',
               'X-User-Name': 'storage-test', 'X-Session-ID': 'storage-session'}

    def internal_client(timeout=10):
        return httpx.AsyncClient(transport=httpx.ASGITransport(meeting_app), base_url='http://meeting/internal/',
                                 headers={'X-Internal-Token': 'storage-test-internal'}, timeout=timeout)

    release_oss._client = internal_client
    release_oss._cached_config = None
    release_oss._backend_configs.clear()
    try:
        async with LifespanManager(meeting_app), LifespanManager(user_app):
            async with httpx.AsyncClient(transport=httpx.ASGITransport(meeting_app), base_url='http://meeting', headers=headers) as meetings, \
                       httpx.AsyncClient(transport=httpx.ASGITransport(user_app), base_url='http://user', headers=headers) as releases, \
                       httpx.AsyncClient(trust_env=False) as download:
                connected = await meetings.post('/admin/api/object-storage/test')
                assert connected.json() == {'ok': True, 'error': None}, connected.text
                record('MinIO 真实读写冒烟（经认证出站代理）', '写入、读回、删除成功', connected.json())
                assert not list(control.list_objects(bucket, recursive=True))
                secret = meeting_settings().minio_access_key_secret
                meeting_settings().minio_access_key_secret = 'deterministic-invalid-secret'
                invalid = await meetings.post('/admin/api/object-storage/test')
                assert invalid.json()['ok'] is False
                record('单独冒烟错误凭据夹具', '确定性返回 ok=false', {'ok': invalid.json()['ok']})
                meeting_settings().minio_access_key_secret = secret
                meeting_settings().minio_public_endpoint = None
                missing = (await meetings.post('/api/v1/meetings', json={'title': 'MinIO 配置失败路径'})).json()['id']
                failed = await meetings.put(f'/api/v1/meetings/{missing}/audio', content=b'fixture')
                assert failed.status_code == 503
                record('单独冒烟缺失配置', '显式 MinIO 模式缺少公共地址返回 503', failed.status_code)
                meeting_settings().minio_public_endpoint = public

                audio = io.BytesIO()
                with wave.open(audio, 'wb') as wav:
                    wav.setnchannels(1); wav.setsampwidth(2); wav.setframerate(16000)
                    wav.writeframes((np.ones(1600, dtype='<i2') * 1000).tobytes())
                payload = audio.getvalue()
                created = await meetings.post('/api/v1/meetings', json={'title': 'MinIO 音频验收'})
                mid = created.json()['id']
                uploaded = await meetings.put(f'/api/v1/meetings/{mid}/audio?filename=audio.wav', content=payload,
                                               headers={'Content-Type': 'audio/wav'})
                assert uploaded.status_code == 200, uploaded.text
                async with session_factory()() as session:
                    metadata = await session.get(Meeting, mid)
                    assert metadata.audio_storage == 'minio'
                    key = metadata.audio_path
                record('上传录音并检查数据库存储类型', '200，audio_storage=minio', uploaded.status_code)
                response = await meetings.get(f'/api/v1/meetings/{mid}/audio')
                assert response.status_code == 302 and response.headers['location'].startswith(public)
                signed = response.headers['location']
                complete = await download.get(signed)
                assert complete.status_code == 200 and complete.content == payload
                part = await download.get(signed, headers={'Range': 'bytes=0-31'})
                assert part.status_code == 206 and part.content == payload[:32]
                record('预签名播放和 Range', '客户端可达地址，原字节一致，Range=206', [complete.status_code, part.status_code])
                anonymous = await download.get(public + '/' + bucket + '/' + key)
                assert anonymous.status_code == 403
                record('私有 Bucket 权限路径', '无签名访问返回 403', anonymous.status_code)
                meeting_settings().minio_access_key_secret = 'deterministic-invalid-secret'
                rejected = await meetings.put(f'/api/v1/meetings/{mid}/audio?filename=rejected.wav', content=payload)
                assert rejected.status_code == 502
                meeting_settings().minio_access_key_secret = secret
                assert (await download.get(signed)).content == payload
                record('上传失败保留原录音', '502，原音频仍可读取', rejected.status_code)

                login = await releases.post('/admin/api/login', json={'password': 'storage-test-admin'})
                assert login.status_code == 200, login.text
                created_release = await releases.post('/admin/api/releases', json={'platform': 'windows', 'version': '9.99.3', 'build': int(uuid.uuid4().hex[:6], 16)})
                assert created_release.status_code == 201, created_release.text
                rid = created_release.json()['id']
                exe = b'MZ-MinIO-storage-fixture-not-an-installable-executable'
                artifact_response = await releases.post(f'/admin/api/releases/{rid}/artifacts', data={'arch': 'x86_64'},
                    files={'file': ('storage-test.exe', exe, 'application/octet-stream'),
                           'signature': ('storage-test.exe.sig', b'fixture-signature', 'text/plain')})
                assert artifact_response.status_code == 201, artifact_response.text
                artifact = artifact_response.json()['artifacts'][0]
                assert artifact['storage'] == 'minio'
                redirect = await releases.get(f"/api/v1/updates/download/{artifact['id']}")
                assert redirect.status_code == 302
                assert (await download.get(redirect.headers['location'])).content == exe
                record('EXE 发布包上传和下载', '服务间共享 MinIO 配置，302 后字节一致；版本保持草稿', artifact['storage'])

                # 不依赖模型就绪即可保存会后音频；不调用真实 RTC、STT 或大模型。
                recording_mid = (await meetings.post('/api/v1/meetings', json={'title': '多人会议录音存储验收'})).json()['id']
                room_id = 'room-storage-' + uuid.uuid4().hex
                job_id = 'job-storage-' + uuid.uuid4().hex
                async with session_factory()() as session:
                    session.add(LiveRoom(id=room_id, code='987654', title='storage fixture', host_user_id='storage-user',
                                         host_participant_id='fixture-participant', status='ended', meeting_id=recording_mid))
                    await session.flush()
                    session.add(RoomRecordingChunk(id=uuid.uuid4().hex, room_id=room_id, chunk_id='fixture-pcm',
                        participant_id='fixture-participant', speaker_name='fixture', start_time=0,
                        **await upload_pcm(room_id, 'fixture-pcm', payload[44:])))
                    job = Job(id=job_id, user_id='storage-user', kind='room_recording', status='queued',
                              meeting_id=recording_mid, params={'room_id': room_id})
                    session.add(job)
                    await session.commit()

                class NoStt:
                    async def ready(self):
                        return False

                room_recording.SttClient = NoStt
                await room_recording.run(job, lambda _: None)
                async with session_factory()() as session:
                    recording = await session.get(Meeting, recording_mid)
                    assert recording.audio_storage == 'minio'
                recorded = await meetings.get(f'/api/v1/meetings/{recording_mid}/audio')
                assert recorded.status_code == 302
                assert (await download.get(recorded.headers['location'])).content.startswith(b'RIFF')
                record('多人会议合成录音进入 MinIO', '即使 STT 未就绪，录音仍存入对象存储', recording.audio_storage)

                meeting_settings().storage_provider = 'local'
                user_settings().storage_provider = 'local'
                release_oss._cached_config = None
                still_audio = await meetings.get(f'/api/v1/meetings/{mid}/audio')
                still_package = await releases.get(f"/api/v1/updates/download/{artifact['id']}")
                assert still_audio.status_code == still_package.status_code == 302
                record('切换写入后读取旧 MinIO 对象', '音频、安装包仍按记录的 minio 后端读取', [still_audio.status_code, still_package.status_code])
                await releases.delete(f'/admin/api/releases/{rid}')
                await meetings.delete(f'/api/v1/meetings/{mid}')
                await meetings.delete(f'/api/v1/meetings/{recording_mid}')
                assert await cleanup_chunks() == 1
                assert not list(control.list_objects(bucket, recursive=True))
                record('切换后删除旧对象', '删除会议与版本时清理原 MinIO 对象', 0)
    finally:
        await proxy.close()
        # 仅清理本次独立 Bucket，绝不操作业务 Bucket。
        assert bucket.startswith('openmeeting-test-')
        for error in control.remove_objects(bucket, (DeleteObject(obj.object_name) for obj in control.list_objects(bucket, recursive=True))):
            raise RuntimeError(error.code)
        control.remove_bucket(bucket)
        report['cleanup'] = [{'service': 'isolated egress proxy', 'stopped': True}, {'service': 'test MinIO bucket', 'removed': True}]
        (out / 'api-results.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')


if __name__ == '__main__':
    try:
        asyncio.run(main())
    except Exception as error:
        record('执行异常', '全部断言通过', f'{type(error).__name__}: {str(error)[:1000]}', False)
        raise
