import httpx
import pytest
from unittest.mock import AsyncMock

from meeting_ms.api.v1 import jobs
from meeting_ms.tests.conftest import user_headers


@pytest.mark.parametrize('character', ['会', 'a', '😀'])
async def test_title_boundary_and_rejected_rename_keeps_saved_title(client: httpx.AsyncClient, character):
    title = character * 50
    created = await client.post('/api/v1/meetings', json={'title': title}, headers=user_headers())
    assert created.status_code == 201, created.text
    mid = created.json()['id']
    saved = await client.patch(f'/api/v1/meetings/{mid}', json={'title': '  ' + title + '  '}, headers=user_headers())
    assert saved.status_code == 200 and saved.json()['title'] == title
    rejected = await client.patch(f'/api/v1/meetings/{mid}', json={'title': title + character}, headers=user_headers())
    assert rejected.status_code == 422
    assert rejected.json()['detail'][0]['loc'] == ['body', 'title']
    unchanged = await client.get(f'/api/v1/meetings/{mid}/metadata', headers=user_headers())
    assert unchanged.json()['title'] == title
    rejected_create = await client.post('/api/v1/meetings', json={'title': title + character}, headers=user_headers())
    assert rejected_create.status_code == 422


@pytest.mark.parametrize('title', ['', '   ', '\n\t'])
async def test_empty_rename_rejected_but_create_retains_default(client: httpx.AsyncClient, title):
    created = await client.post('/api/v1/meetings', json={'title': title}, headers=user_headers())
    assert created.status_code == 201 and created.json()['title'] == '新会议'
    response = await client.patch(f"/api/v1/meetings/{created.json()['id']}", json={'title': title}, headers=user_headers())
    assert response.status_code == 422


async def test_import_title_rejected_before_stt_or_upload(client: httpx.AsyncClient, monkeypatch):
    check_stt = AsyncMock(side_effect=AssertionError('invalid input must not start STT'))
    monkeypatch.setattr(jobs, '_require_stt', check_stt)
    response = await client.post('/api/v1/jobs/import', data={'title': '会' * 51},
                                 files={'file': ('sample.wav', b'invalid-audio', 'audio/wav')}, headers=user_headers())
    assert response.status_code == 422
    check_stt.assert_not_awaited()
