"""Automatic recording replaces manual approval; keep authority and chunk boundaries."""
from unittest.mock import AsyncMock

import pytest

from meeting_ms.db.models import LiveRoom
from meeting_ms.db.session import session_factory
from meeting_ms.tests.test_rooms import ALICE, BOB, CAROL, make_room, join, make_scheduled
from meeting_ms.tests.test_room_recording import chunk, wait_job


async def control(client, room, action, headers=None, **args):
    return await client.post(f"/api/v1/rooms/{room['id']}/recording/control",
        headers=headers or ALICE(), json={'action': action, 'epoch': room['recording']['epoch'], **args})


async def test_rooms_automatically_record_and_start_is_idempotent(client):
    for kwargs in ({}, {'scheduledMeetingId': (await make_scheduled(client))['id']}):
        room = await make_room(client, **kwargs)
        assert room['recording']['active'] and room['recording']['epoch'] == 1
        assert room['recording']['startedAt'] and not room['recording']['requests']
        replay = (await control(client, room, 'start')).json()
        assert replay['recording'] == room['recording']


@pytest.mark.parametrize('action', ['stop', 'request', 'approve', 'deny'])
async def test_manual_controls_cannot_disable_automatic_recording(client, action):
    room = await make_room(client)
    response = await control(client, room, action)
    assert response.status_code == 409 and response.json()['code'] == 'automatic_recording'
    assert (await client.get(f"/api/v1/rooms/{room['id']}", headers=ALICE())).json()['recording']['active']


async def test_legacy_room_can_activate_but_only_host(client):
    room = await make_room(client)
    await join(client, room['code'], BOB())
    async with session_factory()() as db:
        row = await db.get(LiveRoom, room['id'])
        row.recording_active = False; row.recording_epoch = 0; row.recording_started_at = None
        await db.commit()
    room['recording']['epoch'] = 0
    assert (await control(client, room, 'start', BOB())).status_code == 403
    assert (await control(client, room, 'start', CAROL())).status_code == 403
    restored = (await control(client, room, 'start')).json()
    assert restored['recording']['active'] and restored['recording']['epoch'] == 1
    assert (await control(client, room, 'start')).status_code == 409


async def test_auto_recording_host_transfer_keeps_upload_authority(client):
    room = await make_room(client)
    bob = (await join(client, room['code'], BOB())).json()['self']
    url = f"/api/v1/rooms/{room['id']}/recording/chunks"
    assert (await client.post(url, headers=ALICE(), json=chunk(room['hostId']))).status_code == 201
    assert (await client.post(f"/api/v1/rooms/{room['id']}/participants/{bob['id']}/transfer-host", headers=ALICE())).status_code == 204
    current = (await client.get(f"/api/v1/rooms/{room['id']}", headers=BOB())).json()
    assert current['recording']['active'] and current['recording']['epoch'] == 1
    payload = chunk(bob['id'], 'new-host', 1)
    assert (await client.post(url, headers=ALICE(), json=payload)).status_code == 403
    assert (await client.post(url, headers=BOB(), json=payload)).status_code == 201
    assert (await control(client, current, 'start', ALICE())).status_code == 403


async def test_auto_recording_without_audio_reports_failure_not_success(client):
    room = await make_room(client)
    ended = (await client.post(f"/api/v1/rooms/{room['id']}/end", headers=ALICE())).json()
    assert ended['jobId']
    status = await wait_job(client, ended['meetingId'])
    assert status['status'] == 'failed' and '音频' in status['error']
