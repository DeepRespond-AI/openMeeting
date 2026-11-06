from __future__ import annotations

from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Response
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from meeting_ms.api.deps import accessible_meeting, owned_meeting
from meeting_ms.api.v1.meetings import transcript_order
from meeting_ms.api.deps import AuthContext, require_client
from meeting_ms.db.models import Transcript
from meeting_ms.db.session import get_session
from meeting_ms.llm.providers import get_active_provider
from meeting_ms.summary import service as summary_service
from meeting_ms.summary.processor import SummaryError
from meeting_ms.summary.templates import enabled_templates

router = APIRouter(tags=["summary"])


class SummaryRequest(BaseModel):
    # The server picks the template itself and its prompt alone shapes the report (language included);
    # a client-sent `template_id` or `language` is ignored.
    custom_prompt: str | None = None
    text: str | None = None


class SummarySave(BaseModel):
    summary: Any


@router.post("/meetings/{meeting_id}/summary", status_code=202)
async def generate_summary(
    meeting_id: str,
    body: SummaryRequest,
    ctx: AuthContext = Depends(require_client),
    session: AsyncSession = Depends(get_session),
) -> dict:
    meeting = await owned_meeting(session, ctx, meeting_id)
    provider = await get_active_provider()
    if provider is None:
        raise HTTPException(503, "服务器尚未配置可用的大模型")
    if not await enabled_templates():
        raise HTTPException(503, "服务器尚未配置可用的总结模板")
    text = body.text
    if text is None:
        rows = (
            await session.execute(
                select(Transcript).where(Transcript.meeting_id == meeting_id).order_by(*transcript_order())
            )
        ).scalars().all()
        text = summary_service.format_transcript_text(list(rows))
    if not text.strip():
        raise HTTPException(400, "没有可用于总结的转写内容")
    process_id = await summary_service.start_summary(meeting, provider, text, body.custom_prompt)
    return {"message": "Summary generation started", "process_id": process_id}


@router.get("/meetings/{meeting_id}/summary")
async def get_summary(
    meeting_id: str, ctx: AuthContext = Depends(require_client), session: AsyncSession = Depends(get_session)
) -> dict:
    meeting = await accessible_meeting(session, ctx, meeting_id)
    return await summary_service.get_summary_response(session, meeting)


@router.delete("/meetings/{meeting_id}/summary", status_code=204)
async def cancel_summary(
    meeting_id: str, ctx: AuthContext = Depends(require_client), session: AsyncSession = Depends(get_session)
) -> Response:
    await owned_meeting(session, ctx, meeting_id)
    summary_service.cancel_summary(meeting_id)
    return Response(status_code=204)


@router.put("/meetings/{meeting_id}/summary", status_code=204)
async def save_summary(
    meeting_id: str,
    body: SummarySave,
    ctx: AuthContext = Depends(require_client),
    session: AsyncSession = Depends(get_session),
) -> Response:
    meeting = await owned_meeting(session, ctx, meeting_id)
    try:
        await summary_service.save_manual_summary(session, meeting, body.summary)
    except SummaryError as exc:
        raise HTTPException(400, "总结内容为空或包含模型推理标记，未保存") from exc
    except LookupError as exc:
        raise HTTPException(404, "该会议还没有总结记录") from exc
    return Response(status_code=204)
