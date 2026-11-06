from __future__ import annotations

import logging

from fastapi import APIRouter, Depends, Query, Response
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession
from service_net.field_limits import MeetingCreateTitle, MeetingTitle as MeetingTitleText

from meeting_ms.api.deps import accessible_meeting, owned_meeting, visible_meeting
from meeting_ms.api.deps import AuthContext, require_client
from meeting_ms.db.models import Meeting, MeetingNotes, Transcript
from meeting_ms.db.session import get_session
from meeting_ms.storage.audio import delete_meeting_files
from meeting_ms.summary import service as summary_service
from meeting_ms.utils import iso, iso_ms, new_meeting_id, utcnow

logger = logging.getLogger(__name__)
router = APIRouter(tags=["meetings"])


# ----------------------------------------------------------------- serializers


def meeting_metadata(m: Meeting, user_id: str | None = None) -> dict:
    return {
        "id": m.id,
        "title": m.title,
        "created_at": iso(m.created_at),
        "updated_at": iso(m.updated_at),
        "folder_path": None,
        "has_audio": bool(m.audio_path),
        "audio_duration": m.duration if m.audio_path else None,
        "can_manage": user_id is None or m.user_id == user_id,
    }


def transcript_dict(t: Transcript) -> dict:
    d: dict = {"id": t.id, "text": t.transcript, "timestamp": t.timestamp}
    for key in ("audio_start_time", "audio_end_time", "duration", "speaker", "confidence"):
        value = getattr(t, key)
        if value is not None:
            d[key] = value
    return d


def transcript_order():
    return (Transcript.audio_start_time.asc().nulls_first(), Transcript.timestamp.asc())


async def meeting_details(session: AsyncSession, m: Meeting) -> dict:
    rows = (
        await session.execute(select(Transcript).where(Transcript.meeting_id == m.id).order_by(*transcript_order()))
    ).scalars().all()
    return {
        "id": m.id,
        "title": m.title,
        "created_at": iso(m.created_at),
        "updated_at": iso(m.updated_at),
        "transcripts": [transcript_dict(t) for t in rows],
    }


# ----------------------------------------------------------------- meetings


class MeetingCreate(BaseModel):
    title: MeetingCreateTitle


class MeetingTitle(BaseModel):
    title: MeetingTitleText


@router.post("/meetings", status_code=201)
async def create_meeting(
    body: MeetingCreate, ctx: AuthContext = Depends(require_client), session: AsyncSession = Depends(get_session)
) -> dict:
    now = utcnow()
    meeting = Meeting(id=new_meeting_id(), user_id=ctx.user_id, title=body.title or "新会议", created_at=now, updated_at=now)
    session.add(meeting)
    await session.commit()
    return meeting_metadata(meeting)


@router.get("/meetings")
async def list_meetings(
    ctx: AuthContext = Depends(require_client), session: AsyncSession = Depends(get_session)
) -> list[dict]:
    rows = (
        await session.execute(
            select(Meeting.id, Meeting.title, Meeting.created_at, Meeting.updated_at, Meeting.user_id)
            .where(visible_meeting(ctx.user_id))
            .order_by(Meeting.created_at.desc())
        )
    ).all()
    return [
        {"id": r.id, "title": r.title, "created_at": iso(r.created_at), "updated_at": iso(r.updated_at), "can_manage": r.user_id == ctx.user_id} for r in rows
    ]


@router.get("/meetings/{meeting_id}")
async def get_meeting(
    meeting_id: str, ctx: AuthContext = Depends(require_client), session: AsyncSession = Depends(get_session)
) -> dict:
    return await meeting_details(session, await accessible_meeting(session, ctx, meeting_id))


@router.get("/meetings/{meeting_id}/metadata")
async def get_meeting_metadata(
    meeting_id: str, ctx: AuthContext = Depends(require_client), session: AsyncSession = Depends(get_session)
) -> dict:
    return meeting_metadata(await accessible_meeting(session, ctx, meeting_id), ctx.user_id)


@router.patch("/meetings/{meeting_id}")
async def rename_meeting(
    meeting_id: str,
    body: MeetingTitle,
    ctx: AuthContext = Depends(require_client),
    session: AsyncSession = Depends(get_session),
) -> dict:
    meeting = await owned_meeting(session, ctx, meeting_id)
    meeting.title = body.title
    meeting.updated_at = utcnow()
    await session.commit()
    return meeting_metadata(meeting)


@router.delete("/meetings/{meeting_id}", status_code=204)
async def delete_meeting(
    meeting_id: str, ctx: AuthContext = Depends(require_client), session: AsyncSession = Depends(get_session)
) -> Response:
    meeting = await owned_meeting(session, ctx, meeting_id)
    summary_service.cancel_summary(meeting_id)
    await session.delete(meeting)
    await session.commit()
    await delete_meeting_files(meeting)
    return Response(status_code=204)


# ----------------------------------------------------------------- transcripts


@router.get("/meetings/{meeting_id}/transcripts")
async def list_transcripts(
    meeting_id: str,
    limit: int = Query(100, ge=1, le=10000),
    offset: int = Query(0, ge=0),
    ctx: AuthContext = Depends(require_client),
    session: AsyncSession = Depends(get_session),
) -> dict:
    await accessible_meeting(session, ctx, meeting_id)
    total = (
        await session.execute(select(func.count(Transcript.id)).where(Transcript.meeting_id == meeting_id))
    ).scalar_one()
    rows = (
        await session.execute(
            select(Transcript)
            .where(Transcript.meeting_id == meeting_id)
            .order_by(*transcript_order())
            .limit(limit)
            .offset(offset)
        )
    ).scalars().all()
    return {
        "transcripts": [transcript_dict(t) for t in rows],
        "total_count": total,
        "has_more": offset + len(rows) < total,
    }


