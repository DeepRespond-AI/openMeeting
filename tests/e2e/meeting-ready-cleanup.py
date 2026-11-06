"""Remove only resources bound to this task's isolated DB and account ledger."""
import asyncio
import json
import os
from pathlib import Path
import sys
import re
from urllib.parse import urlsplit
from datetime import datetime, timezone

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(os.environ.get('MEETING_READY_OUTPUT', str(ROOT / '.artifacts' / 'meeting-ready-im-sync'))).resolve()
sys.path.insert(0, str(ROOT / 'server'))


async def main():
    for key in list(os.environ):
        if key.upper() in {'HTTP_PROXY', 'HTTPS_PROXY', 'ALL_PROXY'}:
            os.environ.pop(key)
    from dotenv import dotenv_values
    import asyncpg
    for key, value in dotenv_values(sys.argv[1]).items():
        if key.startswith('OPENMEETING_IM_') and value is not None:
            os.environ[key] = value
    os.environ['OPENMEETING_ENV'] = 'dev'
    from user_ms.infrastructure.im_client import get_client, aclose_client
    accounts = json.loads((OUT / 'accounts.private.json').read_text(encoding='utf8'))
    users = [a['id'] for a in accounts]
    assert len(users) == 3 and all(u.startswith('im-ready-') for u in users)
    previous_users = []
    previous_ledger = os.environ.get('MEETING_READY_PREVIOUS_ACCOUNTS')
    if previous_ledger:
        previous_accounts = json.loads(Path(previous_ledger).read_text(encoding='utf8'))
        previous_users = [a['id'] for a in previous_accounts]
        assert len(previous_users) == 3 and all(u.startswith('im-ready-') for u in previous_users)
    port = int(os.environ.get('MEETING_READY_PG_PORT', '55439'))
    conn = await asyncpg.connect(f'postgresql://openmeeting:openmeeting@127.0.0.1:{port}/meeting_ready_meeting')
    rooms = await conn.fetch('SELECT id,im_group_id FROM live_rooms WHERE host_user_id=ANY($1::varchar[])', users)
    if previous_users:
        started = datetime.fromtimestamp(json.loads((OUT/'budget.json').read_text())['firstStartedAt']/1000, timezone.utc)
        rooms += await conn.fetch('SELECT id,im_group_id FROM live_rooms WHERE host_user_id=ANY($1::varchar[]) AND created_at >= $2', previous_users, started)
    await conn.close()
    client = await get_client()
    result = {'groupsDeleted': 0, 'usersDeleted': 0, 'avatarFilesDeleted': 0, 'alreadyAbsent': [], 'errors': []}
    try:
        # Optional avatar ledger from the avatar settings acceptance. Never
        # infer ownership from the URL: verify the IM metadata before deleting.
        avatar_ledger = OUT / 'avatar-files.json'
        if avatar_ledger.exists():
            for url in dict.fromkeys(json.loads(avatar_ledger.read_text(encoding='utf8'))):
                try:
                    match = re.fullmatch(r'(\d+)_[^/]+\.[a-zA-Z0-9]+', urlsplit(url).path.rsplit('/', 1)[-1])
                    assert match, 'Unexpected avatar URL'
                    file_id = match.group(1)
                    info = await client.media.get_file(file_id)
                    assert info.owner in users and info.purpose == 'user_avatar', 'Not an owned test avatar'
                    await client.media.delete_file(file_id)
                    result['avatarFilesDeleted'] += 1
                except Exception as exc:
                    result['errors'].append({'resource': 'owned test avatar', 'error': type(exc).__name__})
        for room in rooms:
            if not room['im_group_id']:
                continue
            try:
                group = await client.groups.get(room['im_group_id'])
                assert (group.attributes or {}).get('openmeeting_room_id') == room['id']
                await client.groups.delete(room['im_group_id'])
                result['groupsDeleted'] += 1
            except Exception as exc:
                if getattr(exc, 'status_code', None) == 404 or getattr(exc, 'status', None) == 404:
                    result['alreadyAbsent'].append('owned test group')
                else:
                    result['errors'].append({'resource':'owned test group','error':type(exc).__name__})
        for user in dict.fromkeys(users+previous_users):
            try:
                await client.users.delete(user)
                result['usersDeleted'] += 1
            except Exception as exc:
                if getattr(exc, 'status_code', None) == 404 or getattr(exc, 'status', None) == 404:
                    result['alreadyAbsent'].append('owned test user')
                else:
                    result['errors'].append({'resource':'owned test user','error':type(exc).__name__})
    finally:
        await aclose_client()
    (OUT/'platform-cleanup.json').write_text(json.dumps(result, indent=2), encoding='utf8')
    print(json.dumps(result))
    return not result['errors']


if __name__ == '__main__':
    raise SystemExit(0 if asyncio.run(main()) else 1)
