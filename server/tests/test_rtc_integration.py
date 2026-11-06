"""SDK contract and internal authorization, without external RTC credentials or shared DB mutation."""
from types import SimpleNamespace
from unittest.mock import AsyncMock

import httpx
import pytest
from fastapi import Depends, FastAPI

from user_ms.api import internal_rtc
from user_ms.api.deps import require_internal
from user_ms.config import get_settings
from meeting_ms.infrastructure import rtc_client


@pytest.fixture
async def rtc(monkeypatch):
    service=SimpleNamespace(**{name:AsyncMock() for name in
        ["create","get","issue_tickets","revoke_tickets","remove_member","close","sessions"]})
    service.issue_tickets.return_value=SimpleNamespace(tickets=[SimpleNamespace(ticket="one-use-fixture",expires_at="2030-01-01T00:00:00Z")])
    monkeypatch.setattr(internal_rtc,"get_client",AsyncMock(return_value=SimpleNamespace(channels=service)))
    monkeypatch.setattr(internal_rtc,"issue_login_ticket",AsyncMock())
    monkeypatch.setattr(get_settings(),"internal_service_token","unit-service-token")
    app=FastAPI()
    app.include_router(internal_rtc.router,dependencies=[Depends(require_internal)])
    async with httpx.AsyncClient(transport=httpx.ASGITransport(app=app),base_url="http://unit") as client:
        yield client,service


async def test_rtc_internal_auth_and_sdk_parameters(rtc):
    client,service=rtc
    path="/internal/im/rtc/channels"
    body={"channel_id":"room-unit","name":"Meeting","max_participants":50}
    assert (await client.post(path,json=body)).status_code==401
    headers={"X-Internal-Token":"unit-service-token"}
    assert (await client.post(path,json=body,headers=headers)).status_code==200
    service.create.assert_awaited_once_with("room-unit",name="Meeting",media="video",access_mode="ticket",default_role="publisher",max_participants=50)
    response=await client.post(path+"/room-unit/tickets",json={"username":"user-unit"},headers=headers)
    assert response.json()=={"ticket":"one-use-fixture","expires_at":"2030-01-01T00:00:00Z"}
    service.issue_tickets.assert_awaited_once_with("room-unit",users=[{"username":"user-unit","role":"publisher"}],ttl_seconds=120)


async def test_rtc_close_and_removal_revoke_consumed_and_unconsumed_access(rtc):
    client,service=rtc
    headers={"X-Internal-Token":"unit-service-token"}
    body={"username":"user-unit","operation_id":"remove-1","reason":"removed"}
    assert (await client.post("/internal/im/rtc/channels/room-unit/remove",json=body,headers=headers)).status_code==200
    service.revoke_tickets.assert_awaited_once_with("room-unit",usernames=["user-unit"],operation_id="remove-1",reason="removed")
    service.remove_member.assert_awaited_once_with("room-unit","user-unit",operation_id="remove-1",reason="removed")
    assert (await client.post("/internal/im/rtc/channels/room-unit/close",json={"reason":"ended"},headers=headers)).status_code==200
    service.close.assert_awaited_once_with("room-unit",reason="ended")


async def test_rtc_outage_never_delivers_a_ticket(rtc):
    client,service=rtc
    service.issue_tickets.side_effect=RuntimeError("private-token-must-not-be-exposed")
    response=await client.post("/internal/im/rtc/channels/room-unit/tickets",json={"username":"user-unit"},headers={"X-Internal-Token":"unit-service-token"})
    assert response.status_code==503
    assert "private-token" not in response.text


async def test_media_removal_attempted_even_if_ticket_revocation_fails(rtc):
    client,service=rtc
    service.revoke_tickets.side_effect=RuntimeError("unavailable")
    response=await client.post("/internal/im/rtc/channels/room-unit/remove",json={"username":"user-unit","operation_id":"remove-2","reason":"removed"},headers={"X-Internal-Token":"unit-service-token"})
    assert response.status_code==503
    service.remove_member.assert_awaited_once()


