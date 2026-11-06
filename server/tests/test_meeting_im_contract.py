"""Authenticated SDK boundary. No live platform data or shared databases."""
from types import SimpleNamespace
from unittest.mock import AsyncMock, Mock

import httpx
import pytest
from fastapi import Depends, FastAPI

from user_ms.api import internal_meeting_chat as chat
from user_ms.api.deps import require_internal
from user_ms.config import get_settings


@pytest.fixture
async def platform(monkeypatch):
    groups = SimpleNamespace(**{name: AsyncMock() for name in (
        "create", "add_members", "remove_members", "update_member", "delete", "update")})
    groups.create.return_value = SimpleNamespace(group_id="1001")
    groups.add_members.return_value = SimpleNamespace(results=[SimpleNamespace(status="joined")])
    groups.remove_members.return_value = SimpleNamespace(results=[SimpleNamespace(status="removed")])
    existing = []

    async def iterate(**kwargs):
        assert kwargs == {"owner": chat.OWNER, "status": "active", "limit": 100}
        for group in existing:
            yield group

    groups.iter = iterate
    sdk = SimpleNamespace(groups=groups, users=SimpleNamespace(issue_login_ticket=AsyncMock()), messages=SimpleNamespace(send=AsyncMock()))
    sdk.with_options = Mock(return_value=sdk)
    monkeypatch.setattr(chat, "get_client", AsyncMock(return_value=sdk))
    monkeypatch.setattr(get_settings(), "internal_service_token", "im-contract-token")
    app = FastAPI()
    app.include_router(chat.router, dependencies=[Depends(require_internal)])
    async with httpx.AsyncClient(transport=httpx.ASGITransport(app), base_url="http://unit", trust_env=False) as client:
        yield client, sdk, existing


HEADERS = {"X-Internal-Token": "im-contract-token"}
BASE = "/internal/im/meeting-chat"
BODY = {"room_id": "room-contract", "name": "会议", "max_members": 51}


async def test_notification_id_is_stable_and_compatible_with_im(platform):
    client, sdk, _ = platform
    payload = {"event_id": "scheduled:" + "long-event:" * 10, "recipient": "alice", "body": {"kind": "openmeeting.meeting"}}
    assert (await client.post(BASE + "/notify", json=payload)).status_code == 401
    for _ in range(2):
        assert (await client.post(BASE + "/notify", json=payload, headers=HEADERS)).status_code == 200
    calls = sdk.messages.send.await_args_list
    assert calls[0].kwargs["client_msg_id"] == calls[1].kwargs["client_msg_id"]
    assert len(calls[0].kwargs["client_msg_id"]) == 32
    assert calls[0].kwargs["from_"] == "notice"


@pytest.mark.parametrize("event", ["scheduled_created", "scheduled_updated", "scheduled_cancelled",
    "reminder", "processing_completed", "processing_failed", "room_state"])
async def test_business_notices_deliver_silently_without_unread_or_push(platform, event):
    client, sdk, _ = platform
    body = {"kind": "openmeeting.meeting", "version": 1, "event": event, "roomId": "room-contract"}
    payload = {"event_id": "silent:" + event, "recipient": "alice", "body": body}
    assert (await client.post(BASE + "/notify", json=payload, headers=HEADERS)).status_code == 200
    sent = sdk.messages.send.await_args.kwargs
    assert sent["from_"] == "notice" and sent["to_user"] == "alice"
    assert sent["type"] == "custom" and sent["body"] == body
    assert sent["exclude_from_unread"] is True
    assert sent["push"] == {"disabled": True}


async def test_create_private_server_owned_group_and_auth(platform):
    client, sdk, _ = platform
    assert (await client.post(BASE, json=BODY)).status_code == 401
    response = await client.post(BASE, json=BODY, headers=HEADERS)
    assert response.json() == {"group_id": "1001"}
    sdk.groups.create.assert_awaited_once_with(chat.OWNER, type="private", name="会议", member_invite="disabled",
        max_members=51, attributes={"openmeeting_room_id": "room-contract"})
    sdk.with_options.assert_called_with(timeout=3, max_retries=0, max_rate_limited_retries=0)


async def test_response_loss_recovers_existing_business_binding(platform):
    client, sdk, existing = platform
    existing.extend([SimpleNamespace(group_id="unrelated", attributes=None),
                     SimpleNamespace(group_id="recovered", attributes={"openmeeting_room_id": "room-contract"})])
    assert (await client.post(BASE, json=BODY, headers=HEADERS)).json() == {"group_id": "recovered"}
    sdk.groups.create.assert_not_awaited()


async def test_join_and_remove_use_platform_membership(platform):
    client, sdk, _ = platform
    assert (await client.post(BASE + "/1001/members", json={"username": "alice", "name": "Alice"}, headers=HEADERS)).status_code == 200
    sdk.users.issue_login_ticket.assert_awaited_once_with("alice", auto_create=True)
    sdk.groups.add_members.assert_awaited_once_with("1001", ["alice"])
    sdk.groups.update_member.assert_awaited_once_with("1001", "alice", group_nickname="Alice")
    assert (await client.post(BASE + "/1001/remove", json={"username": "alice"}, headers=HEADERS)).status_code == 200
    sdk.groups.remove_members.assert_awaited_once_with("1001", ["alice"])


@pytest.mark.parametrize("results", [[], [SimpleNamespace(status=None)], [SimpleNamespace(status="rejected")]])
async def test_partial_platform_failure_never_reports_success(platform, results):
    client, sdk, _ = platform
    sdk.groups.add_members.return_value = SimpleNamespace(results=results)
    response = await client.post(BASE + "/1001/members", json={"username": "alice"}, headers=HEADERS)
    assert response.status_code == 503
    sdk.groups.update_member.assert_not_awaited()


async def test_end_dismisses_group_and_surfaces_platform_failure(platform):
    client, sdk, _ = platform
    assert (await client.post(BASE + "/1001/close", headers=HEADERS)).status_code == 200
    sdk.groups.delete.assert_awaited_once_with("1001", reason="Meeting ended")
    sdk.groups.delete.side_effect = RuntimeError("private-platform-secret")
    response = await client.post(BASE + "/1001/close", headers=HEADERS)
    assert response.status_code == 503 and "private-platform-secret" not in response.text
