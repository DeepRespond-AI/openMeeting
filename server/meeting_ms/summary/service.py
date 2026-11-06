"""Summary orchestration and persistence (port of summary/service.rs + commands.rs)."""
from __future__ import annotations

import asyncio
import json
import logging
import time
from dataclasses import dataclass
from datetime import datetime, timedelta

from sqlalchemy import func, select, update
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from meeting_ms.db.models import LlmProvider, Meeting, SummaryProcess, Transcript, TranscriptChunk
from meeting_ms.db.session import session_factory
from meeting_ms.jobs import store as job_store
from meeting_ms.llm.providers import provider_config
from meeting_ms.monitor.metrics import log_request
from meeting_ms.summary import processor
from meeting_ms.summary.processor import SummaryError, clean_llm_markdown, contains_reasoning_marker
from meeting_ms.summary.templates import FORMAT_MARKDOWN, OUTPUT_FORMATS, enabled_templates
from meeting_ms.utils import rfc3339, rfc3339_nanos, utcnow

logger = logging.getLogger(__name__)

FORMAT_FIELD = "format"
# Which template the server picked; admin-only (stripped from client responses).
TEMPLATE_FIELD = "template"
# Written by the former English-first pipeline; older rows may still carry it, so it stays server-side only.
LEGACY_ENGLISH_CACHE_FIELD = "english_cache"
INTERNAL_FIELDS = (LEGACY_ENGLISH_CACHE_FIELD, TEMPLATE_FIELD)
CANCELLED_ERROR = "Generation was cancelled by user"


@dataclass
class _Running:
    started_at: datetime
    task: asyncio.Task
    job_id: str


_running: dict[str, _Running] = {}
_start_lock = asyncio.Lock()
_last_start: datetime | None = None


def _next_start(now: datetime) -> datetime:
    global _last_start
    nxt = now if _last_start is None or now > _last_start else _last_start + timedelta(microseconds=1)
    _last_start = nxt
    return nxt


# ----------------------------------------------------------------- formatting helpers


def format_transcript_text(rows: list[Transcript]) -> str:
    """Same layout the UI builds before calling api_process_transcript."""
    lines = []
    for t in rows:
        if t.audio_start_time is None:
            prefix = t.timestamp
        else:
            secs = int(t.audio_start_time)
            prefix = f"[{secs // 60:02d}:{secs % 60:02d}]"
        speaker = f" {t.speaker}:" if t.speaker else ""
        lines.append(f"{prefix}{speaker} {t.transcript}")
    return "\n".join(lines)


def strip_leading_title(markdown: str) -> str:
    pos = markdown.find("#")
    if pos == -1:
        return ""
    line_end = markdown.find("\n", pos)
    body_start = len(markdown) if line_end == -1 else line_end
    return markdown[body_start:].lstrip()


def strip_title_if_present(markdown: str) -> str:
    if markdown.lstrip().startswith("# "):
        return strip_leading_title(markdown)
    return processor.strip_leading_html_title(markdown)


def build_result_json(gen: processor.GeneratedSummary) -> dict:
    final = clean_llm_markdown(gen.final_markdown)
    processor.require_visible_markdown("Final summary", final)
    markdown = strip_title_if_present(final.markdown)
    if not markdown.strip():
        raise SummaryError("Final summary contains no visible content after title removal")
    template = gen.template
    return {
        "markdown": markdown,
        FORMAT_FIELD: template.output_format,
        TEMPLATE_FIELD: {"id": template.id, "name": template.name},
        "reasoning_stripped": gen.reasoning_stripped or final.reasoning_stripped,
    }


# ----------------------------------------------------------------- response shaping


def _blocknote_has_visible_text(value) -> bool:
    if isinstance(value, list):
        return any(_blocknote_has_visible_text(v) for v in value)
    if isinstance(value, dict):
        text = value.get("text")
        return (
            (isinstance(text, str) and bool(text.strip()))
            or ("content" in value and _blocknote_has_visible_text(value["content"]))
            or ("children" in value and _blocknote_has_visible_text(value["children"]))
        )
    return False


def _legacy_section_has_visible_text(value) -> bool:
    blocks = value.get("blocks") if isinstance(value, dict) else None
    return isinstance(blocks, list) and any(
        isinstance(b, dict) and isinstance(b.get("content"), str) and b["content"].strip() for b in blocks
    )


def _summary_contains_reasoning_marker(value) -> bool:
    if isinstance(value, list):
        return any(_summary_contains_reasoning_marker(v) for v in value)
    if isinstance(value, dict):
        for key, v in value.items():
            if key in ("markdown", "text", "content"):
                if isinstance(v, str) and contains_reasoning_marker(v):
                    return True
                if isinstance(v, list) and _summary_contains_reasoning_marker(v):
                    return True
            elif key in ("summary_json", "children") and _summary_contains_reasoning_marker(v):
                return True
    return False


