"""Shared reads, early leavers, one WAV and durable IM delivery; real isolated DB/API."""
import asyncio
import io
import wave
from contextlib import asynccontextmanager
from unittest.mock import AsyncMock

import httpx
import pytest
import respx
from sqlalchemy import select

from meeting_ms.db.models import ImNotification, Meeting, RoomRecordingSpeaker
from meeting_ms.db.session import session_factory
from meeting_ms.infrastructure import im_notifications as notices
from meeting_ms.jobs import store
from meeting_ms.tests.test_rooms import ALICE, BOB, CAROL, make_room, join, make_scheduled
from meeting_ms.tests.test_room_recording import chunk, wait_job
from meeting_ms.tests.test_summary import FakeLlm, LLM_BASE
from meeting_ms.utils import utcnow


async def finish(client, room, audio=True):
    if audio:
        uploaded = await client.post(f"/api/v1/rooms/{room['id']}/recording/chunks", headers=ALICE(), json=chunk(room['hostId']))
        assert uploaded.status_code == 201, uploaded.text
    end = await client.post(f"/api/v1/rooms/{room['id']}/end", headers=ALICE())
    assert end.status_code == 200, end.text
    await wait_job(client, end.json()['meetingId'])
    return end.json()['meetingId']


async def test_early_leaver_reads_full_record_and_downloads_same_wav(client, fake_stt):
    with respx.mock(assert_all_called=False) as mock:
        mock.post(f'{LLM_BASE}/chat/completions').mock(side_effect=FakeLlm())
        assert (await client.post('/admin/api/llm/providers', json={'name':'fixture','base_url':LLM_BASE,'model':'test','api_key':'test'})).status_code == 200
        room = await make_room(client)
        await join(client, room['code'], BOB())
        assert (await client.post(f"/api/v1/rooms/{room['id']}/leave", headers=BOB())).status_code == 204
        assert (await client.get('/api/v1/meetings', headers=BOB())).json() == []
        mid = await finish(client, room)
        records = (await client.get('/api/v1/meetings', headers=BOB())).json()
        assert [r['id'] for r in records] == [mid] and records[0]['can_manage'] is False
        for suffix in ['', '/metadata', '/transcripts', '/notes', '/summary-language', '/recording']:
            response = await client.get(f'/api/v1/meetings/{mid}{suffix}', headers=BOB())
            assert response.status_code == 200, (suffix, response.text)
        assert (await client.get(f'/api/v1/meetings/{mid}/transcripts', headers=BOB())).json()['transcripts']
        summary = (await client.get(f'/api/v1/meetings/{mid}/summary', headers=BOB())).json()
        assert summary['status'] == 'completed'
        search = await client.get('/api/v1/transcripts/search?q=segment', headers=BOB())
        assert any(row['id'] == mid for row in search.json())
        audio = await client.get(f'/api/v1/meetings/{mid}/audio', headers=BOB())
        owner_audio = await client.get(f'/api/v1/meetings/{mid}/audio', headers=ALICE())
        assert audio.status_code == 200 and audio.content == owner_audio.content
        with wave.open(io.BytesIO(audio.content)) as wav:
            assert wav.getnframes() == 16000
        async with session_factory()() as db:
            assert len(list((await db.execute(select(Meeting))).scalars())) == 1
            events = list((await db.execute(select(ImNotification))).scalars())
            for event in ['meeting_ended', 'processing_completed']:
                assert {r.recipient for r in events if r.body.get('event') == event} == {'u-1','u-2'}
            count = len(events)
        job = (await client.get(f'/api/v1/meetings/{mid}/recording', headers=BOB())).json()
        await store.update_job(job['jobId'], status='completed')
        async with session_factory()() as db:
            assert len(list((await db.execute(select(ImNotification))).scalars())) == count
        assert (await client.patch(f'/api/v1/meetings/{mid}', headers=BOB(), json={'title':'forged'})).status_code == 404
        assert (await client.delete(f'/api/v1/meetings/{mid}', headers=BOB())).status_code == 404


