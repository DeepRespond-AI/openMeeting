"""Real local sockets, verified TLS, request libraries and WebSockets through the gateway proxy."""
import asyncio
import base64
from contextlib import suppress
from datetime import datetime, timedelta, timezone
import ipaddress
import ssl
from types import SimpleNamespace

import h11
import httpx
import pytest
import requests
import websockets
from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.x509.oid import NameOID

from gateway_ms.infrastructure.egress import EgressProxy
from service_net.egress import async_client, configure_requests, configure_sdk_environment, proxy_address


@pytest.fixture
async def upstream(tmp_path):
    key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    name = x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, 'localhost')])
    now = datetime.now(timezone.utc)
    cert = (x509.CertificateBuilder().subject_name(name).issuer_name(name).public_key(key.public_key())
        .serial_number(x509.random_serial_number()).not_valid_before(now-timedelta(minutes=1))
        .not_valid_after(now+timedelta(days=1)).add_extension(x509.BasicConstraints(ca=True, path_length=None), True)
        .add_extension(x509.SubjectAlternativeName([x509.DNSName('localhost'), x509.IPAddress(ipaddress.ip_address('127.0.0.1'))]), False)
        .sign(key, hashes.SHA256()))
    certfile, keyfile = tmp_path/'cert.pem', tmp_path/'key.pem'
    certfile.write_bytes(cert.public_bytes(serialization.Encoding.PEM))
    keyfile.write_bytes(key.private_bytes(serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8, serialization.NoEncryption()))
    tls = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    tls.load_cert_chain(certfile, keyfile)
    received = []
    active = set()

    async def handle(reader, writer):
        task = asyncio.current_task(); active.add(task)
        try:
            conn = h11.Connection(h11.SERVER)
            request = None; body = b''
            while True:
                event = conn.next_event()
                if event is h11.NEED_DATA:
                    conn.receive_data(await reader.read(65536))
                elif isinstance(event, h11.Request):
                    request = event
                elif isinstance(event, h11.Data):
                    body += event.data
                elif isinstance(event, h11.EndOfMessage):
                    break
                else:
                    return
            headers = dict(request.headers)
            received.append({'path':request.target, 'body':body, 'headers':headers})
            if request.target == b'/stream':
                writer.write(conn.send(h11.Response(status_code=200, headers=[('Content-Type','text/event-stream'),('Connection','close')])))
                writer.write(conn.send(h11.Data(data=b'data: first\n\n'))); await writer.drain()
                await asyncio.sleep(0.1)
                writer.write(conn.send(h11.Data(data=b'data: second\n\n')))
            else:
                writer.write(conn.send(h11.Response(status_code=200, headers=[('Content-Type','application/octet-stream'),('Connection','close')])))
                writer.write(conn.send(h11.Data(data=body or b'upstream-ok')))
            writer.write(conn.send(h11.EndOfMessage())); await writer.drain()
        finally:
            writer.close()
            with suppress(Exception): await writer.wait_closed()
            active.discard(task)
    plain = await asyncio.start_server(handle, '127.0.0.1', 0)
    secure = await asyncio.start_server(handle, '127.0.0.1', 0, ssl=tls)
    p, s = plain.sockets[0].getsockname()[1], secure.sockets[0].getsockname()[1]
    yield SimpleNamespace(http=f'http://127.0.0.1:{p}', https=f'https://127.0.0.1:{s}', ports=[p,s], cert=str(certfile), tls=tls, received=received)
    for server in [plain,secure]: server.close(); await server.wait_closed()
    for task in list(active): task.cancel()
    await asyncio.gather(*active, return_exceptions=True)


@pytest.fixture
async def proxy(upstream):
    settings = SimpleNamespace(internal_service_token='unit-egress-secret', egress_host='127.0.0.1', egress_port=0,
        egress_allowed_hosts=['127.0.0.1'], egress_private_hosts=['127.0.0.1'], egress_allowed_ports=upstream.ports,
        egress_connect_timeout=1, egress_idle_timeout=2, egress_max_connections=20)
    instance = await EgressProxy(settings).start()
    port = instance.server.sockets[0].getsockname()[1]
    settings.egress_proxy_url=f'http://127.0.0.1:{port}'
    settings.is_dev=False
    yield SimpleNamespace(instance=instance, settings=settings, url=f'http://openmeeting:unit-egress-secret@127.0.0.1:{port}', port=port)
    await instance.close()


async def connect_status(proxy, target, auth=True, version='HTTP/1.1'):
    reader, writer=await asyncio.open_connection('127.0.0.1',proxy.port)
    authorization='Proxy-Authorization: Basic '+base64.b64encode(b'openmeeting:unit-egress-secret').decode()+'\r\n' if auth else ''
    writer.write(f'CONNECT {target} {version}\r\nHost: {target}\r\n{authorization}\r\n'.encode()); await writer.drain()
    response=await reader.readuntil(b'\r\n\r\n')
    return int(response.split()[1]), reader, writer


async def test_http_bytes_query_and_credentials_remain_separate(upstream, proxy):
    async with async_client(proxy.settings) as client:
        response=await client.post(upstream.http+'/echo?q=one&q=two',content=b'\x00\xff\x11',headers={'Authorization':'Bearer vendor-test-key'})
    assert response.status_code==200 and response.content==b'\x00\xff\x11'
    request=upstream.received[-1]
    assert request['path']==b'/echo?q=one&q=two'
    assert request['headers'][b'authorization']==b'Bearer vendor-test-key'
    assert b'proxy-authorization' not in request['headers']


