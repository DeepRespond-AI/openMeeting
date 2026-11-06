"""Loopback-only temporary IM users/channel. No business DB or exported credentials."""
import os
import sys
import re
import asyncio
from pathlib import Path
from uuid import uuid4
from contextlib import asynccontextmanager
sys.path.insert(0, str(Path(__file__).resolve().parents[3] / 'server'))
from dotenv import dotenv_values
for key, value in dotenv_values(os.environ['OPENMEETING_RTC_TEST_ENV']).items():
    if key.startswith('OPENMEETING_IM_') and value is not None:
        os.environ[key] = value
# This isolated harness has no business DB and never changes deployed egress settings.
os.environ.update(OPENMEETING_ENV='test', OPENMEETING_EGRESS_PROXY_URL='')
for key in ('HTTP_PROXY', 'HTTPS_PROXY', 'ALL_PROXY'):
    os.environ.pop(key, None)
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from user_ms.infrastructure.im_client import get_client, aclose_client
from user_ms.config import get_settings

users = {}
channel = 'screen-test-' + uuid4().hex[:16]
created = False

async def cleanup():
    global created
    errors = []
    sdk = await get_client()
    channel_status = 'not_created'
    close_requested = False
    if created:
        try:
            result = await sdk.channels.close(channel, reason='test_complete')
            channel_status = result.channel.status
            close_requested = True
        except Exception as e:
            errors.append('channel:' + type(e).__name__)
    for alias, username in list(users.items()):
        try:
            await sdk.users.delete(username)
            del users[alias]
        except Exception as e:
            errors.append('user:' + type(e).__name__)
    if created and close_requested:
        deadline = asyncio.get_running_loop().time() + 20
        try:
            while channel_status != 'closed' and asyncio.get_running_loop().time() < deadline:
                await asyncio.sleep(.25)
                channel_status = (await sdk.channels.get(channel)).channel.status
            created = channel_status != 'closed'
            if created:
                errors.append('channel: close still pending')
        except Exception as e:
            errors.append('channel verification:' + type(e).__name__)
    return {'errors': errors, 'remainingUsers': len(users), 'channelId': channel,
            'channelClosed': not created, 'channelStatus': channel_status}

@asynccontextmanager
async def lifespan(app):
    yield
    await cleanup()
    await aclose_client()

app = FastAPI(lifespan=lifespan)
app.add_middleware(CORSMiddleware, allow_origins=['http://127.0.0.1:3188'], allow_methods=['*'], allow_headers=['*'])

@app.get('/health')
async def health():
    return {'service': 'isolated-im-screen-test', 'credentials': 'memory-only'}

@app.get('/config/{alias}')
async def config(alias: str, scope: str = 'probe'):
    global created
    if alias not in ('host', 'peer', 'late', 'viewer'):
        raise HTTPException(400, 'Unknown isolated test alias')
    if not re.fullmatch(r'[a-zA-Z0-9-]{1,64}', scope):
        raise HTTPException(400, 'Invalid isolated browser scope')
    sdk = await get_client()
    if not created:
        await sdk.channels.create(channel, name='Temporary screen acceptance', media='video', access_mode='ticket', default_role='publisher', max_participants=10)
        created = True
    identity = alias + ':' + scope
    if identity not in users:
        users[identity] = 'screen-validation-' + uuid4().hex[:16]
    username = users[identity]
    login = await sdk.users.issue_login_ticket(username, auto_create=True)
    role = 'subscriber' if alias == 'viewer' else 'publisher'
    tickets = await sdk.channels.issue_tickets(channel, users=[{'username': username, 'role': role}], ttl_seconds=120)
    item = tickets.tickets[0]
    s = get_settings()
    return {'apiUrl': s.im_base_url, 'appKey': f'{s.im_org_name}#{s.im_app_name}', 'username': username,
            'loginTicket': login.ticket, 'channelId': channel, 'ticket': item.ticket, 'role': role, 'expiresAt': item.expires_at.isoformat()}

@app.post('/cleanup')
async def do_cleanup():
    return await cleanup()

@app.post('/shutdown')
async def shutdown():
    server.should_exit = True
    return {'stopping': True}

if __name__ == '__main__':
    import uvicorn
    server = uvicorn.Server(uvicorn.Config(app, host='127.0.0.1', port=3177, access_log=False, log_level='warning'))
    server.run()
