"""
In-memory asyncio pub/sub for SSE hospital status broadcasts.
"""
import asyncio
import json
import logging
from collections import defaultdict

logger = logging.getLogger(__name__)


class SSEManager:
    def __init__(self) -> None:
        # Map from channel (e.g. "hospitals") to set of asyncio.Queue
        self._subscribers: dict[str, set[asyncio.Queue]] = defaultdict(set)

    def _channel_queues(self, channel: str) -> set[asyncio.Queue]:
        return self._subscribers[channel]

    async def subscribe(self, channel: str) -> asyncio.Queue:
        q: asyncio.Queue = asyncio.Queue(maxsize=50)
        self._subscribers[channel].add(q)
        logger.debug("SSE subscriber added to '%s'. Total: %d", channel, len(self._subscribers[channel]))
        return q

    def unsubscribe(self, channel: str, q: asyncio.Queue) -> None:
        self._subscribers[channel].discard(q)
        logger.debug("SSE subscriber removed from '%s'. Total: %d", channel, len(self._subscribers[channel]))

    async def broadcast(self, channel: str, data: dict) -> None:
        payload = json.dumps(data, default=str)
        dead: list[asyncio.Queue] = []
        for q in list(self._subscribers[channel]):
            try:
                q.put_nowait(payload)
            except asyncio.QueueFull:
                dead.append(q)
        for q in dead:
            self.unsubscribe(channel, q)
            logger.warning("Dropped slow SSE subscriber on '%s'", channel)

    async def close_all(self) -> None:
        for channel, queues in self._subscribers.items():
            for q in queues:
                try:
                    q.put_nowait(None)  # sentinel → generator exits
                except asyncio.QueueFull:
                    pass
        self._subscribers.clear()


sse_manager = SSEManager()
