"""Delete only platform objects proven to belong to this native acceptance run."""
import asyncio
import json
import os
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'server'))
OUT = Path(os.environ['MEETING_UI_NATIVE_OUTPUT']).resolve()


async def main():
    for key in list(os.environ):
        if key.upper() in {'HTTP_PROXY', 'HTTPS_PROXY', 'ALL_PROXY'}:
            os.environ.pop(key)
    from dotenv import dotenv_values
    for key, value in dotenv_values(os.environ.get('OPENMEETING_RTC_TEST_ENV') or ROOT / 'server' / '.env').items():
        if key.startswith('OPENMEETING_IM_') and value is not None:
            os.environ[key] = value
    os.environ['OPENMEETING_ENV'] = 'dev'
    import asyncpg
    from user_ms.infrastructure.im_client import get_client, aclose_client
    users = [a['id'] for a in json.loads((OUT / 'accounts.private.json').read_text(encoding='utf8'))]
    assert len(users) == 3 and all(user.startswith('ui-native-') for user in users)
    database = next(db for db in json.loads((OUT / 'databases.json').read_text())['databases'] if db.endswith('_meeting'))
    assert database.startswith('meeting_ui_') and database.replace('_', '').isalnum()
    conn = await asyncpg.connect(f'postgresql://openmeeting:openmeeting@127.0.0.1:55439/{database}')
    rooms = await conn.fetch('SELECT id,im_group_id FROM live_rooms WHERE host_user_id=ANY($1::varchar[])', users)
    await conn.close()
    client = await get_client()
    result = dict(groupsDeleted=0, usersDeleted=0, alreadyAbsent=0, errors=[])
    try:
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
                    result['alreadyAbsent'] += 1
                else:
                    result['errors'].append({'resource': 'owned group', 'error': type(exc).__name__})
        for user in users:
            try:
                await client.users.delete(user)
                result['usersDeleted'] += 1
            except Exception as exc:
                if getattr(exc, 'status_code', None) == 404 or getattr(exc, 'status', None) == 404:
                    result['alreadyAbsent'] += 1
                else:
                    result['errors'].append({'resource': 'owned user', 'error': type(exc).__name__})
    finally:
        await aclose_client()
    (OUT / 'platform-cleanup.json').write_text(json.dumps(result, indent=2), encoding='utf8')
    print(json.dumps(result))
    return not result['errors']


if __name__ == '__main__':
    raise SystemExit(0 if asyncio.run(main()) else 1)
