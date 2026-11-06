from __future__ import annotations

import asyncio
import json
import logging

from fastapi import APIRouter, Query, Request
from fastapi.responses import StreamingResponse

from meeting_ms import SERVER_VERSION
from meeting_ms.config import get_settings
from meeting_ms.infrastructure.stt_client import SttClient, SttUnavailable
from meeting_ms.infrastructure.user_client import UserClient
from meeting_ms.llm.providers import llm_status
from meeting_ms.monitor import metrics
from meeting_ms.monitor.events import broker
from meeting_ms.monitor.inflight import tracker

logger = logging.getLogger(__name__)
router = APIRouter(tags=["admin-dashboard"])

PING_INTERVAL_SEC = 15.0
# Downstream state (connections / STT) arrives via polling instead of the former in-process events.
POLL_INTERVAL_SEC = 3.0


def _user_client() -> UserClient:
    return UserClient()


def _stt_client() -> SttClient:
    return SttClient()


def _stt_brief(status: dict) -> dict:
    """SSE "stt" event shape (matches the pre-split registry.status() payload)."""
    return {k: status.get(k) for k in ("engine", "model", "ready", "error")}


async def connections_snapshot() -> list[dict]:
    conn = await _user_client().connections()
    return tracker.merge(conn["snapshot"] if conn else [])


@router.get("/dashboard")
async def dashboard() -> dict:
    conn = await _user_client().connections()
    online, recording = (conn["online"], conn["recording"]) if conn else (0, 0)
    device = "cpu"
    try:
        status = await _stt_client().status()
        device = status.get("device") or "cpu"
        stt = _stt_brief(status)
    except SttUnavailable as exc:
        stt = {"engine": None, "model": None, "ready": False, "error": str(exc)}
    system = await asyncio.to_thread(metrics.system_stats, str(get_settings().data_dir))
    return {
        "server_version": SERVER_VERSION,
        "uptime_sec": metrics.uptime_sec(),
        "system": system,
        "device": device,
        "stt": stt,
        "llm": await llm_status(),
        "stats": {"online_clients": online, "recording_clients": recording, **await metrics.today_stats()},
    }


@router.get("/stats/timeseries")
async def timeseries(hours: int = Query(24, ge=1, le=24 * 31)) -> list[dict]:
    return await metrics.timeseries(hours)


@router.get("/connections")
async def connections() -> list[dict]:
    return await connections_snapshot()


def _sse(event: str, data: str) -> str:
    return f"event: {event}\ndata: {data}\n\n"


@router.get("/events")
async def events(request: Request) -> StreamingResponse:
    queue = broker.subscribe()

    async def stream():
        try:
            # Initial snapshot so the UI can render immediately.
            yield _sse("connections", json.dumps(await connections_snapshot(), ensure_ascii=False))
            try:
                yield _sse("stt", json.dumps(_stt_brief(await _stt_client().status()), ensure_ascii=False))
            except SttUnavailable as exc:
                yield _sse("stt", json.dumps({"engine": None, "model": None, "ready": False, "error": str(exc)}))
            yield _sse("llm", json.dumps(await llm_status(), ensure_ascii=False))
            while True:
                if await request.is_disconnected():
                    break
                try:
                    event, data = await asyncio.wait_for(queue.get(), timeout=PING_INTERVAL_SEC)
                    yield _sse(event, data)
                except TimeoutError:
                    yield _sse("ping", "{}")
        finally:
            broker.unsubscribe(queue)

    return StreamingResponse(
        stream(),
        media_type="text/event-stream",
        headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no", "Connection": "keep-alive"},
    )


async def downstream_ticker() -> None:
    """Poll user_ms connections and stt_ms status, publishing SSE events on change.

    Replaces the in-process pushes of the monolith: heartbeats fired "connections" from
    the connection registry and STT activation/download published "stt"/"model-download".
    """
    last_conn: list | None = None
    last_stt: dict | None = None
    last_models: dict | None = None
    while True:
        await asyncio.sleep(POLL_INTERVAL_SEC)
        if not broker.subscriber_count:
            continue
        # Connections from user_ms
        try:
            snapshot = await connections_snapshot()
            if snapshot != last_conn:
                last_conn = snapshot
                broker.publish("connections", snapshot)
        except Exception:  # noqa: BLE001 - never kill the ticker
            logger.exception("Polling user_ms connections failed")
        # STT status + model download progress from stt_ms
        try:
            status = await _stt_client().status()
            brief = _stt_brief(status)
            if brief != last_stt:
                last_stt = brief
                broker.publish("stt", brief)
            models = {m["id"]: m for m in status.get("models") or []}
            if models != last_models:
                if last_models is not None:
                    for model_id, model in models.items():
                        old = last_models.get(model_id)
                        if old is None or (
                            old["status"], old["progress"], old["error"]
                        ) != (model["status"], model["progress"], model["error"]):
                            broker.publish("model-download", model)
                last_models = models
        except SttUnavailable:
            brief = {"engine": None, "model": None, "ready": False, "error": "stt_ms 无法访问"}
            if brief != last_stt:
                last_stt = brief
                broker.publish("stt", brief)
        except Exception:  # noqa: BLE001
            logger.exception("Polling stt_ms status failed")
