"""Gateway routing security and real service client URLs, without touching any database."""
import httpx
import pytest
from fastapi import FastAPI, HTTPException

from gateway_ms.api.internal import router
from gateway_ms.config import get_settings
from meeting_ms.config import get_settings as meeting_settings
from meeting_ms.infrastructure.internal_client import client_for
from user_ms.config import get_settings as user_settings
from user_ms.infrastructure.meeting_client import _client
from user_ms.infrastructure import meeting_client


@pytest.fixture
async def gateway(monkeypatch):
    settings = get_settings()
    monkeypatch.setattr(settings, 'internal_service_token', 'test-internal-token')
    seen = []

    async def downstream(request):
        seen.append(request)
        if request.url.path.endswith('/outage'):
            raise httpx.ConnectError('injected outage', request=request)
        if request.url.path.endswith('/unavailable'):
            return httpx.Response(503, json={'detail': 'model unavailable'})
        if request.method == 'DELETE':
            return httpx.Response(204)
        return httpx.Response(200, content=await request.aread(), headers={'X-Upstream': 'preserved'})

    app = FastAPI()
    app.include_router(router)
    async with httpx.AsyncClient(transport=httpx.MockTransport(downstream)) as relay:
        app.state.http_client = relay
        async with httpx.AsyncClient(transport=httpx.ASGITransport(app=app), base_url='http://gateway') as client:
            yield client, seen


@pytest.mark.parametrize('headers', [{}, {'X-Internal-Token': 'wrong'},
    {'Authorization': 'Bearer ms_fake', 'X-User-ID': 'admin'}, {'X-Internal-Token': '非ASCII'}])
async def test_internal_auth_rejects_before_forwarding(gateway, headers):
    client, seen = gateway
    # httpx encodes request header strings as ASCII; use UTF-8 bytes for malformed input.
    headers = {k: v.encode() for k, v in headers.items()}
    response = await client.get('/internal/user/connections', headers=headers)
    assert response.status_code == 401
    assert seen == []


async def test_unconfigured_token_fails_closed(gateway, monkeypatch):
    client, seen = gateway
    monkeypatch.setattr(get_settings(), 'internal_service_token', '')
    assert (await client.get('/internal/user/connections')).status_code == 503
    assert seen == []


@pytest.mark.parametrize('service', ['user', 'meeting', 'stt'])
async def test_forward_bytes_query_and_strip_identity(gateway, service):
    client, seen = gateway
    response = await client.post(f'/internal/{service}/transcribe?a=1&a=2', content=b'\x00\xff\x10', headers={
        'X-Internal-Token': 'test-internal-token', 'X-User-ID': 'spoofed',
        'X-Session-ID': 'spoofed', 'Authorization': 'Bearer fake', 'Cookie': 'admin=fake',
        'X-Audio-Format': 'pcm16le',
    })
    assert response.status_code == 200 and response.content == b'\x00\xff\x10'
    request = seen[-1]
    assert request.url.path == '/internal/transcribe'
    assert request.url.params.multi_items() == [('a', '1'), ('a', '2')]
    assert request.headers['X-Internal-Token'] == 'test-internal-token'
    assert request.headers['X-Audio-Format'] == 'pcm16le'
    assert all(k not in request.headers for k in ['x-user-id', 'x-session-id', 'authorization', 'cookie'])
    assert response.headers['X-Upstream'] == 'preserved'


@pytest.mark.parametrize('path', ['unknown/status', 'user/%252e%252e/admin', 'user/a%2F..%2Fadmin',
    'user/a%5Cb', 'user/a//b', 'gateway/status'])
async def test_cannot_choose_arbitrary_target_or_escape_namespace(gateway, path):
    client, seen = gateway
    response = await client.get('/internal/' + path, headers={'X-Internal-Token': 'test-internal-token'})
    assert response.status_code == 404
    assert seen == []


async def test_upstream_failure_and_empty_delete_response(gateway):
    client, _ = gateway
    headers = {'X-Internal-Token': 'test-internal-token'}
    response = await client.get('/internal/stt/outage', headers=headers)
    assert response.status_code == 502 and response.json()['detail'] == '上游服务不可用'
    response = await client.get('/internal/stt/unavailable', headers=headers)
    assert response.status_code == 503 and response.json()['detail'] == 'model unavailable'
    response = await client.delete('/internal/meeting/users/u/data', headers=headers)
    assert response.status_code == 204 and response.content == b''


async def test_all_service_clients_address_gateway(monkeypatch):
    monkeypatch.setattr(meeting_settings(), 'gateway_ms_url', 'http://gateway:39110/')
    monkeypatch.setattr(user_settings(), 'gateway_ms_url', 'http://gateway:39110/')
    for service, endpoint in [('user', '/users/batch'), ('stt', '/status')]:
        async with client_for(service) as client:
            assert str(client.build_request('GET', endpoint).url) == f'http://gateway:39110/internal/{service}{endpoint}'
    async with _client() as client:
        assert str(client.build_request('GET', '/oss-config').url) == 'http://gateway:39110/internal/meeting/oss-config'


@pytest.mark.parametrize('failure', ['connect', 401, 502, 503])
async def test_delete_dependency_failure_is_actionable_and_sanitized(monkeypatch, failure):
    def handler(request):
        if failure == 'connect':
            raise httpx.ConnectError('private-diagnostic-must-not-leak', request=request)
        return httpx.Response(failure, json={'detail': 'private-diagnostic-must-not-leak'})
    monkeypatch.setattr(meeting_client, '_client', lambda **kwargs: httpx.AsyncClient(
        transport=httpx.MockTransport(handler), base_url='http://gateway/internal/meeting'))
    with pytest.raises(HTTPException) as error:
        await meeting_client.MeetingClient().delete_user_data('u-test')
    assert error.value.status_code == 502
    assert '用户未删除' in error.value.detail
    assert 'private-diagnostic' not in error.value.detail
