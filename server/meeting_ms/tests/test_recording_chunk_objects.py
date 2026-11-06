"""对象分片的幂等、故障恢复与安全清理。真实 MinIO 用例需显式启用。"""
import asyncio
import base64
from datetime import timedelta
import hashlib
import os
from uuid import uuid4

import pytest
import respx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from meeting_ms.config import get_settings
from meeting_ms.db.models import Job, RoomRecordingChunk
from meeting_ms.db.session import session_factory
from meeting_ms.storage import oss, recording_chunks as storage
from meeting_ms.tests.test_room_recording import chunk, wait_job
from meeting_ms.tests.test_rooms import ALICE, make_room
from meeting_ms.tests.test_summary import FakeLlm, LLM_BASE
from meeting_ms.utils import utcnow

REAL_REQUIRE_STORE = storage.require_store


async def rows():
    async with session_factory()() as session:
        return list(await session.scalars(select(RoomRecordingChunk)))


async def upload(client, room, **changes):
    return await client.post(f"/api/v1/rooms/{room['id']}/recording/chunks", headers=ALICE(),
        json={**chunk(room['hostId']), **changes})


async def test_upload_only_object_and_idempotent_conflicts(client, chunk_object_store):
    room = await make_room(client)
    replies = await asyncio.gather(*(upload(client, room) for _ in range(4)))
    assert [r.status_code for r in replies] == [201] * 4
    data = await rows()
    assert len(data) == 1
    row = data[0]
    pcm = base64.b64decode(chunk(room['hostId'])['pcm'])
    assert 'pcm' not in RoomRecordingChunk.__table__.columns and row.storage == 'oss'
    assert row.size == len(pcm) and row.sha256 == hashlib.sha256(pcm).hexdigest()
    assert chunk_object_store.objects() == [row.storage_key]
    assert (chunk_object_store.root / row.storage_key).read_bytes() == pcm
    assert (await upload(client, room, pcm=base64.b64encode(b'\x01\x00' * 16000).decode())).status_code == 409
    assert len(chunk_object_store.objects()) == 1
    assert not list((get_settings().data_dir / 'tmp').glob('pcm-upload-*'))


async def test_upload_failure_not_acknowledged_or_fallback_and_retry(client, chunk_object_store):
    room = await make_room(client)
    chunk_object_store.fail_upload = True
    response = await upload(client, room)
    assert response.status_code == 502 and '对象存储' in response.text
    assert await rows() == []
    assert not list((get_settings().data_dir / 'tmp').glob('pcm-upload-*'))
    chunk_object_store.fail_upload = False
    assert (await upload(client, room)).status_code == 201
    assert (await rows())[0].storage_key


async def test_unconfigured_object_store_is_explicit_503(client, monkeypatch):
    monkeypatch.setattr(storage, 'require_store', REAL_REQUIRE_STORE)
    room = await make_room(client)
    response = await upload(client, room)
    assert response.status_code == 503 and 'MinIO' in response.text
    assert await rows() == []


async def test_database_commit_failure_retry_reuses_object(client, chunk_object_store, monkeypatch):
    room = await make_room(client)
    original = AsyncSession.commit

    async def failing_commit(session):
        if any(isinstance(row, RoomRecordingChunk) for row in session.new):
            raise RuntimeError('deterministic commit failure')
        await original(session)

    monkeypatch.setattr(AsyncSession, 'commit', failing_commit)
    with pytest.raises(RuntimeError, match='commit failure'):
        await upload(client, room)
    assert await rows() == [] and len(chunk_object_store.objects()) == 1
    monkeypatch.setattr(AsyncSession, 'commit', original)
    assert (await upload(client, room)).status_code == 201
    assert len(await rows()) == 1 and len(chunk_object_store.objects()) == 1


async def assert_recording_pipeline(client, object_store, fake_stt):
    with respx.mock(assert_all_called=False) as mock:
        mock.post(f'{LLM_BASE}/chat/completions').mock(side_effect=FakeLlm())
        assert (await client.post('/admin/api/llm/providers', json={
            'name': 'fixture', 'base_url': LLM_BASE, 'model': 'test', 'api_key': 'test'})).status_code == 200
        room = await make_room(client)
        assert (await upload(client, room)).status_code == 201
        current = next(r for r in await rows() if r.chunk_id == 'chunk-1')
        original = base64.b64decode(chunk(room['hostId'])['pcm'])
        # Deterministic integrity failure, then restore the exact object for retry.
        bad_path = get_settings().data_dir / 'corrupt.pcm'
        bad_path.write_bytes(b'\x00\x00')
        await object_store.upload(bad_path, current.storage_key, 'application/octet-stream')
        mid = (await client.post(f"/api/v1/rooms/{room['id']}/end", headers=ALICE())).json()['meetingId']
        failed = await wait_job(client, mid)
        assert failed['status'] == 'failed' and '校验失败' in failed['error']
        assert all(r.purged_at is None for r in await rows())
        bad_path.write_bytes(original)
        await object_store.upload(bad_path, current.storage_key, 'application/octet-stream')
        bad_path.unlink()
        assert (await client.post(f'/api/v1/meetings/{mid}/recording/retry', headers=ALICE())).status_code == 202
        assert (await wait_job(client, mid))['status'] == 'completed'
        result = (await client.get(f'/api/v1/meetings/{mid}', headers=ALICE())).json()
        assert len(result['transcripts']) == 1
        assert all(t['speaker'] == '1·alice' for t in result['transcripts'])
        assert all(r.purged_at is None for r in await rows())
        assert await storage.cleanup_chunks() == 0
        assert all(r.expires_at is not None for r in await rows())
        audio = await client.get(f'/api/v1/meetings/{mid}/audio', headers=ALICE())
        assert audio.status_code in (200, 302)
        assert not list((get_settings().data_dir / 'tmp').glob('room-pcm-*'))
        return room, mid


