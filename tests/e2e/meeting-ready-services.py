"""Isolated real gateway/user/meeting services; only IM deployment config is reused.

Run from server with the existing virtualenv. No auth/IM/RTC transport is mocked.
The deterministic fault branch is enabled only on this loopback test process.
"""
import argparse
import asyncio
import ipaddress
import json
import os
from pathlib import Path
import secrets
import socket
import subprocess
import sys
import time
import urllib.request
from urllib.parse import urlsplit

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'server'))
OUT = Path(os.environ.get('MEETING_READY_OUTPUT', str(ROOT / '.artifacts' / 'meeting-ready-im-sync'))).resolve()
OUT.mkdir(parents=True, exist_ok=True)
PG_PORT = int(os.environ.get('MEETING_READY_PG_PORT', '55439'))
BASE = f'postgresql+asyncpg://openmeeting:openmeeting@127.0.0.1:{PG_PORT}/'
PORT_OFFSET = int(os.environ.get('MEETING_READY_PORT_OFFSET', '0'))
PORTS = {name: port + PORT_OFFSET for name, port in {'gateway':3160, 'user':3161, 'egress':3163, 'meeting':3167}.items()}


async def seed(env):
    import asyncpg
    from user_ms.auth.passwords import hash_password
    conn = await asyncpg.connect(f'postgresql://openmeeting:openmeeting@127.0.0.1:{PG_PORT}/postgres')
    for db in ['meeting_ready_user', 'meeting_ready_meeting']:
        if not await conn.fetchval('SELECT 1 FROM pg_database WHERE datname=$1', db):
            await conn.execute(f'CREATE DATABASE {db}')
    await conn.close()
    os.environ.update(env)
    from user_ms.db.session import run_migrations
    await run_migrations(BASE + 'meeting_ready_user')
    file = OUT / 'accounts.private.json'
    if not file.exists():
        tag = secrets.token_hex(5)
        accounts = [{'id': f'im-ready-{tag}-{i}', 'phone': f'199{secrets.randbelow(10**8):08}',
                     'name': f'IM Ready {chr(65+i)}', 'password': secrets.token_hex(12)+'A1'} for i in range(3)]
        conn = await asyncpg.connect(f'postgresql://openmeeting:openmeeting@127.0.0.1:{PG_PORT}/meeting_ready_user')
        for item in accounts:
            await conn.execute('INSERT INTO users(id,phone,name,password_hash) VALUES($1,$2,$3,$4)',
                               item['id'], item['phone'], item['name'], hash_password(item['password']))
        await conn.close()
        file.write_text(json.dumps(accounts), encoding='utf8')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--env', required=True)
    parser.add_argument('--service', choices=['gateway', 'user', 'meeting'])
    args = parser.parse_args()
    args.env = str(Path(args.env).resolve(strict=True))
    from dotenv import dotenv_values
    env = dict(os.environ)
    for key in list(env):
        if key.upper() in ['HTTP_PROXY', 'HTTPS_PROXY', 'ALL_PROXY'] or key.startswith('OPENMEETING_'):
            env.pop(key)
    deployment = dotenv_values(args.env)
    env.update({k: v for k, v in deployment.items() if k.startswith('OPENMEETING_IM_') and v is not None})
    im_host = urlsplit(deployment.get('OPENMEETING_IM_BASE_URL') or '').hostname
    env.update(OPENMEETING_ENV='dev', OPENMEETING_SECRET_KEY='isolated-native-meeting-ready-test-key',
               OPENMEETING_ADMIN_PASSWORD='isolated-test-admin', OPENMEETING_INTERNAL_SERVICE_TOKEN='isolated-native-ready',
               OPENMEETING_GATEWAY_MS_URL=f'http://127.0.0.1:{PORTS["gateway"]}',
               OPENMEETING_EGRESS_PROXY_URL=f'http://127.0.0.1:{PORTS["egress"]}',
               OPENMEETING_EGRESS_ENABLED='true', OPENMEETING_EGRESS_HOST='127.0.0.1', OPENMEETING_EGRESS_PORT=str(PORTS['egress']),
               OPENMEETING_EGRESS_ALLOWED_HOSTS=deployment.get('OPENMEETING_EGRESS_ALLOWED_HOSTS') or json.dumps([im_host] if im_host else []),
               OPENMEETING_EGRESS_ALLOWED_PORTS=deployment.get('OPENMEETING_EGRESS_ALLOWED_PORTS') or '[80,443]',
               OPENMEETING_EGRESS_PRIVATE_HOSTS=deployment.get('OPENMEETING_EGRESS_PRIVATE_HOSTS') or '[]',
               OPENMEETING_USER_MS_URL=f'http://127.0.0.1:{PORTS["user"]}', OPENMEETING_MEETING_MS_URL=f'http://127.0.0.1:{PORTS["meeting"]}',
               OPENMEETING_STT_MS_URL='http://127.0.0.1:39109', OPENMEETING_AUTO_MIGRATE='true')
    if args.service:
        port = PORTS[args.service]
        env['OPENMEETING_DATABASE_URL'] = BASE + ('meeting_ready_meeting' if args.service == 'meeting' else 'meeting_ready_user')
        env['OPENMEETING_DATA_DIR'] = str(OUT / 'server-data' / args.service)
        os.environ.update(env)
        # Explicit test DNS mapping for hosts with Fake-IP interception. This
        # changes name resolution only: the production proxy still authenticates,
        # checks the original hostname/port and validates every resolved address.
        if args.service == 'gateway' and os.environ.get('MEETING_READY_DNS_MAP'):
            mapping = json.loads(Path(os.environ['MEETING_READY_DNS_MAP']).read_text(encoding='utf8'))
            if not all(isinstance(host, str) and ipaddress.ip_address(address).is_global for host, address in mapping.items()):
                raise ValueError('Test DNS overrides must resolve to public IP addresses')
            original_lookup = socket.getaddrinfo
            def lookup(host, port, *lookup_args, **lookup_kwargs):
                return original_lookup(mapping.get(host, host), port, *lookup_args, **lookup_kwargs)
            socket.getaddrinfo = lookup
        import uvicorn
        if args.service == 'meeting':
            # Explicitly controlled failures, used only in this isolated server.
            from fastapi import HTTPException
            from meeting_ms.infrastructure import im_chat, rtc_client
            original_chat, original_rtc = im_chat.request, rtc_client.ensure_channel

            async def chat(path, payload=None):
                flags = json.loads((OUT / 'faults.json').read_text()) if (OUT / 'faults.json').exists() else {}
                if flags.get('chat'):
                    raise HTTPException(503, 'Deterministic IM preparation outage')
                return await original_chat(path, payload)

            async def rtc(room):
                flags = json.loads((OUT / 'faults.json').read_text()) if (OUT / 'faults.json').exists() else {}
                if flags.get('rtc'):
                    return False
                if flags.get('delay'):
                    await asyncio.sleep(min(10, flags['delay']))
                return await original_rtc(room)
            im_chat.request, rtc_client.ensure_channel = chat, rtc
            # Deterministic controls failure/loading for explicit recording E2E.
            # This middleware exists only in the isolated loopback launcher.
            from meeting_ms.main import app
            from fastapi.responses import JSONResponse

            @app.middleware('http')
            async def recording_control_fault(request, call_next):
                if request.url.path.endswith('/audio'):
                    flags = json.loads((OUT / 'faults.json').read_text()) if (OUT / 'faults.json').exists() else {}
                    if flags.get('audioDownload'):
                        return JSONResponse({'detail': 'Deterministic recording download outage'}, status_code=503)
                    if flags.get('audioDelay'):
                        await asyncio.sleep(min(10, flags['audioDelay']))
                if request.url.path.endswith('/recording/control'):
                    flags = json.loads((OUT / 'faults.json').read_text()) if (OUT / 'faults.json').exists() else {}
                    if flags.get('recordingControl'):
                        return JSONResponse({'detail':'Deterministic recording control outage'}, status_code=503)
                    if flags.get('recordingDelay'):
                        await asyncio.sleep(min(10, flags['recordingDelay']))
                return await call_next(request)

            @app.get('/__e2e/recording/{room_id}')
            async def recording_probe(room_id: str):
                from sqlalchemy import select, func
                from meeting_ms.db.session import session_factory
                from meeting_ms.db.models import LiveRoom, RoomRecordingChunk
                accounts = json.loads((OUT / 'accounts.private.json').read_text(encoding='utf8'))
                async with session_factory()() as session:
                    room = await session.get(LiveRoom, room_id)
                    if not room or room.host_user_id not in {a['id'] for a in accounts}:
                        raise HTTPException(404, 'Not an owned isolated test room')
                    chunks = (await session.execute(select(RoomRecordingChunk.recording_epoch,
                        func.count(), func.sum(RoomRecordingChunk.size)).where(
                        RoomRecordingChunk.room_id == room_id).group_by(RoomRecordingChunk.recording_epoch))).all()
                    return {'active':room.recording_active,'epoch':room.recording_epoch,
                        'chunks':sum(row[1] for row in chunks),
                        'epochs':[{'epoch':row[0],'chunks':row[1],'bytes':row[2]} for row in chunks]}
        uvicorn.run(f'{args.service}_ms.main:app', host='127.0.0.1', port=port, log_level='warning')
        return
    for port in PORTS.values():
        with socket.socket() as probe:
            if probe.connect_ex(('127.0.0.1',port)) == 0:
                raise RuntimeError(f'Port {port} already occupied; preserve existing service')
    asyncio.run(seed(env))
    children=[]
    try:
        for service in ['user', 'meeting', 'gateway']:
            log = open(OUT / f'{service}.log', 'a', encoding='utf8')
            child = subprocess.Popen([sys.executable, __file__, '--env', args.env, '--service', service],
                                     cwd=ROOT/'server', env=env, stdout=log, stderr=log,
                                     creationflags=subprocess.CREATE_NO_WINDOW)
            log.close()
            children.append(child)
        (OUT/'services.json').write_text(json.dumps({'pids':[c.pid for c in children]}), encoding='utf8')
        for port in [PORTS['gateway'],PORTS['user'],PORTS['meeting']]:
            for _ in range(90):
                try:
                    with urllib.request.urlopen(f'http://127.0.0.1:{port}/healthz', timeout=1) as response:
                        assert response.status == 200
                    break
                except Exception:
                    if any(c.poll() is not None for c in children):
                        raise RuntimeError('Service exited; inspect task logs')
                    time.sleep(1)
            else:
                raise RuntimeError(f'Service {port} failed readiness')
        print(json.dumps({'operation':'services_ready','ports':PORTS,'pass':True}), flush=True)
        while all(c.poll() is None for c in children):
            time.sleep(1)
    finally:
        for child in children:
            child.terminate()
        for child in children:
            child.wait(timeout=20)
        (OUT/'service-cleanup.json').write_text(json.dumps({'closed': True, 'pids':[c.pid for c in children]}), encoding='utf8')


if __name__ == '__main__':
    main()
