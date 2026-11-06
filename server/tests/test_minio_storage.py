from dataclasses import replace
from urllib.parse import parse_qs, urlsplit

from fastapi import HTTPException
import pytest
import urllib3

from meeting_ms.config import Settings
from meeting_ms.storage import oss
from service_net.minio_store import MinioStore, endpoint_parts


def settings(**changes):
    return Settings(_env_file=None, env='test', egress_proxy_url='', storage_provider='minio',
                    minio_endpoint='http://minio:9000', minio_public_endpoint='http://192.0.2.1:39120',
                    minio_bucket='test-bucket', minio_access_key_id='test-access',
                    minio_access_key_secret='test-secret', **changes)


@pytest.fixture
def configured(monkeypatch):
    current = settings()
    monkeypatch.setattr(oss, 'get_settings', lambda: current)

    async def stored():
        return {'endpoint': 'oss-cn-hangzhou.aliyuncs.com', 'region': 'cn-hangzhou', 'bucket': 'legacy-bucket',
                'access_key_id': 'legacy-access', 'prefix': 'legacy/'}

    monkeypatch.setattr(oss, 'load_stored_oss_config', stored)
    current.oss_access_key_secret = 'legacy-secret'
    return current


async def test_minio_and_oss_configurations_are_separate_and_history_survives_switch(configured):
    minio = await oss.load_oss_config()
    assert minio.provider == 'minio' and minio.ready and minio.bucket == 'test-bucket'
    assert minio.access_key_secret == 'test-secret'
    legacy = await oss.load_oss_config('oss')
    assert legacy.provider == 'oss' and legacy.ready and legacy.bucket == 'legacy-bucket'
    assert legacy.access_key_secret == 'legacy-secret'
    configured.storage_provider = 'oss'
    assert (await oss.load_oss_config()).provider == 'oss'
    assert await oss.load_oss_config('minio') == minio
    configured.storage_provider = 'local'
    assert not (await oss.load_oss_config()).ready
    assert (await oss.load_oss_config('minio')).ready


async def test_explicit_minio_missing_secret_does_not_fall_back_to_oss_or_disk(configured):
    configured.minio_access_key_secret = ''
    assert not (await oss.load_oss_config()).ready
    with pytest.raises(HTTPException) as failure:
        await oss.get_audio_store()
    assert failure.value.status_code == 503
    assert (await oss.load_oss_config('oss')).ready


async def test_presigned_url_uses_public_host_and_sigv4_without_network(configured):
    cfg = await oss.load_oss_config()
    url = MinioStore(cfg, configured).presign_get('openmeeting/audio/user/meeting/录音.wav')
    parsed = urlsplit(url)
    assert parsed.netloc == '192.0.2.1:39120'
    query = parse_qs(parsed.query)
    assert query['X-Amz-Algorithm'] == ['AWS4-HMAC-SHA256']
    assert query['X-Amz-Expires'] == ['3600']
    assert 'X-Amz-Signature' in query
    assert 'minio:9000' not in url
    assert not replace(cfg, public_endpoint=None).ready


async def test_minio_sdk_transport_uses_authenticated_gateway_proxy(configured):
    configured.egress_proxy_url = 'http://gateway_ms:39111'
    configured.internal_service_token = 'fixture-token'
    client = MinioStore(await oss.load_oss_config(), configured)
    assert isinstance(client.client._http, urllib3.ProxyManager)
    assert client.client._http.proxy.host == 'gateway_ms'
    assert client.client._http.proxy_headers == urllib3.make_headers(proxy_basic_auth='openmeeting:fixture-token')


@pytest.mark.parametrize('endpoint', ['http://user:secret@minio:9000', 'http://minio:9000/path', 'ftp://minio:9000', 'http://minio:9000?x=y'])
def test_invalid_endpoint_rejected(endpoint):
    with pytest.raises(ValueError):
        endpoint_parts(endpoint)