@pytest.mark.parametrize('status', ['failed', 'cancelled', 'running', 'queued', 'completed'])
async def test_cleanup_only_completed_after_retention(client, chunk_object_store, fake_stt, status):
    room = await make_room(client)
    assert (await upload(client, room)).status_code == 201
    fake_stt.ready = False
    mid = (await client.post(f"/api/v1/rooms/{room['id']}/end", headers=ALICE())).json()['meetingId']
    await wait_job(client, mid)
    async with session_factory()() as session:
        job = await session.scalar(select(Job).where(Job.meeting_id == mid, Job.kind == 'room_recording'))
        job.status, job.updated_at = status, utcnow() - timedelta(days=5)
        await session.commit()
    purged = await storage.cleanup_chunks()
    row = (await rows())[0]
    assert purged == (1 if status == 'completed' else 0)
    assert (row.purged_at is not None) == (status == 'completed')
    assert len(chunk_object_store.objects()) == (0 if status == 'completed' else 1)
    assert await storage.cleanup_chunks() == 0


async def test_delete_meeting_cleans_sources_on_next_sweep(client, fake_stt, chunk_object_store):
    room = await make_room(client)
    assert (await upload(client, room)).status_code == 201
    fake_stt.ready = False
    mid = (await client.post(f"/api/v1/rooms/{room['id']}/end", headers=ALICE())).json()['meetingId']
    await wait_job(client, mid)
    assert (await client.delete(f'/api/v1/meetings/{mid}', headers=ALICE())).status_code == 204
    assert await storage.cleanup_chunks() == 1
    assert chunk_object_store.objects() == []


async def test_delete_failure_preserves_index_for_retry(client, fake_stt, chunk_object_store, monkeypatch):
    room = await make_room(client)
    assert (await upload(client, room)).status_code == 201
    fake_stt.ready = False
    mid = (await client.post(f"/api/v1/rooms/{room['id']}/end", headers=ALICE())).json()['meetingId']
    await wait_job(client, mid)
    await client.delete(f'/api/v1/meetings/{mid}', headers=ALICE())
    original = chunk_object_store.delete_prefix

    async def fail(*args, **kwargs):
        raise RuntimeError('delete failure fixture')

    monkeypatch.setattr(chunk_object_store, 'delete_prefix', fail)
    with pytest.raises(RuntimeError):
        await storage.cleanup_chunks()
    assert (await rows())[0].purged_at is None
    monkeypatch.setattr(chunk_object_store, 'delete_prefix', original)
    assert await storage.cleanup_chunks() == 1


@pytest.mark.skipif(not os.getenv('PCM_TEST_MINIO_ENDPOINT'), reason='需显式配置隔离的真实 MinIO 测试')
async def test_real_minio_recording_integrity_retry_and_retention(client, fake_stt, monkeypatch):
    from service_net.minio_store import MinioStore
    prefix = 'pcm-e2e-' + uuid4().hex + '/'
    cfg = oss.OssConfig(os.environ['PCM_TEST_MINIO_ENDPOINT'], 'us-east-1',
        os.environ['PCM_TEST_MINIO_BUCKET'], os.environ['PCM_TEST_MINIO_ACCESS_KEY_ID'],
        os.environ['PCM_TEST_MINIO_ACCESS_KEY_SECRET'], prefix, 'minio', os.environ['PCM_TEST_MINIO_ENDPOINT'])
    store = MinioStore(cfg, get_settings())

    async def get_store(backend=None):
        return store

    monkeypatch.setattr(storage, 'require_store', get_store)
    monkeypatch.setattr(oss, 'get_audio_store', get_store)
    try:
        # First smoke the deterministic real MinIO authentication failure.
        from dataclasses import replace
        wrong = MinioStore(replace(cfg, access_key_secret='explicit-invalid-e2e-secret'), get_settings())

        async def wrong_store(backend=None):
            return wrong

        room = await make_room(client)
        monkeypatch.setattr(storage, 'require_store', wrong_store)
        assert (await upload(client, room)).status_code == 502
        assert await rows() == []
        monkeypatch.setattr(storage, 'require_store', get_store)
        room, mid = await assert_recording_pipeline(client, store, fake_stt)
        data = await rows()
        assert all(r.storage == 'minio' and r.sha256 for r in data)
        async with session_factory()() as session:
            for row in await session.scalars(select(RoomRecordingChunk)):
                row.expires_at = utcnow() - timedelta(seconds=1)
            await session.commit()
        assert await storage.cleanup_chunks() == 1
        objects = await asyncio.to_thread(lambda: list(store.client.list_objects(cfg.bucket, prefix=prefix, recursive=True)))
        assert len(objects) == 1 and objects[0].object_name.endswith('room.wav')
        audio = await client.get(f'/api/v1/meetings/{mid}/audio', headers=ALICE())
        assert audio.status_code == 302
    finally:
        await store.delete_prefix(prefix)
