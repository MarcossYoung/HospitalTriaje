"""
SSE endpoint: GET /hospitals/stream
Clients receive live hospital status events pushed by staff.
"""
import asyncio
import logging
from collections import defaultdict

from fastapi import APIRouter, Request
from fastapi.responses import StreamingResponse

from app.services.sse_manager import sse_manager
from app.config import settings

logger = logging.getLogger(__name__)
router = APIRouter()

# Per-IP connection counter
_ip_connections: dict[str, int] = defaultdict(int)


async def _event_generator(request: Request, queue: asyncio.Queue):
    try:
        while True:
            if await request.is_disconnected():
                break
            try:
                payload = await asyncio.wait_for(queue.get(), timeout=30.0)
            except asyncio.TimeoutError:
                # Send keepalive comment
                yield ": keepalive\n\n"
                continue

            if payload is None:  # sentinel from close_all()
                break

            yield f"data: {payload}\n\n"
    finally:
        sse_manager.unsubscribe("hospitals", queue)


@router.get("/stream")
async def hospital_stream(request: Request):
    client_ip = request.client.host if request.client else "unknown"

    if _ip_connections[client_ip] >= settings.sse_max_connections_per_ip:
        from fastapi import HTTPException
        raise HTTPException(status_code=429, detail="Demasiadas conexiones SSE desde esta IP")

    _ip_connections[client_ip] += 1
    queue = await sse_manager.subscribe("hospitals")

    async def cleanup_generator():
        try:
            async for chunk in _event_generator(request, queue):
                yield chunk
        finally:
            _ip_connections[client_ip] = max(0, _ip_connections[client_ip] - 1)

    return StreamingResponse(
        cleanup_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "X-Accel-Buffering": "no",
            "Connection": "keep-alive",
        },
    )