async def test_https_tls_verified_and_proxy_header_not_sent_to_origin(upstream,proxy):
    async with async_client(proxy.settings,verify=ssl.create_default_context(cafile=upstream.cert)) as client:
        assert (await client.post(upstream.https+'/echo',content=b'tls-intact')).content==b'tls-intact'
    assert b'proxy-authorization' not in upstream.received[-1]['headers']
    async with async_client(proxy.settings) as client:
        with pytest.raises(httpx.ConnectError):
            await client.get(upstream.https+'/untrusted')


async def test_requests_sdk_transport_through_verified_connect(upstream,proxy):
    def run():
        with requests.Session() as session:
            configure_requests(session,proxy.settings)
            return session.post(upstream.https+'/signed',data=b'signed-payload',headers={'Authorization':'OSS4-HMAC-SHA256 signature'},verify=upstream.cert)
    response=await asyncio.to_thread(run)
    assert response.content==b'signed-payload'
    assert upstream.received[-1]['headers'][b'authorization']==b'OSS4-HMAC-SHA256 signature'
    assert b'proxy-authorization' not in upstream.received[-1]['headers']


async def test_chunked_upload_and_sse_stream_are_not_buffered(upstream,proxy):
    async def chunks():
        yield b'first';await asyncio.sleep(0.01);yield b'second'
    async with async_client(proxy.settings) as client:
        assert (await client.post(upstream.http+'/echo',content=chunks())).content==b'firstsecond'
        async with client.stream('GET',upstream.http+'/stream') as response:
            parts=response.aiter_raw()
            first=await anext(parts)
            assert b'first' in first and b'second' not in first
            assert b'second' in b''.join([chunk async for chunk in parts])


@pytest.mark.parametrize('auth,target,status',[(False,'127.0.0.1:443',407),(True,'example.invalid:443',403),(True,'127.0.0.1:22',403)])
async def test_proxy_auth_host_and_port_denials(upstream,proxy,auth,target,status):
    actual,reader,writer=await connect_status(proxy,target,auth)
    assert actual==status and not upstream.received
    writer.close();await writer.wait_closed()


async def test_private_dns_and_rebinding_answers_are_denied(upstream,proxy,monkeypatch):
    proxy.settings.egress_private_hosts=[]
    status,_,writer=await connect_status(proxy,'127.0.0.1:'+str(upstream.ports[1]));assert status==403
    writer.close();await writer.wait_closed()
    proxy.settings.egress_allowed_hosts=['api.example.com']
    async def answers(*args,**kwargs):
        return [(2,1,6,'',('93.184.216.34',443)),(2,1,6,'',('169.254.169.254',443))]
    monkeypatch.setattr(asyncio.get_running_loop(),'getaddrinfo',answers)
    with pytest.raises(Exception,match='Egress address denied'):
        await proxy.instance.resolve('api.example.com',upstream.ports[0])


async def test_http10_connect_capacity_and_shutdown(upstream,proxy):
    proxy.settings.egress_max_connections=1
    status,reader,writer=await connect_status(proxy,'127.0.0.1:'+str(upstream.ports[1]),version='HTTP/1.0');assert status==200
    status,_,other=await connect_status(proxy,'127.0.0.1:'+str(upstream.ports[1]));assert status==503
    other.close();await other.wait_closed()
    await proxy.instance.close()
    assert await asyncio.wait_for(reader.read(),1)==b''
    writer.close();await writer.wait_closed()


async def test_wss_full_duplex_over_authenticated_proxy(upstream,proxy):
    from websockets.asyncio.server import serve
    async def echo(connection):
        async for message in connection: await connection.send(message)
    async with serve(echo,'127.0.0.1',0,ssl=upstream.tls) as server:
        port=server.sockets[0].getsockname()[1];proxy.settings.egress_allowed_ports.append(port)
        async with websockets.connect(f'wss://127.0.0.1:{port}/asr',proxy=proxy.url,ssl=ssl.create_default_context(cafile=upstream.cert)) as connection:
            await connection.send('音频控制');assert await connection.recv()=='音频控制'
            await connection.send(b'\x00\xff');assert await connection.recv()==b'\x00\xff'


def test_no_production_direct_fallback_and_sdk_environment(monkeypatch):
    settings=SimpleNamespace(egress_proxy_url='',is_dev=False,internal_service_token='secret')
    with pytest.raises(RuntimeError,match='required'):proxy_address(settings)
    settings.egress_proxy_url='http://gateway:39111';settings.internal_service_token='a:@ b'
    with monkeypatch.context() as patch:
        for name in ['HTTP_PROXY','HTTPS_PROXY','ALL_PROXY','http_proxy','https_proxy','all_proxy','NO_PROXY','no_proxy','HF_HUB_DISABLE_XET','HF_HUB_ENABLE_HF_TRANSFER']:
            patch.setenv(name,'old')
        configure_sdk_environment(settings)
        import os
        assert os.environ['HTTPS_PROXY']=='http://openmeeting:a%3A%40%20b@gateway:39111'
        assert os.environ['NO_PROXY']=='' and os.environ['no_proxy']==''
        assert os.environ['HF_HUB_DISABLE_XET']=='1'
