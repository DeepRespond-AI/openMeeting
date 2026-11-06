"""Request logging, system resource metrics and admin statistics."""
from __future__ import annotations

import asyncio
import logging
import time
from datetime import timedelta
from functools import lru_cache

import psutil
from sqlalchemy import case, func, select

from meeting_ms.db.models import Job, RequestLog
from meeting_ms.db.session import session_factory
from meeting_ms.utils import iso, utcnow

logger = logging.getLogger(__name__)

START_MONOTONIC = time.monotonic()
_background: set[asyncio.Task] = set()


def uptime_sec() -> int:
    return int(time.monotonic() - START_MONOTONIC)


async def _write_log(entry: RequestLog) -> None:
    try:
        async with session_factory()() as session:
            session.add(entry)
            await session.commit()
    except Exception:  # noqa: BLE001 - metrics must never break requests
        logger.exception("Failed to write request log")


def log_request(
    kind: str,
    *,
    duration_ms: int,
    status: str = "ok",
    audio_sec: float = 0.0,
    session_id: str | None = None,
    user_id: str | None = None,
    error: str | None = None,
) -> None:
    """Fire-and-forget insert into request_logs."""
    entry = RequestLog(
        kind=kind,
        duration_ms=int(duration_ms),
        audio_sec=float(audio_sec),
        status=status,
        session_id=session_id,
        user_id=user_id,
        error=(error or None) and error[:2000],
        created_at=utcnow(),
    )
    task = asyncio.create_task(_write_log(entry))
    _background.add(task)
    task.add_done_callback(_background.discard)


async def flush_pending_logs() -> None:
    if _background:
        await asyncio.gather(*list(_background), return_exceptions=True)


@lru_cache
def _nvml_available() -> bool:
    try:
        import pynvml

        pynvml.nvmlInit()
        return True
    except Exception:  # noqa: BLE001
        return False


def gpu_stats() -> list[dict]:
    if not _nvml_available():
        return []
    import pynvml

    gpus = []
    try:
        for i in range(pynvml.nvmlDeviceGetCount()):
            h = pynvml.nvmlDeviceGetHandleByIndex(i)
            name = pynvml.nvmlDeviceGetName(h)
            util = pynvml.nvmlDeviceGetUtilizationRates(h)
            mem = pynvml.nvmlDeviceGetMemoryInfo(h)
            gpus.append(
                {
                    "index": i,
                    "name": name.decode() if isinstance(name, bytes) else name,
                    "util_percent": float(util.gpu),
                    "mem_used": int(mem.used),
                    "mem_total": int(mem.total),
                }
            )
    except Exception:  # noqa: BLE001
        logger.exception("Failed to query NVML")
    return gpus


def system_stats(data_dir: str) -> dict:
    vm = psutil.virtual_memory()
    disk = psutil.disk_usage(data_dir)
    return {
        "cpu_percent": psutil.cpu_percent(interval=None),
        "mem_used": int(vm.total - vm.available),
        "mem_total": int(vm.total),
        "disk_used": int(disk.used),
        "disk_total": int(disk.total),
        "gpus": gpu_stats(),
    }


async def today_stats() -> dict:
    since = utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
    async with session_factory()() as session:
        row = (
            await session.execute(
                select(
                    func.count(RequestLog.id),
                    func.coalesce(func.sum(case((RequestLog.kind == "transcribe", RequestLog.audio_sec), else_=0.0)), 0.0),
                    func.count(RequestLog.id).filter(RequestLog.status != "ok"),
                    func.avg(RequestLog.duration_ms).filter(RequestLog.kind == "transcribe"),
                ).where(RequestLog.created_at >= since)
            )
        ).one()
        running_jobs = (
            await session.execute(select(func.count(Job.id)).where(Job.status.in_(("queued", "running"))))
        ).scalar_one()
    return {
        "running_jobs": int(running_jobs),
        "today_requests": int(row[0]),
        "today_audio_sec": round(float(row[1]), 2),
        "today_errors": int(row[2]),
        "avg_latency_ms": None if row[3] is None else round(float(row[3]), 1),
    }


async def timeseries(hours: int) -> list[dict]:
    hours = max(1, min(hours, 24 * 31))
    end = utcnow().replace(minute=0, second=0, microsecond=0)
    start = end - timedelta(hours=hours - 1)
    bucket = func.date_trunc("hour", RequestLog.created_at).label("bucket")
    async with session_factory()() as session:
        rows = (
            await session.execute(
                select(
                    bucket,
                    func.count(RequestLog.id).filter(RequestLog.kind == "transcribe"),
                    func.coalesce(func.sum(RequestLog.audio_sec).filter(RequestLog.kind == "transcribe"), 0.0),
                    func.count(RequestLog.id).filter(RequestLog.kind == "summary"),
                    func.count(RequestLog.id).filter(RequestLog.status != "ok"),
                    func.avg(RequestLog.duration_ms).filter(RequestLog.kind == "transcribe"),
                )
                .where(RequestLog.created_at >= start)
                .group_by(bucket)
            )
        ).all()
    by_hour = {r[0].astimezone(end.tzinfo).replace(minute=0, second=0, microsecond=0): r for r in rows}
    out = []
    for i in range(hours):
        ts = start + timedelta(hours=i)
        r = by_hour.get(ts)
        out.append(
            {
                "ts": iso(ts),
                "transcribe_requests": int(r[1]) if r else 0,
                "audio_sec": round(float(r[2]), 2) if r else 0.0,
                "summary_requests": int(r[3]) if r else 0,
                "errors": int(r[4]) if r else 0,
                "avg_latency_ms": round(float(r[5]), 1) if r and r[5] is not None else None,
            }
        )
    return out
