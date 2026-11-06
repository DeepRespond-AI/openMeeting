"""Background import / retranscription jobs (asyncio queue, cancellable, progress tracking)."""
from __future__ import annotations

import asyncio
import logging
import time

from sqlalchemy import delete, select, update

from meeting_ms.config import get_settings
from meeting_ms.db.models import Job, Meeting, Transcript
from meeting_ms.db.session import session_factory
from meeting_ms.infrastructure.stt_client import SttClient, SttNotReady
from meeting_ms.jobs import store as job_store
from meeting_ms.monitor.metrics import log_request
from meeting_ms.storage import oss
from meeting_ms.storage.audio import delete_meeting_files, move_local_audio_to_oss, open_meeting_audio
from meeting_ms.stt.audio import decode_file, vad_split
from meeting_ms.stt.base import SAMPLE_RATE, normalize_language
from meeting_ms.utils import iso_ms, new_uuid, utcnow

logger = logging.getLogger(__name__)


class JobCancelled(Exception):
    pass


class JobRunner:
    def __init__(self) -> None:
        self._queue: asyncio.Queue[str] = asyncio.Queue()
        self._workers: list[asyncio.Task] = []
        self._cancelled: set[str] = set()
        # Imported audio moving to OSS after its job, by meeting id (a later job waits for it).
        self._oss_moves: dict[str, asyncio.Task] = {}

    async def start(self, workers: int = 1) -> None:
        await self._recover()
        for i in range(max(1, workers)):
            self._workers.append(asyncio.create_task(self._worker(), name=f"job-worker-{i}"))

    async def stop(self) -> None:
        for w in self._workers:
            w.cancel()
        await asyncio.gather(*self._workers, return_exceptions=True)
        self._workers.clear()
        moves = list(self._oss_moves.values())
        for move in moves:
            move.cancel()  # the audio simply stays local
        await asyncio.gather(*moves, return_exceptions=True)

    async def _recover(self) -> None:
        """Jobs interrupted by a restart: requeue queued ones, fail running ones."""
        async with session_factory()() as session:
            # Room finalization is idempotent and has durable source chunks.
            await session.execute(update(Job).where(Job.status == "running", Job.kind == "room_recording")
                                  .values(status="queued", updated_at=utcnow()))
            await session.execute(
                update(Job)
                .where(Job.status == "running")
                .values(status="failed", error="服务器重启，任务已中断", updated_at=utcnow())
            )
            queued = (
                await session.execute(
                    select(Job.id).where(Job.status == "queued", Job.kind.in_(("import", "retranscribe", "room_recording")))
                    .order_by(Job.created_at)
                )
            ).scalars().all()
            await session.commit()
        for job_id in queued:
            self._queue.put_nowait(job_id)

    def submit(self, job_id: str) -> None:
        self._queue.put_nowait(job_id)

    async def cancel(self, job_id: str) -> Job | None:
        job = await job_store.get_job(job_id)
        if job is None or job.status in job_store.TERMINAL:
            return job
        if job.kind == "summary":
            from meeting_ms.summary import service as summary_service

            # The summary task also records the cancellation on its process row.
            summary_service.cancel_summary_by_job(job_id)
            return await job_store.update_job(job_id, status="cancelled", message="任务已取消")
        self._cancelled.add(job_id)
        if job.status == "queued":
            await self._cleanup_import(job)
            return await job_store.update_job(job_id, status="cancelled", message="任务已取消")
        # Running: the worker notices between segments and finalizes the job.
        return await job_store.update_job(job_id, status="cancelled", message="任务已取消")

    async def _worker(self) -> None:
        while True:
            job_id = await self._queue.get()
            try:
                await self._run(job_id)
            except Exception:  # noqa: BLE001
                logger.exception("Job %s crashed", job_id)
            finally:
                self._queue.task_done()

    def _check(self, job_id: str) -> None:
        if job_id in self._cancelled:
            raise JobCancelled()

    async def _run(self, job_id: str) -> None:
        job = await job_store.get_job(job_id)
        if job is None or job.status != "queued" or job_id in self._cancelled:
            self._cancelled.discard(job_id)
            return
        if job.kind == "room_recording":
            from meeting_ms.jobs.room_recording import run
            try:
                await run(job, self._check)
            finally:
                self._cancelled.discard(job_id)
            return
        t0 = time.monotonic()
        audio_sec = 0.0
        stt = SttClient()
        if job.meeting_id and (move := self._oss_moves.get(job.meeting_id)):
            await asyncio.wait({move})
        await job_store.update_job(job_id, status="running", progress=1, message="正在解码音频")
        try:
            async with session_factory()() as session:
                meeting = await session.get(Meeting, job.meeting_id) if job.meeting_id else None
            if meeting is None or not meeting.audio_path:
                raise RuntimeError("会议音频不存在")
            if not await stt.ready():
                raise SttNotReady()

            async with open_meeting_audio(meeting) as audio_file:
                audio = await asyncio.to_thread(decode_file, audio_file)
            audio_sec = audio.size / SAMPLE_RATE
            self._check(job_id)
            await job_store.update_job(job_id, progress=5, message="正在检测语音片段")
            segments = await asyncio.to_thread(vad_split, audio)
            self._check(job_id)
            total = len(segments)
            await job_store.update_job(job_id, progress=10, segments=total, message=f"共 {total} 个语音片段")

            language = normalize_language(job.params.get("language"))
            rows: list[Transcript] = []
            last_progress = 10
            for i, (start, end) in enumerate(segments):
                self._check(job_id)
                result = await stt.transcribe_segment(audio[start:end], language)
                text = result.text.strip()
                if text:
                    s, e = start / SAMPLE_RATE, end / SAMPLE_RATE
                    rows.append(
                        Transcript(
                            id=new_uuid(), meeting_id=meeting.id, transcript=text, timestamp=iso_ms(utcnow()),
                            audio_start_time=round(s, 3), audio_end_time=round(e, 3), duration=round(e - s, 3),
                            confidence=result.confidence,
                        )
                    )
                progress = 10 + int(88 * (i + 1) / max(total, 1))
                if progress != last_progress:
                    last_progress = progress
                    await job_store.update_job(job_id, progress=progress, message=f"正在转写 {i + 1}/{total}")
            self._check(job_id)

            async with session_factory()() as session:
                # Replace transcripts atomically (retranscribe) / insert (import).
                await session.execute(delete(Transcript).where(Transcript.meeting_id == meeting.id))
                session.add_all(rows)
                await session.execute(
                    update(Meeting).where(Meeting.id == meeting.id).values(updated_at=utcnow(), duration=audio_sec)
                )
                await session.commit()
            await job_store.update_job(
                job_id, status="completed", progress=100, segments=len(rows), message=f"完成，共 {len(rows)} 段转写"
            )
            log_request(job.kind, duration_ms=int((time.monotonic() - t0) * 1000), audio_sec=audio_sec,
                        user_id=job.user_id)
            if job.kind == "import":
                self._schedule_oss_move(meeting.id)
        except JobCancelled:
            logger.info("Job %s cancelled", job_id)
            await self._cleanup_import(job)
            await job_store.update_job(job_id, only_if_active=False, status="cancelled", message="任务已取消")
        except SttNotReady:
            await self._fail(job, "语音识别模型未就绪", t0, audio_sec)
        except Exception as exc:  # noqa: BLE001
            logger.exception("Job %s failed", job_id)
            await self._fail(job, str(exc) or exc.__class__.__name__, t0, audio_sec)
        finally:
            self._cancelled.discard(job_id)

    def _schedule_oss_move(self, meeting_id: str) -> None:
        """Imports are transcribed from local disk; afterwards their audio goes to OSS (if configured)."""

        async def _move() -> None:
            try:
                if await move_local_audio_to_oss(meeting_id):
                    logger.info("Imported audio of meeting %s moved to OSS", meeting_id)
            except Exception as exc:  # noqa: BLE001 - the audio stays local and playable
                logger.warning("Moving imported audio of meeting %s to OSS failed: %s",
                               meeting_id, oss.describe_error(exc))
            finally:
                self._oss_moves.pop(meeting_id, None)

        self._oss_moves[meeting_id] = asyncio.create_task(_move(), name=f"oss-move-{meeting_id}")

    async def _fail(self, job: Job, error: str, t0: float, audio_sec: float) -> None:
        await self._cleanup_import(job)
        await job_store.update_job(job.id, status="failed", error=error, message="任务失败")
        log_request(job.kind, duration_ms=int((time.monotonic() - t0) * 1000), audio_sec=audio_sec,
                    status="error", user_id=job.user_id, error=error)

    async def _cleanup_import(self, job: Job) -> None:
        """A failed/cancelled import leaves no half-created meeting behind."""
        if job.kind != "import" or not job.meeting_id:
            return
        async with session_factory()() as session:
            meeting = await session.get(Meeting, job.meeting_id)
            if meeting is not None:
                await session.delete(meeting)
                await session.commit()
                await delete_meeting_files(meeting)


job_runner = JobRunner()