async def test_room_media_fallback_and_ticket_handoff(monkeypatch):
    room=SimpleNamespace(id="room-unit",title="Meeting")
    request=AsyncMock(side_effect=[{"ok":True},{"ticket":"fixture","expires_at":"2030-01-01T00:00:00Z"}])
    monkeypatch.setattr(rtc_client,"request",request)
    assert await rtc_client.media_for(room,"user-unit")=={"transport":"dr-rtc","channelId":"room-unit","ticket":"fixture","expiresAt":"2030-01-01T00:00:00Z"}
    request.side_effect=None;request.return_value=None
    assert (await rtc_client.media_for(room,"user-unit"))["unavailableReason"]=="rtc_unavailable"


async def test_renamed_business_room_reuses_existing_open_channel(rtc):
    client,service=rtc
    conflict=RuntimeError("already exists");conflict.code="already_exists"
    service.create.side_effect=conflict
    service.get.return_value=SimpleNamespace(channel=SimpleNamespace(status="open",media="video",access_mode="ticket",default_role="publisher",max_participants=50))
    response=await client.post("/internal/im/rtc/channels",json={"channel_id":"room-unit","name":"Renamed","max_participants":50},headers={"X-Internal-Token":"unit-service-token"})
    assert response.status_code==200


async def test_ticket_issued_during_removal_is_revoked(monkeypatch):
    from meeting_ms.api.v1.rooms import authorized_media
    monkeypatch.setattr(rtc_client,"media_for",AsyncMock(return_value={"transport":"dr-rtc","ticket":"private"}))
    remove=AsyncMock();monkeypatch.setattr(rtc_client,"remove",remove)
    session=SimpleNamespace(execute=AsyncMock(return_value=SimpleNamespace(scalar_one_or_none=lambda:None)))
    result=await authorized_media(session,SimpleNamespace(id="room-unit"),"user-unit")
    assert result["transport"]=="webrtc"
    remove.assert_awaited_once_with("room-unit","user-unit")


async def test_im_ticket_bootstrap_contract_and_legacy_get(monkeypatch):
    from user_ms.api.v1 import im
    settings=get_settings()
    monkeypatch.setattr(settings,"im_base_url","https://im.example/")
    monkeypatch.setattr(settings,"im_org_name","org")
    monkeypatch.setattr(settings,"im_app_name","app")
    monkeypatch.setattr(im.im_client,"issue_login_ticket",AsyncMock(return_value={"ticket":"fixture","expires_in":300,"user_created":False}))
    app=FastAPI();app.include_router(im.router,prefix="/api/v1")
    async with httpx.AsyncClient(transport=httpx.ASGITransport(app=app),base_url="http://unit") as client:
        for method in ("POST","GET"):
            response=await client.request(method,"/api/v1/im/ticket",headers={"X-User-ID":"user-unit"})
            assert response.status_code==200
            assert response.json()["app_key"]=="org#app"
            assert response.json()["api_url"]=="https://im.example"
            assert response.json()["expires_in_sec"]==300
            assert response.headers["cache-control"]=="private, no-store"


RECOVER = "/internal/im/rtc/channels/room-unit/recover"
RECOVER_HEADERS = {"X-Internal-Token":"unit-service-token"}
RECOVER_BODY = {"username":"user-unit", "session_id":"stale-session"}


def channel_session(session_id="stale-session", username="user-unit", status="leaving"):
    return SimpleNamespace(session_id=session_id, username=username, status=status)


def sessions_page(*items, cursor=None):
    return SimpleNamespace(items=list(items), next_cursor=cursor)


async def test_recover_removes_only_verified_leaving_user_and_checks_release(rtc):
    client, service = rtc
    service.sessions.side_effect = [sessions_page(channel_session(), channel_session("other", "other", "joined")),
                                    sessions_page(channel_session(status="left"))]
    assert (await client.post(RECOVER, json=RECOVER_BODY)).status_code == 401
    response = await client.post(RECOVER, json=RECOVER_BODY, headers=RECOVER_HEADERS)
    assert response.json() == {"released": True}
    args = service.remove_member.await_args
    assert args.args == ("room-unit", "user-unit")
    assert len(args.kwargs["operation_id"]) == 32
    service.close.assert_not_awaited()
    service.revoke_tickets.assert_not_awaited()
    service.issue_tickets.assert_not_awaited()