async def test_waiting_and_unrelated_accounts_get_no_records_or_audio(client, fake_stt):
    sched = await make_scheduled(client, waitRoom=True)
    room = await make_room(client, scheduledMeetingId=sched['id'])
    waiting = await join(client, room['code'], BOB())
    assert waiting.json()['state'] == 'waiting'
    mid = await finish(client, room)
    for headers in [BOB(), CAROL()]:
        assert (await client.get('/api/v1/meetings', headers=headers)).json() == []
        for suffix in ['', '/metadata', '/transcripts', '/summary', '/audio', '/recording']:
            assert (await client.get(f'/api/v1/meetings/{mid}{suffix}', headers=headers)).status_code == 404
    assert (await client.get(f'/api/v1/meetings/{mid}/audio')).status_code == 401


async def test_admitted_member_rejoin_is_not_duplicated_and_single_recording_private(client, fake_stt):
    sched = await make_scheduled(client, waitRoom=True)
    room = await make_room(client, scheduledMeetingId=sched['id'])
    bob = (await join(client, room['code'], BOB())).json()['self']
    assert (await client.post(f"/api/v1/rooms/{room['id']}/admit", headers=ALICE(), json={'participantId':bob['id']})).status_code == 204
    await client.post(f"/api/v1/rooms/{room['id']}/leave", headers=BOB())
    bob2 = (await join(client, room['code'], BOB())).json()['self']
    await client.post(f"/api/v1/rooms/{room['id']}/admit", headers=ALICE(), json={'participantId':bob2['id']})
    await client.post(f"/api/v1/rooms/{room['id']}/leave", headers=BOB())
    mid = await finish(client, room)
    assert len((await client.get('/api/v1/meetings', headers=BOB())).json()) == 1
    personal = (await client.post('/api/v1/meetings', headers=ALICE(), json={'title':'private recording'})).json()['id']
    assert (await client.get(f'/api/v1/meetings/{personal}/audio', headers=BOB())).status_code == 404
    async with session_factory()() as db:
        events = list((await db.execute(select(ImNotification))).scalars())
        assert len([r for r in events if r.recipient == 'u-2' and r.body.get('event') == 'meeting_ended']) == 1


async def test_processing_failure_keeps_downloadable_audio_and_notifies_early_leaver(client, fake_stt, monkeypatch):
    fake_stt.ready = False
    room = await make_room(client)
    await join(client, room['code'], BOB())
    await client.post(f"/api/v1/rooms/{room['id']}/leave", headers=BOB())
    mid = await finish(client, room)
    status = (await client.get(f'/api/v1/meetings/{mid}/recording', headers=BOB())).json()
    assert status['status'] == 'failed'
    assert (await client.get(f'/api/v1/meetings/{mid}/audio', headers=BOB())).status_code == 200
    async with session_factory()() as db:
        rows = list((await db.execute(select(ImNotification))).scalars())
        assert {r.recipient for r in rows if r.body.get('event') == 'processing_failed'} == {'u-1','u-2'}
    request = AsyncMock(return_value=httpx.Response(503, request=httpx.Request('POST','http://im')))
    @asynccontextmanager
    async def fixture(*args, **kwargs):
        yield type('Client', (), {'post':request})()
    monkeypatch.setattr(notices, 'client_for', fixture)
    await notices.tick()
    async with session_factory()() as db:
        rows = list((await db.execute(select(ImNotification))).scalars())
        assert all(row.delivered_at is None and row.attempts >= 1 for row in rows)
        for row in rows: row.next_attempt_at = utcnow()
        await db.commit()
    request.return_value = httpx.Response(200, request=httpx.Request('POST','http://im'))
    await notices.tick()
    async with session_factory()() as db:
        assert all(row.delivered_at and not row.body for row in (await db.execute(select(ImNotification))).scalars())
