"""Read-only audit of this task's ended groups and released preview cache files."""
import asyncio
import json
import os
from pathlib import Path
import sys
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(os.environ.get('MEETING_CHAT_OUTPUT', str(ROOT / '.artifacts' / '会议聊天生命周期与界面'))) / 'native'
sys.path.insert(0, str(ROOT / 'server'))


async def main():
    import asyncpg
    from dotenv import dotenv_values
    for key in list(os.environ):
        if key.upper() in {'HTTP_PROXY', 'HTTPS_PROXY', 'ALL_PROXY'}:
            os.environ.pop(key)
    os.environ.update({k: v for k, v in dotenv_values(sys.argv[1]).items() if k.startswith('OPENMEETING_IM_') and v is not None})
    os.environ.update(OPENMEETING_ENV='dev', OPENMEETING_INTERNAL_SERVICE_TOKEN='isolated-native-ready',
                      OPENMEETING_EGRESS_PROXY_URL='http://127.0.0.1:3163')
    from user_ms.infrastructure.im_client import get_client, aclose_client
    accounts = json.loads((OUT / 'accounts.private.json').read_text(encoding='utf8'))
    users = [a['id'] for a in accounts]
    assert all(u.startswith('im-ready-') for u in users)
    conn = await asyncpg.connect('postgresql://openmeeting:openmeeting@127.0.0.1:55439/meeting_ready_meeting')
    rooms = await conn.fetch('SELECT id,status,im_group_id FROM live_rooms WHERE host_user_id=ANY($1::text[])', users)
    await conn.close()
    rows = []
    client = await get_client()
    try:
        groups = []
        for room in rooms:
            assert room['status'] == 'ended', room['id']
            if not room['im_group_id']:
                continue
            group = await client.groups.get(room['im_group_id'])
            assert (group.attributes or {}).get('openmeeting_room_id') == room['id']
            assert group.status == 'dismissed', group.status
            groups.append({'roomId': room['id'], 'groupId': group.group_id, 'status': group.status})
        assert len(groups) >= 4
        assert len({g['groupId'] for g in groups}) == len(groups)
        rows.append({'operation': '真实平台群生命周期', 'expected': '本次账号创建的结束房间均已解散，群互不复用', 'actual': groups, 'pass': True})
    except Exception as exc:
        rows.append({'operation': '真实平台群生命周期', 'expected': '已结束群全部 dismissed', 'actual': str(exc), 'pass': False})
    finally:
        await aclose_client()
    previews = []
    for file in [OUT / 'chat-results.json', *OUT.glob('chat-attempt-*.json')]:
        for row in json.loads(file.read_text(encoding='utf8')).get('steps', []):
            actual = row.get('actual')
            if isinstance(actual, dict) and 'drim-file.localhost' in actual.get('src', ''):
                previews.append(Path(unquote(urlsplit(actual['src']).path.lstrip('/'))))
    previews = list(dict.fromkeys(previews))
    remaining = [str(p) for p in previews if p.exists()]
    rows.append({'operation': '关闭视频预览释放原生缓存', 'expected': '已记录的实际播放缓存全部删除',
                 'actual': {'checked': len(previews), 'remaining': remaining}, 'pass': bool(previews) and not remaining})
    (OUT / 'audit-results.json').write_text(json.dumps(rows, ensure_ascii=False, indent=2), encoding='utf8')
    for row in rows:
        print(json.dumps(row, ensure_ascii=False), flush=True)
    if any(not r['pass'] for r in rows):
        raise SystemExit(1)


asyncio.run(main())
