"""Persisted business presence, independent of DeepRespond's media heartbeat."""
from __future__ import annotations

import asyncio
import logging
from datetime import timedelta

from sqlalchemy import and_, delete, or_, select

from meeting_ms.config import get_settings
from meeting_ms.db.models import LiveRoom, RoomConnectionLease, RoomParticipant
from meeting_ms.db.session import session_factory
from meeting_ms.infrastructure import rtc_client, im_chat
from meeting_ms.infrastructure.room_events import manager
from meeting_ms.utils import utcnow

logger = logging.getLogger(__name__)


async def touch(room_id: str, participant_id: str, connection_id: str, *, register: bool = False) -> bool:
    """Lock order matches expiry and room end. An old connection cannot recreate a deleted seat."""
    async with session_factory()() as session:
        room = await session.get(LiveRoom, room_id, with_for_update=True)
        member = await session.get(RoomParticipant, participant_id)
        if not room or room.status == "ended" or not member or member.room_id != room_id or member.state != "joined":
            return False
        lease = await session.get(RoomConnectionLease, connection_id)
        if lease is None:
            if not register:
                return False
            lease = RoomConnectionLease(id=connection_id, room_id=room_id, participant_id=participant_id)
            session.add(lease)
        now = utcnow()
        lease.last_seen_at = member.last_seen_at = now
        member.disconnected_at = None
        await session.commit()
        return True


async def disconnect(room_id: str, participant_id: str, connection_id: str) -> None:
    from meeting_ms.api.v1.rooms import broadcast_state

    async with session_factory()() as session:
        room = await session.get(LiveRoom, room_id, with_for_update=True)
        removed = await session.scalar(delete(RoomConnectionLease).where(
            RoomConnectionLease.id == connection_id,
            RoomConnectionLease.room_id == room_id,
            RoomConnectionLease.participant_id == participant_id,
        ).returning(RoomConnectionLease.id))
        member = await session.get(RoomParticipant, participant_id)
        # Only a fresh connection can keep publishing. Do not disturb a new
        # connection when the delayed finally block of the old one runs.
        cutoff = utcnow() - timedelta(seconds=get_settings().room_heartbeat_timeout_seconds)
        active = (await session.execute(select(RoomConnectionLease.id).where(
            RoomConnectionLease.participant_id == participant_id,
            RoomConnectionLease.last_seen_at >= cutoff).limit(1))).first()
        if removed and room and room.status != "ended" and member and member.state == "joined" and not active:
            # Do not reset the deadline when another old socket finishes later.
            member.disconnected_at = member.disconnected_at or utcnow()
        changed = bool(room and room.status != "ended" and member and member.screen_sharing and not active)
        if changed:
            member.screen_sharing, member.screen_share_id = False, None
        await session.commit()
        if changed:
            await broadcast_state(session, room)


async def sweep_once() -> None:
    from meeting_ms.api.v1.rooms import broadcast_state, close_participant, finalize_room

    settings, now = get_settings(), utcnow()
    # Candidate selection is only a hint. Recheck activity after taking each
    # room's lock; reconnect/touch may have committed in the meantime.
    member_cutoff = now - timedelta(seconds=settings.room_member_grace_seconds)
    host_cutoff = now - timedelta(seconds=settings.room_host_grace_seconds)
    disconnect_cutoff = now - timedelta(seconds=settings.room_disconnect_grace_seconds)
    async with session_factory()() as session:
        room_ids = list((await session.execute(select(RoomParticipant.room_id).join(LiveRoom)
            .where(LiveRoom.status != "ended", or_(
                RoomParticipant.disconnected_at < disconnect_cutoff,
                and_(RoomParticipant.id == LiveRoom.host_participant_id, RoomParticipant.last_seen_at < host_cutoff),
                and_(RoomParticipant.id != LiveRoom.host_participant_id, RoomParticipant.last_seen_at < member_cutoff)))
            .distinct().order_by(RoomParticipant.room_id).limit(100))).scalars())
    for room_id in room_ids:
        expired = []
        try:
            async with session_factory()() as session:
                room = (await session.execute(select(LiveRoom).where(LiveRoom.id == room_id)
                    .with_for_update(skip_locked=True))).scalar_one_or_none()
                if not room or room.status == "ended":
                    continue
                members = list((await session.execute(select(RoomParticipant).where(
                    RoomParticipant.room_id == room_id))).scalars())
                host_expired = False
                for member in members:
                    grace = settings.room_host_grace_seconds if member.id == room.host_participant_id else settings.room_member_grace_seconds
                    disconnected = member.disconnected_at is not None and member.disconnected_at < disconnect_cutoff
                    if not disconnected and member.last_seen_at >= now - timedelta(seconds=grace):
                        continue
                    # A replacement socket can be live even if an older one
                    # closed late. Recheck persisted leases under the room lock.
                    active = await session.scalar(select(RoomConnectionLease.id).where(
                        RoomConnectionLease.participant_id == member.id,
                        RoomConnectionLease.last_seen_at >= now - timedelta(seconds=settings.room_heartbeat_timeout_seconds)
                    ).limit(1))
                    if active:
                        continue
                    if member.id == room.host_participant_id:
                        host_expired = True
                        break
                    expired.append(member)
                if host_expired:
                    logger.warning("room host timed out: room_id=%s", room_id)
                    await finalize_room(session, room)
                    continue
                for member in expired:
                    await im_chat.remove(room, member.user_id)
                    await session.delete(member)
                await session.commit()
                if expired:
                    await broadcast_state(session, room)
            for member in expired:
                logger.info("room seat expired: room_id=%s participant_id=%s", room_id, member.id)
                # Close business access first, then perform bounded platform cleanup.
                await close_participant(room_id, member.id)
                if member.user_id:
                    await rtc_client.remove(room_id, member.user_id)
        except Exception:
            logger.exception("room expiry failed: room_id=%s", room_id)


async def run() -> None:
    while True:
        await asyncio.sleep(get_settings().room_sweep_interval_seconds)
        try:
            await sweep_once()
        except Exception:
            logger.exception("room presence scan failed; retrying next interval")
