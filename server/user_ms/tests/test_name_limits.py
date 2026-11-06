import httpx
import pytest

from user_ms.tests.helpers import register_via_sms


@pytest.mark.parametrize('character', ['名', 'a', '😀'])
async def test_registration_and_profile_name_boundaries(client: httpx.AsyncClient, character):
    name = character * 32
    account = await register_via_sms(client, name, client_id='field-limit-test', hostname='field-limit-test')
    assert account['user']['name'] == name
    updated = await client.patch('/api/v1/auth/me', json={'name': ' ' + name + ' '}, headers=account['headers'])
    assert updated.status_code == 200 and updated.json()['name'] == name
    for invalid in [name + character, '', '   ']:
        response = await client.patch('/api/v1/auth/me', json={'name': invalid}, headers=account['headers'])
        assert response.status_code == 422
        assert response.json()['detail'][0]['loc'] == ['body', 'name']
    current = await client.get('/api/v1/auth/me', headers=account['headers'])
    assert current.json()['name'] == name


@pytest.mark.parametrize('name', ['名' * 33, '😀' * 33, '', '   '])
async def test_invalid_registration_rejected_before_sms_verification(client: httpx.AsyncClient, name):
    response = await client.post('/api/v1/auth/register', json={'phone': '13800138000', 'code': '000000', 'name': name})
    assert response.status_code == 422
    assert response.json()['detail'][0]['loc'] == ['body', 'name']


@pytest.mark.parametrize('method,path', [('POST', '/admin/api/users'), ('PATCH', '/admin/api/users/not-found')])
async def test_admin_cannot_bypass_name_limit(admin: httpx.AsyncClient, method, path):
    response = await admin.request(method, path, json={'phone': '13800138000', 'name': '名' * 33})
    assert response.status_code == 422
    assert response.json()['detail'][0]['loc'] == ['body', 'name']
