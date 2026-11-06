"""Authenticated HTTP forward proxy and opaque CONNECT tunnels owned by gateway_ms.

TLS stays end-to-end: URL/Host, SDK signatures and remote certificate verification are preserved.
Only configured hosts/ports are reachable; DNS answers are validated and the chosen IP is pinned.
"""
from __future__ import annotations

import asyncio
import base64
import contextlib
import hmac
import ipaddress
import logging
import socket
from urllib.parse import urlsplit

import h11

logger = logging.getLogger(__name__)


class Denied(Exception):
    def __init__(self, status: int, message: str):
        self.status, self.message = status, message


class EgressProxy:
    def __init__(self, settings):
        self.settings = settings
        self.server = None
        self.tasks = set()
        self.active = 0

    async def start(self):
        if not self.settings.internal_service_token:
            raise RuntimeError('An internal token is required to enable egress')
        self.server = await asyncio.start_server(self.handle, self.settings.egress_host,
                                                 self.settings.egress_port, limit=32768)
        return self

    async def close(self):
        if self.server:
            self.server.close()
            await self.server.wait_closed()
        for task in list(self.tasks):
            task.cancel()
        await asyncio.gather(*self.tasks, return_exceptions=True)

    def authorize(self, headers):
        expected = b'Basic ' + base64.b64encode(('openmeeting:' + self.settings.internal_service_token).encode())
        given = headers.get(b'proxy-authorization', b'')
        if not hmac.compare_digest(given, expected):
            raise Denied(407, 'Proxy authentication required')

    async def resolve(self, hostname, port):
        host = hostname.lower().rstrip('.')
        def matches(pattern):
            pattern = pattern.lower().rstrip('.')
            return host == pattern or (pattern.startswith('*.') and host.endswith(pattern[1:]) and host != pattern[2:])
        if port not in self.settings.egress_allowed_ports or not any(matches(p) for p in self.settings.egress_allowed_hosts):
            raise Denied(403, 'Egress target denied')
        private = host in {p.lower().rstrip('.') for p in self.settings.egress_private_hosts}
        answers = await asyncio.get_running_loop().getaddrinfo(host, port, type=socket.SOCK_STREAM)
        addresses = list(dict.fromkeys(item[4][0] for item in answers))
        if not addresses:
            raise Denied(502, 'Egress DNS failed')
        for address in addresses:
            ip = ipaddress.ip_address(address)
            if getattr(ip, 'ipv4_mapped', None):
                ip = ip.ipv4_mapped
            if ip.is_link_local or ip.is_multicast or ip.is_unspecified or (not ip.is_global and not private):
                raise Denied(403, 'Egress address denied')
        return addresses

    async def connect(self, host, port):
        addresses = await asyncio.wait_for(self.resolve(host, port), self.settings.egress_connect_timeout)
        for address in addresses:
            try:
                return await asyncio.wait_for(asyncio.open_connection(address, port), self.settings.egress_connect_timeout)
            except (OSError, asyncio.TimeoutError):
                continue
        raise Denied(502, 'Egress upstream unavailable')

    async def copy(self, reader, writer):
        while True:
            data = await asyncio.wait_for(reader.read(65536), self.settings.egress_idle_timeout)
            if not data:
                return
            writer.write(data)
            await writer.drain()

    async def tunnel(self, reader, writer, upstream_reader, upstream_writer):
        tasks = [asyncio.create_task(self.copy(reader, upstream_writer)),
                 asyncio.create_task(self.copy(upstream_reader, writer))]
        try:
            done, _ = await asyncio.wait(tasks, return_when=asyncio.FIRST_COMPLETED)
            for task in done:
                task.result()
        finally:
            for task in tasks:
                task.cancel()
            await asyncio.gather(*tasks, return_exceptions=True)

    async def forward(self, reader, writer, upstream_reader, upstream_writer, head, method, parsed, headers):
        inbound = h11.Connection(h11.SERVER, max_incomplete_event_size=32768)
        inbound.receive_data(head)
        event = inbound.next_event()
        if not isinstance(event, h11.Request):
            raise Denied(400, 'Invalid proxy request')
        outgoing = h11.Connection(h11.CLIENT)
        clean = [(key, value) for key, value in headers.items()
                 if key not in {b'proxy-authorization', b'proxy-connection', b'connection', b'host', b'upgrade'}]
        authority = parsed.netloc.encode('ascii')
        clean += [(b'host', authority), (b'connection', b'close')]
        target = (parsed.path or '/') + ('?' + parsed.query if parsed.query else '')
        upstream_writer.write(outgoing.send(h11.Request(method=method, target=target.encode('ascii'), headers=clean)))
        await upstream_writer.drain()

        async def body():
            while True:
                event = inbound.next_event()
                if event is h11.NEED_DATA:
                    data = await asyncio.wait_for(reader.read(65536), self.settings.egress_idle_timeout)
                    inbound.receive_data(data)
                elif isinstance(event, h11.Data):
                    upstream_writer.write(outgoing.send(h11.Data(data=event.data)))
                    await upstream_writer.drain()
                elif isinstance(event, h11.EndOfMessage):
                    upstream_writer.write(outgoing.send(h11.EndOfMessage()))
                    await upstream_writer.drain()
                    return
                else:
                    raise Denied(400, 'Invalid proxy body')
        upload = asyncio.create_task(body())
        response = asyncio.create_task(self.copy(upstream_reader, writer))
        try:
            done, _ = await asyncio.wait([upload, response], return_when=asyncio.FIRST_COMPLETED)
            if upload in done:
                upload.result()
            await response
        finally:
            upload.cancel()
            response.cancel()
            await asyncio.gather(upload, response, return_exceptions=True)

    async def handle(self, reader, writer):
        task = asyncio.current_task()
        self.tasks.add(task)
        upstream_writer = None
        started = False
        admitted = False
        host, port, method = '', 0, b''
        status = 500
        try:
            head = await asyncio.wait_for(reader.readuntil(b'\r\n\r\n'), 10)
            lines = head[:-4].split(b'\r\n')
            method, target, version = lines[0].split(b' ')
            if version not in {b'HTTP/1.0', b'HTTP/1.1'}:
                raise Denied(400, 'Invalid HTTP version')
            headers = {}
            for line in lines[1:]:
                key, value = line.split(b':', 1)
                key = key.lower()
                if key in headers:
                    raise Denied(400, 'Duplicate proxy header')
                headers[key] = value.strip()
            if b'content-length' in headers and b'transfer-encoding' in headers:
                raise Denied(400, 'Ambiguous request framing')
            self.authorize(headers)
            if self.active >= self.settings.egress_max_connections:
                raise Denied(503, 'Egress capacity reached')
            self.active += 1
            admitted = True
            if method == b'CONNECT':
                parsed = urlsplit('//' + target.decode('ascii'))
                if parsed.path or parsed.query or parsed.fragment or not parsed.port:
                    raise Denied(400, 'Invalid CONNECT target')
            else:
                parsed = urlsplit(target.decode('ascii'))
                if method not in {b'GET', b'HEAD', b'POST', b'PUT', b'PATCH', b'DELETE', b'OPTIONS'} or parsed.scheme != 'http':
                    raise Denied(400, 'Invalid forward request')
            if not parsed.hostname or parsed.username or parsed.password or parsed.fragment:
                raise Denied(400, 'Invalid egress target')
            host, port = parsed.hostname, parsed.port or 80
            upstream_reader, upstream_writer = await self.connect(host, port)
            status = 200
            if method == b'CONNECT':
                writer.write(b'HTTP/1.1 200 Connection Established\r\n\r\n')
                await writer.drain()
                started = True
                await self.tunnel(reader, writer, upstream_reader, upstream_writer)
            else:
                # Errors after request forwarding close the connection; never splice a second HTTP response.
                started = True
                await self.forward(reader, writer, upstream_reader, upstream_writer, head, method, parsed, headers)
        except Denied as exc:
            status = exc.status
            if not started:
                await self.reject(writer, exc.status, exc.message)
        except (ValueError, UnicodeError, h11.ProtocolError, asyncio.LimitOverrunError, asyncio.IncompleteReadError):
            status = 400
            if not started:
                await self.reject(writer, 400, 'Invalid proxy request')
        except (OSError, asyncio.TimeoutError):
            status = 502
            if not started:
                await self.reject(writer, 502, 'Egress upstream unavailable')
        finally:
            if admitted:
                self.active -= 1
            for stream in [upstream_writer, writer]:
                if stream:
                    stream.close()
                    with contextlib.suppress(Exception):
                        await asyncio.wait_for(stream.wait_closed(), 2)
            self.tasks.discard(task)
            logger.info('egress method=%s host=%s port=%s status=%s', method.decode('ascii', 'replace'), host, port, status)

    async def reject(self, writer, status, message):
        body = message.encode('ascii')
        extra = 'Proxy-Authenticate: Basic realm="openmeeting-egress"\r\n' if status == 407 else ''
        writer.write((f'HTTP/1.1 {status} Proxy Error\r\n{extra}Content-Length: {len(body)}\r\nConnection: close\r\n\r\n').encode() + body)
        with contextlib.suppress(OSError):
            await writer.drain()