def summary_is_renderable(value) -> bool:
    if not isinstance(value, dict) or _summary_contains_reasoning_marker(value):
        return False
    if "markdown" in value:
        md = value["markdown"]
        return isinstance(md, str) and bool(clean_llm_markdown(md).markdown)
    if "summary_json" in value:
        return _blocknote_has_visible_text(value["summary_json"])
    return any(
        _legacy_section_has_visible_text(v) for k, v in value.items() if k not in ("MeetingName", "_section_order")
    )


def _sanitize_markdown(obj: dict) -> bool:
    md = obj.get("markdown")
    if not isinstance(md, str):
        return False
    cleaned = clean_llm_markdown(md)
    obj["markdown"] = cleaned.markdown
    return cleaned.reasoning_stripped


def redact_flagged_reasoning(result):
    if not isinstance(result, dict):
        return result
    stripped = result.get("reasoning_stripped") is True
    if stripped:
        result.pop("reasoning", None)
    stripped |= _sanitize_markdown(result)
    cache = result.get(LEGACY_ENGLISH_CACHE_FIELD)
    if isinstance(cache, dict):
        stripped |= _sanitize_markdown(cache)
    if stripped:
        result["reasoning_stripped"] = True
    return result


def _strip_internal(data: dict) -> dict:
    return {k: v for k, v in data.items() if k not in INTERNAL_FIELDS}


async def get_summary_response(session: AsyncSession, meeting: Meeting, internal: bool = False) -> dict:
    """Mirrors the Rust `api_get_summary` command output.

    ``internal`` keeps server-side bookkeeping (chosen template) for the admin API.
    """
    row = (
        await session.execute(
            select(SummaryProcess)
            .join(TranscriptChunk, TranscriptChunk.meeting_id == SummaryProcess.meeting_id)
            .where(SummaryProcess.meeting_id == meeting.id)
        )
    ).scalar_one_or_none()
    if row is None:
        return {"status": "idle", "meetingName": meeting.title, "meeting_id": meeting.id,
                "start": None, "end": None, "data": None, "error": None}
    status = row.status.lower()
    error = row.error
    data = None
    if row.result:
        try:
            data = redact_flagged_reasoning(json.loads(row.result))
        except ValueError:
            logger.error("Failed to parse summary result JSON for %s", meeting.id)
    if status == "completed" and not (data is not None and summary_is_renderable(data)):
        status = "error"
        error = "Stored summary data is missing or invalid. Generate the summary again."
        data = None
    if isinstance(data, dict) and not internal:
        data = _strip_internal(data)
    return {
        "status": status,
        "meetingName": meeting.title,
        "meeting_id": meeting.id,
        "start": rfc3339_nanos(row.start_time) if row.start_time else None,
        "end": rfc3339(row.end_time),
        "data": data,
        "error": error,
    }


async def save_manual_summary(session: AsyncSession, meeting: Meeting, summary) -> None:
    if not summary_is_renderable(summary):
        raise SummaryError("Summary contains no visible content or model reasoning markers and was not saved.")
    if isinstance(summary, dict):
        if FORMAT_FIELD in summary and summary[FORMAT_FIELD] not in OUTPUT_FORMATS:
            raise SummaryError(f"Unknown summary format: {summary[FORMAT_FIELD]!r}")
        summary = _strip_internal(summary)
        # Clients edit the body only: keep the stored format (unless sent) and the chosen template.
        previous = (
            await session.execute(select(SummaryProcess.result).where(SummaryProcess.meeting_id == meeting.id))
        ).scalar_one_or_none()
        try:
            previous_data = json.loads(previous) if previous else {}
        except ValueError:
            previous_data = {}
        if FORMAT_FIELD not in summary and "summary_json" in summary:
            # BlockNote (desktop editor) output is always Markdown, even for older clients that omit `format`.
            summary[FORMAT_FIELD] = FORMAT_MARKDOWN
        if isinstance(previous_data, dict):
            if FORMAT_FIELD not in summary and previous_data.get(FORMAT_FIELD) in OUTPUT_FORMATS:
                summary[FORMAT_FIELD] = previous_data[FORMAT_FIELD]
            if TEMPLATE_FIELD in previous_data:
                summary[TEMPLATE_FIELD] = previous_data[TEMPLATE_FIELD]
    now = utcnow()
    result = await session.execute(
        update(SummaryProcess)
        .where(SummaryProcess.meeting_id == meeting.id)
        .values(result=json.dumps(summary, ensure_ascii=False), updated_at=now)
    )
    if result.rowcount == 0:
        raise LookupError("Meeting not found or can't convert the json")
    meeting.updated_at = now
    await session.commit()


# ----------------------------------------------------------------- lifecycle