class TranscriptSegmentIn(BaseModel):
    id: str
    text: str
    timestamp: str | None = None
    audio_start_time: float | None = None
    audio_end_time: float | None = None
    duration: float | None = None


class TranscriptBulkIn(BaseModel):
    transcripts: list[TranscriptSegmentIn]


@router.post("/meetings/{meeting_id}/transcripts")
async def bulk_insert_transcripts(
    meeting_id: str,
    body: TranscriptBulkIn,
    ctx: AuthContext = Depends(require_client),
    session: AsyncSession = Depends(get_session),
) -> dict:
    meeting = await owned_meeting(session, ctx, meeting_id)
    if not body.transcripts:
        return {"inserted": 0}
    now = iso_ms(utcnow())
    values = [
        {
            "id": t.id,
            "meeting_id": meeting_id,
            "transcript": t.text,
            "timestamp": t.timestamp or now,
            "audio_start_time": t.audio_start_time,
            "audio_end_time": t.audio_end_time,
            "duration": t.duration
            if t.duration is not None
            else (t.audio_end_time - t.audio_start_time if t.audio_end_time is not None and t.audio_start_time is not None else None),
        }
        for t in body.transcripts
    ]
    result = await session.execute(
        insert(Transcript).values(values).on_conflict_do_nothing(index_elements=[Transcript.id]).returning(Transcript.id)
    )
    inserted = len(result.scalars().all())
    meeting.updated_at = utcnow()
    await session.commit()
    return {"inserted": inserted}


def _match_context(transcript: str, query: str) -> str:
    idx = transcript.lower().find(query.lower())
    if idx == -1:
        return transcript[:200]
    start = max(0, idx - 100)
    end = min(len(transcript), idx + len(query) + 100)
    return ("..." if start > 0 else "") + transcript[start:end] + ("..." if end < len(transcript) else "")


@router.get("/transcripts/search")
async def search_transcripts(
    q: str = "", ctx: AuthContext = Depends(require_client), session: AsyncSession = Depends(get_session)
) -> list[dict]:
    if not q.strip():
        return []
    pattern = "%" + q.lower().replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_") + "%"
    rows = (
        await session.execute(
            select(Meeting.id, Meeting.title, Transcript.transcript, Transcript.timestamp)
            .join(Transcript, Transcript.meeting_id == Meeting.id)
            .where(visible_meeting(ctx.user_id), func.lower(Transcript.transcript).like(pattern, escape="\\"))
            .order_by(Meeting.created_at.desc(), *transcript_order())
            .limit(500)
        )
    ).all()
    return [
        {"id": r.id, "title": r.title, "matchContext": _match_context(r.transcript, q), "timestamp": r.timestamp}
        for r in rows
    ]


# ----------------------------------------------------------------- notes


class NotesIn(BaseModel):
    notes_markdown: str | None = None
    notes_json: str | None = None


def _notes_dict(meeting_id: str, notes: MeetingNotes | None) -> dict:
    return {
        "meeting_id": meeting_id,
        "notes_markdown": notes.notes_markdown if notes else None,
        "notes_json": notes.notes_json if notes else None,
        "updated_at": iso(notes.updated_at) if notes else None,
    }


@router.get("/meetings/{meeting_id}/notes")
async def get_notes(
    meeting_id: str, ctx: AuthContext = Depends(require_client), session: AsyncSession = Depends(get_session)
) -> dict:
    await accessible_meeting(session, ctx, meeting_id)
    return _notes_dict(meeting_id, await session.get(MeetingNotes, meeting_id))


@router.put("/meetings/{meeting_id}/notes")
async def save_notes(
    meeting_id: str,
    body: NotesIn,
    ctx: AuthContext = Depends(require_client),
    session: AsyncSession = Depends(get_session),
) -> dict:
    await owned_meeting(session, ctx, meeting_id)
    now = utcnow()
    stmt = insert(MeetingNotes).values(
        meeting_id=meeting_id, notes_markdown=body.notes_markdown, notes_json=body.notes_json,
        created_at=now, updated_at=now,
    )
    stmt = stmt.on_conflict_do_update(
        index_elements=[MeetingNotes.meeting_id],
        set_={"notes_markdown": body.notes_markdown, "notes_json": body.notes_json, "updated_at": now},
    )
    await session.execute(stmt)
    await session.commit()
    return _notes_dict(meeting_id, await session.get(MeetingNotes, meeting_id, populate_existing=True))


# ----------------------------------------------------------------- summary language


class SummaryLanguageIn(BaseModel):
    language: str | None = None
    detected_language: str | None = None


def _lang_dict(m: Meeting) -> dict:
    return {"language": m.summary_language, "detected_language": m.detected_summary_language}


def _clean_lang(value: str | None) -> str | None:
    return (value or "").strip() or None


@router.get("/meetings/{meeting_id}/summary-language")
async def get_summary_language(
    meeting_id: str, ctx: AuthContext = Depends(require_client), session: AsyncSession = Depends(get_session)
) -> dict:
    return _lang_dict(await accessible_meeting(session, ctx, meeting_id))


@router.put("/meetings/{meeting_id}/summary-language")
async def save_summary_language(
    meeting_id: str,
    body: SummaryLanguageIn,
    ctx: AuthContext = Depends(require_client),
    session: AsyncSession = Depends(get_session),
) -> dict:
    meeting = await owned_meeting(session, ctx, meeting_id)
    if "language" in body.model_fields_set:
        meeting.summary_language = _clean_lang(body.language)
    if "detected_language" in body.model_fields_set:
        meeting.detected_summary_language = _clean_lang(body.detected_language)
    await session.commit()
    return _lang_dict(meeting)
