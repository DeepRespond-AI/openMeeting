"""Real isolated services for native UI acceptance; no API/IM/RTC substitutes."""
import argparse
import asyncio
import json
import os
from pathlib import Path
import secrets
import sys
from urllib.parse import urlsplit

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'server'))
OUT = Path(os.environ['MEETING_UI_NATIVE_OUTPUT']).resolve()
OUT.mkdir(parents=True, exist_ok=True)


def environment(service=None):
    from dotenv import dotenv_values
    deployment = dotenv_values(os.environ.get('OPENMEETING_RTC_TEST_ENV') or ROOT / 'server' / '.env')
    im_host = urlsplit(deployment.get('OPENMEETING_IM_BASE_URL') or '').hostname
    env = {k: v for k, v in os.environ.items() if not k.startswith('OPENMEETING_') and k.upper() not in ['HTTP_PROXY', 'HTTPS_PROXY', 'ALL_PROXY']}
    env.update({k: v for k, v in deployment.items() if k.startswith('OPENMEETING_IM_') and v is not None})
    env.update(OPENMEETING_ENV='dev', OPENMEETING_SECRET_KEY='meeting-ui-native-isolated-key',
               OPENMEETING_ADMIN_PASSWORD='meeting-ui-native-test-only',
               OPENMEETING_INTERNAL_SERVICE_TOKEN=deployment.get('INTERNAL_SERVICE_TOKEN') or deployment.get('OPENMEETING_INTERNAL_SERVICE_TOKEN') or 'meeting-ui-native-test-only',
               OPENMEETING_GATEWAY_MS_URL='http://127.0.0.1:3160',
               OPENMEETING_EGRESS_PROXY_URL='http://127.0.0.1:3163',
               OPENMEETING_EGRESS_ENABLED='true', OPENMEETING_EGRESS_HOST='127.0.0.1', OPENMEETING_EGRESS_PORT='3163',
               OPENMEETING_EGRESS_ALLOWED_HOSTS=deployment.get('OPENMEETING_EGRESS_ALLOWED_HOSTS') or json.dumps([im_host] if im_host else []),
               OPENMEETING_EGRESS_ALLOWED_PORTS=deployment.get('OPENMEETING_EGRESS_ALLOWED_PORTS') or '[80,443]',
               OPENMEETING_EGRESS_PRIVATE_HOSTS=deployment.get('OPENMEETING_EGRESS_PRIVATE_HOSTS') or '[]',
               OPENMEETING_USER_MS_URL='http://127.0.0.1:3161', OPENMEETING_MEETING_MS_URL='http://127.0.0.1:3167',
               OPENMEETING_STT_MS_URL='http://127.0.0.1:39109', OPENMEETING_AUTO_MIGRATE='true')
    suffix = ''.join(c for c in OUT.name if c.isalnum())[-24:]
    database = f'meeting_ui_{suffix}_' + ('meeting' if service == 'meeting' else 'user')
    env.update(OPENMEETING_DATABASE_URL=f'postgresql+asyncpg://openmeeting:openmeeting@127.0.0.1:55439/{database}',
               OPENMEETING_DATA_DIR=str(OUT / 'server-data' / (service or 'user')))
    return env


async def seed():
    import asyncpg
    env = environment()
    os.environ.update(env)
    conn = await asyncpg.connect('postgresql://openmeeting:openmeeting@127.0.0.1:55439/postgres')
    databases = []
    for service in ['user', 'meeting']:
        database = environment(service)['OPENMEETING_DATABASE_URL'].rsplit('/', 1)[1]
        databases.append(database)
        if not await conn.fetchval('SELECT 1 FROM pg_database WHERE datname=$1', database):
            await conn.execute(f'CREATE DATABASE "{database}"')
    await conn.close()
    from user_ms.db.session import run_migrations
    from user_ms.auth.passwords import hash_password
    await run_migrations(env['OPENMEETING_DATABASE_URL'])
    file = OUT / 'accounts.private.json'
    if not file.exists():
        tag = secrets.token_hex(5)
        accounts = [dict(id=f'ui-native-{tag}-{i}', phone=f'199{secrets.randbelow(10**8):08}', name=f'模块配置验收 {chr(65+i)}', password=secrets.token_hex(12)+'A1') for i in range(3)]
        conn = await asyncpg.connect(env['OPENMEETING_DATABASE_URL'].replace('+asyncpg', ''))
        for account in accounts:
            await conn.execute('INSERT INTO users(id,phone,name,password_hash) VALUES($1,$2,$3,$4)', account['id'], account['phone'], account['name'], hash_password(account['password']))
        await conn.close()
        file.write_text(json.dumps(accounts), encoding='utf8')
    (OUT / 'databases.json').write_text(json.dumps({'databases': databases}), encoding='utf8')
    print(json.dumps({'operation': 'seed isolated native accounts', 'accounts': 3, 'databases': databases, 'pass': True}), flush=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--service', choices=['gateway', 'user', 'meeting'])
    args = parser.parse_args()
    if args.service:
        service_env = environment(args.service)
        for key in list(os.environ):
            if key.upper() in ['HTTP_PROXY', 'HTTPS_PROXY', 'ALL_PROXY']:
                os.environ.pop(key)
        os.environ.update(service_env)
        import uvicorn
        uvicorn.run(f'{args.service}_ms.main:app', host='127.0.0.1', port={'gateway': 3160, 'user': 3161, 'meeting': 3167}[args.service], log_level='warning')
    else:
        asyncio.run(seed())