async def start_summary(
    meeting: Meeting,
    provider: LlmProvider,
    text: str,
    custom_prompt: str | None,
) -> str:
    """Create/reset the process row and spawn the background task. Returns process_id."""
    async with _start_lock:
        started_at = _next_start(utcnow())
        async with session_factory()() as session:
            stmt = insert(SummaryProcess).values(
                meeting_id=meeting.id, status="PENDING", created_at=started_at, updated_at=started_at,
                start_time=started_at, result=None, error=None,
            )
            stmt = stmt.on_conflict_do_update(
                index_elements=[SummaryProcess.meeting_id],
                set_={
                    "status": "PENDING",
                    "updated_at": stmt.excluded.updated_at,
                    "start_time": stmt.excluded.start_time,
                    "result_backup": SummaryProcess.result,
                    "result_backup_timestamp": stmt.excluded.updated_at,
                    "error": None,
                    "end_time": None,
                },
            )
            await session.execute(stmt)
            chunk = insert(TranscriptChunk).values(
                meeting_id=meeting.id, meeting_name=meeting.title, transcript_text=text, model="custom-openai",
                model_name=provider.model, chunk_size=40000, overlap=1000, created_at=started_at,
            )
            chunk = chunk.on_conflict_do_update(
                index_elements=[TranscriptChunk.meeting_id],
                set_={k: chunk.excluded[k] for k in ("meeting_name", "transcript_text", "model", "model_name", "created_at")},
            )
            await session.execute(chunk)
            await session.commit()

        job = await job_store.create_job(
            meeting.user_id, "summary", meeting.id, {}, status="running",
            message="正在生成总结",
        )
        previous = _running.get(meeting.id)
        if previous is not None:
            previous.task.cancel()
        task = asyncio.create_task(
            _process(meeting.id, meeting.user_id, started_at, job.id, provider, text, custom_prompt or "")
        )
        _running[meeting.id] = _Running(started_at, task, job.id)
    return rfc3339_nanos(started_at)


def cancel_summary(meeting_id: str) -> bool:
    entry = _running.get(meeting_id)
    if entry is None:
        return False
    entry.task.cancel()
    return True


def cancel_summary_by_job(job_id: str) -> bool:
    for meeting_id, entry in _running.items():
        if entry.job_id == job_id:
            return cancel_summary(meeting_id)
    return False


async def _finish(meeting_id: str, started_at: datetime, **values) -> bool:
    """Compare-and-set on (meeting_id, start_time, status=pending), like the Rust repository."""
    now = utcnow()
    async with session_factory()() as session:
        if values.get("status") in ("failed", "cancelled"):
            # Restore the previous summary (if any) when regeneration does not complete.
            stmt = update(SummaryProcess).values(
                **values,
                updated_at=now,
                end_time=now,
                result=func.coalesce(SummaryProcess.result_backup, SummaryProcess.result),
                result_backup=None,
                result_backup_timestamp=None,
            )
        else:
            stmt = update(SummaryProcess).values(
                **values, updated_at=now, end_time=now, error=None, result_backup=None, result_backup_timestamp=None
            )
        stmt = stmt.where(
            SummaryProcess.meeting_id == meeting_id,
            SummaryProcess.start_time == started_at,
            SummaryProcess.status.ilike("pending"),
        )
        result = await session.execute(stmt)
        await session.commit()
        return result.rowcount == 1


async def _process(
    meeting_id: str,
    user_id: str,
    started_at: datetime,
    job_id: str,
    provider: LlmProvider,
    text: str,
    custom_prompt: str,
) -> None:
    t0 = time.monotonic()
    status = "ok"
    error_text: str | None = None
    try:
        templates = await enabled_templates()
        if not templates:
            raise SummaryError("服务器没有启用的总结模板")
        token_threshold = max(provider.context_tokens - 300, 1000)
        generated = await processor.generate_meeting_summary(
            provider_config(provider), text, custom_prompt, templates, token_threshold
        )
        result_json = build_result_json(generated)
        duration = time.monotonic() - t0
        if await _finish(
            meeting_id, started_at, status="completed", result=json.dumps(result_json, ensure_ascii=False),
            chunk_count=generated.successful_chunk_count, processing_time=duration,
        ):
            name = processor.extract_meeting_name(generated.final_markdown, generated.template.output_format)
            if name:
                async with session_factory()() as session:
                    await session.execute(
                        update(Meeting).where(Meeting.id == meeting_id).values(title=name, updated_at=utcnow())
                    )
                    await session.commit()
            logger.info("Summary completed for %s in %.1fs", meeting_id, duration)
        await job_store.update_job(job_id, status="completed", progress=100, message="总结已完成")
    except asyncio.CancelledError:
        status = "cancelled"
        await asyncio.shield(_on_cancel(meeting_id, started_at, job_id))
    except Exception as exc:  # noqa: BLE001 - SummaryError, LlmError, DB errors
        status = "error"
        error_text = str(exc)
        logger.error("Summary failed for %s: %s", meeting_id, exc)
        await _finish(meeting_id, started_at, status="failed", error=error_text)
        await job_store.update_job(job_id, status="failed", error=error_text, message="总结失败")
    finally:
        entry = _running.get(meeting_id)
        if entry is not None and entry.started_at == started_at:
            _running.pop(meeting_id, None)
        log_request("summary", duration_ms=int((time.monotonic() - t0) * 1000), status=status,
                    user_id=user_id, error=error_text)


async def _on_cancel(meeting_id: str, started_at: datetime, job_id: str) -> None:
    await _finish(meeting_id, started_at, status="cancelled", error=CANCELLED_ERROR)
    await job_store.update_job(job_id, status="cancelled", message="总结已取消")
