from __future__ import annotations

import logging
import time

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from sqlalchemy import select, update
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from meeting_ms.api.deps import AuthContext, owned_meeting, require_client
from meeting_ms.db.models import Meeting, Transcript
from meeting_ms.db.session import get_session
from meeting_ms.infrastructure.stt_client import SttAudioError, SttClient, SttNotReady
from meeting_ms.monitor.metrics import log_request
from meeting_ms.stt.base import SAMPLE_RATE, normalize_language
from meeting_ms.utils import iso_ms, new_uuid, utcnow

logger = logging.getLogger(__name__)
router = APIRouter(tags=["transcription"])

MAX_SEGMENT_BYTES = 120 * SAMPLE_RATE * 2  # 2 minutes of PCM16


def _segment_result(t: Transcript, seq: int) -> dict:
    return {"id": t.id, "text": t.transcript, "confidence": t.confidence, "seq": seq}


async def _existing(session: AsyncSession, meeting_id: str, seq: int) -> Transcript | None:
    return (
        await session.execute(select(Transcript).where(Transcript.meeting_id == meeting_id, Transcript.seq == seq))
    ).scalar_one_or_none()


@router.post("/meetings/{meeting_id}/segments")
async def transcribe_segment(
    meeting_id: str,
    request: Request,
    seq: int = Query(..., ge=0),
    start: float = Query(..., ge=0),
    end: float = Query(..., ge=0),
    language: str | None = None,
    ctx: AuthContext = Depends(require_client),
    session: AsyncSession = Depends(get_session),
) -> dict:
    await owned_meeting(session, ctx, meeting_id)
    existing = await _existing(session, meeting_id, seq)
    if existing is not None:
        return _segment_result(existing, seq)

    body = await request.body()
    if len(body) > MAX_SEGMENT_BYTES:
        raise HTTPException(413, "语音段过长")
    audio_sec = len(body) / (SAMPLE_RATE * 2)

    t0 = time.monotonic()
    stt = SttClient()
    try:
        result = await stt.transcribe_pcm(body, normalize_language(language))
    except SttNotReady as exc:
        raise HTTPException(503, "语音识别模型未就绪") from exc
    except SttAudioError as exc:
        raise HTTPException(400, f"音频数据格式错误（{exc}；需要 16kHz 单声道 PCM16）") from exc
    except Exception as exc:
        logger.exception("Transcription failed for meeting %s seq %s", meeting_id, seq)
        log_request("transcribe", duration_ms=int((time.monotonic() - t0) * 1000), audio_sec=audio_sec,
                    status="error", session_id=ctx.session_id, user_id=ctx.user_id, error=str(exc))
        raise HTTPException(500, f"转写失败：{exc}") from exc
    log_request("transcribe", duration_ms=int((time.monotonic() - t0) * 1000), audio_sec=audio_sec,
                session_id=ctx.session_id, user_id=ctx.user_id)

    text = result.text.strip()
    if not text:
        return {"id": None, "text": "", "confidence": result.confidence, "seq": seq}

    end = max(end, start)
    inserted = (
        await session.execute(
            insert(Transcript)
            .values(
                id=new_uuid(), meeting_id=meeting_id, transcript=text, timestamp=iso_ms(utcnow()),
                audio_start_time=start, audio_end_time=end, duration=round(end - start, 3),
                confidence=result.confidence, seq=seq,
            )
            .on_conflict_do_nothing(constraint="uq_transcripts_meeting_seq")
            .returning(Transcript.id)
        )
    ).scalar_one_or_none()
    await session.execute(update(Meeting).where(Meeting.id == meeting_id).values(updated_at=utcnow()))
    await session.commit()
    if inserted is None:  # concurrent retry won the race
        existing = await _existing(session, meeting_id, seq)
        assert existing is not None
        return _segment_result(existing, seq)
    return {"id": inserted, "text": text, "confidence": result.confidence, "seq": seq}
