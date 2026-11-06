"""In-process pub/sub used by the admin SSE stream."""
from __future__ import annotations

import asyncio
import json
import logging
from typing import Any

logger = logging.getLogger(__name__)


class EventBroker:
    def __init__(self) -> None:
        self._subscribers: set[asyncio.Queue[tuple[str, str]]] = set()

    def subscribe(self) -> asyncio.Queue[tuple[str, str]]:
        queue: asyncio.Queue[tuple[str, str]] = asyncio.Queue(maxsize=500)
        self._subscribers.add(queue)
        return queue

    def unsubscribe(self, queue: asyncio.Queue[tuple[str, str]]) -> None:
        self._subscribers.discard(queue)

    def publish(self, event: str, data: Any) -> None:
        if not self._subscribers:
            return
        payload = json.dumps(data, ensure_ascii=False, default=str)
        for queue in list(self._subscribers):
            try:
                queue.put_nowait((event, payload))
            except asyncio.QueueFull:
                logger.debug("Dropping SSE event %s for slow subscriber", event)

    @property
    def subscriber_count(self) -> int:
        return len(self._subscribers)


broker = EventBroker()
