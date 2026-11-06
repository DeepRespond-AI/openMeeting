"""Transactional business events -> durable IM delivery, never a second message store."""
import asyncio
import logging
from datetime import timedelta

from sqlalchemy import delete, select
from sqlalchemy.dialects.postgresql import insert

from meeting_ms.db.models import ImNotification, ScheduledMeeting, RoomParticipant, RoomRecordingSpeaker
from meeting_ms.db.session import session_factory
from meeting_ms.infrastructure.internal_client import client_for
from meeting_ms.utils import iso, utcnow

logger = logging.getLogger(__name__)


async def enqueue(session, event_id, recipient, body):
    await session.execute(insert(ImNotification).values(id=event_id, recipient=recipient,
        body={"kind": "openmeeting.meeting", "version": 1, **body}).on_conflict_do_nothing(index_elements=["id"]))


async def scheduled_event(session, row, event):
    await enqueue(session, f"scheduled:{row.id}:{event}:{row.updated_at.isoformat()}", row.user_id,
        {"event": event, "title": row.title, "code": row.code, "scheduledId": row.id,
         "startAt": iso(row.start_at)})


async def room_changed(session, room, reason):
    recipients = (await session.execute(select(RoomParticipant.user_id).where(
        RoomParticipant.room_id == room.id, RoomParticipant.state == "joined",
        RoomParticipant.user_id.is_not(None)))).scalars()
    for recipient in set(recipients):
        await enqueue(session, f"state:{room.id}:{room.updated_at.isoformat()}:{recipient}", recipient,
            {"event": "room_state", "roomId": room.id, "versionAt": iso(room.updated_at), "reason": reason})


async def meeting_event(session, room_id, meeting, event, event_key):
    """One shared record; durable attendance includes members who already left."""
    recipients = set((await session.execute(select(RoomRecordingSpeaker.user_id).where(
        RoomRecordingSpeaker.room_id == room_id, RoomRecordingSpeaker.user_id.is_not(None)))).scalars())
    recipients.add(meeting.user_id)
    for recipient in recipients:
        await enqueue(session, f'{event_key}:{recipient}', recipient,
            {'event': event, 'title': meeting.title, 'meetingId': meeting.id, 'roomId': room_id})


async def tick():
    now = utcnow()
    async with session_factory()() as session:
        await session.execute(delete(ImNotification).where(ImNotification.delivered_at < now - timedelta(days=7)))
        rows = (await session.execute(select(ScheduledMeeting).where(
            ScheduledMeeting.remind.is_(True), ScheduledMeeting.cancelled.is_(False),
            ScheduledMeeting.meeting_id.is_(None), ScheduledMeeting.start_at > now,
            ScheduledMeeting.start_at <= now + timedelta(minutes=10)))).scalars()
        for row in rows:
            await enqueue(session, f"reminder:{row.id}:{row.start_at.isoformat()}", row.user_id,
                {"event": "reminder", "title": row.title, "code": row.code,
                 "scheduledId": row.id, "startAt": iso(row.start_at)})
        await session.commit()
    # Row locks avoid concurrent workers delivering the same event at once. Lost
    # responses are safe: the IM server deduplicates the stable client_msg_id.
    for _ in range(50):
        async with session_factory()() as session:
            row = (await session.execute(select(ImNotification).where(
                ImNotification.delivered_at.is_(None), ImNotification.next_attempt_at <= utcnow()
            ).order_by(ImNotification.created_at).limit(1).with_for_update(skip_locked=True))).scalar_one_or_none()
            if row is None:
                break
            # Superseded/cancelled reminders must not appear after a long outage.
            if row.body.get("event") == "reminder":
                scheduled = await session.get(ScheduledMeeting, row.body["scheduledId"])
                if (not scheduled or scheduled.cancelled or not scheduled.remind or scheduled.meeting_id
                    or scheduled.start_at <= utcnow() or iso(scheduled.start_at) != row.body["startAt"]):
                    await session.delete(row)
                    await session.commit()
                    continue
            row.attempts += 1
            try:
                async with client_for("user", timeout=15) as client:
                    response = await client.post("/im/meeting-chat/notify", json={
                        "event_id": row.id, "recipient": row.recipient, "body": row.body})
                response.raise_for_status()
                row.delivered_at = utcnow()
                # IM now owns the content. Retain only delivery metadata.
                row.body = {}
            except Exception as exc:
                logger.warning("IM notification pending: id=%s type=%s", row.id, type(exc).__name__)
                row.next_attempt_at = utcnow() + timedelta(seconds=min(300, 15 * 2 ** min(row.attempts, 5)))
            await session.commit()


async def run():
    while True:
        try:
            await tick()
        except Exception as exc:
            logger.warning("IM notification worker retry: type=%s", type(exc).__name__)
        await asyncio.sleep(15)