@pytest.mark.parametrize("items", [
    [channel_session(status="joined")], [channel_session(status="joining")],
    [channel_session(username="another-user")],
    [channel_session(), channel_session("replacement", status="joined")],
    [channel_session(), channel_session("replacement", status="leaving")],
])
async def test_recover_rejects_healthy_changed_and_foreign_sessions(rtc, items):
    client, service = rtc
    service.sessions.return_value = sessions_page(*items)
    response = await client.post(RECOVER, json=RECOVER_BODY, headers=RECOVER_HEADERS)
    assert response.status_code == 409
    service.remove_member.assert_not_awaited()


async def test_recover_checks_later_pages_for_healthy_replacement(rtc):
    client, service = rtc
    service.sessions.side_effect = [sessions_page(channel_session(), cursor="page-2"),
                                    sessions_page(channel_session("healthy", status="joined"))]
    assert (await client.post(RECOVER, json=RECOVER_BODY, headers=RECOVER_HEADERS)).status_code == 409
    assert service.sessions.await_args.kwargs["cursor"] == "page-2"
    service.remove_member.assert_not_awaited()


async def test_recover_pending_release_reuses_operation_id_without_claiming_success(rtc):
    client, service = rtc
    service.sessions.return_value = sessions_page(channel_session())
    for _ in range(2):
        assert (await client.post(RECOVER, json=RECOVER_BODY, headers=RECOVER_HEADERS)).json() == {"released":False}
    calls = service.remove_member.await_args_list
    assert calls[0].kwargs["operation_id"] == calls[1].kwargs["operation_id"]


@pytest.mark.parametrize("items", [[], [channel_session(status="left")]])
async def test_recover_already_released_is_idempotent(rtc, items):
    client, service = rtc
    service.sessions.return_value = sessions_page(*items)
    assert (await client.post(RECOVER, json=RECOVER_BODY, headers=RECOVER_HEADERS)).json() == {"released":True}
    service.remove_member.assert_not_awaited()


async def test_platform_recovery_error_is_not_a_success_or_ticket(rtc):
    client, service = rtc
    service.sessions.return_value = sessions_page(channel_session())
    service.remove_member.side_effect = RuntimeError("private-platform-token")
    response = await client.post(RECOVER, json=RECOVER_BODY, headers=RECOVER_HEADERS)
    assert response.status_code == 503 and "private-platform-token" not in response.text
    service.issue_tickets.assert_not_awaited()


async def test_recover_rejects_a_replacement_observed_after_removal(rtc):
    client, service = rtc
    service.sessions.side_effect = [sessions_page(channel_session()),
                                    sessions_page(channel_session("new", status="joined"))]
    assert (await client.post(RECOVER, json=RECOVER_BODY, headers=RECOVER_HEADERS)).status_code == 409
    service.remove_member.assert_awaited_once()
    service.issue_tickets.assert_not_awaited()


async def test_recovery_pagination_loop_fails_closed(rtc):
    client, service = rtc
    service.sessions.return_value = sessions_page(channel_session(), cursor="repeated")
    assert (await client.post(RECOVER, json=RECOVER_BODY, headers=RECOVER_HEADERS)).status_code == 503
    service.remove_member.assert_not_awaited()


async def test_recover_bridge_preserves_conflict_and_rejects_invalid_success(monkeypatch):
    from contextlib import asynccontextmanager
    responses = [httpx.Response(409), httpx.Response(200,json={"released":False}),
                 httpx.Response(200,json={"ok":True})]
    post = AsyncMock(side_effect=responses)
    @asynccontextmanager
    async def client_for(*args, **kwargs):
        yield SimpleNamespace(post=post)
    monkeypatch.setattr(rtc_client, "client_for", client_for)
    from fastapi import HTTPException
    with pytest.raises(HTTPException) as conflict:
        await rtc_client.recover("room-unit", "user-unit", "stale-session")
    assert conflict.value.status_code == 409
    assert await rtc_client.recover("room-unit", "user-unit", "stale-session") == {"released":False}
    with pytest.raises(HTTPException) as invalid:
        await rtc_client.recover("room-unit", "user-unit", "stale-session")
    assert invalid.value.status_code == 503
    assert post.await_args.kwargs["json"] == {"username":"user-unit","session_id":"stale-session"}
