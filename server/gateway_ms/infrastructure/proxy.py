"""Reverse proxy over httpx: streaming request/response passthrough with hop-by-hop cleanup."""
from __future__ import annotations

import logging
from collections.abc import AsyncIterable, Mapping

import httpx
from fastapi.responses import JSONResponse, StreamingResponse

logger = logging.getLogger(__name__)

_HOP_HEADERS = {"transfer-encoding", "content-length", "connection", "keep-alive", "host"}


def sanitize_request_headers(headers: Mapping[str, str]) -> dict[str, str]:
    return {k: v for k, v in headers.items() if k.lower() not in _HOP_HEADERS}


def sanitize_response_headers(headers: httpx.Headers) -> dict[str, str]:
    return {k: v for k, v in headers.items() if k.lower() not in _HOP_HEADERS}


def target_url(base_url: str, path: str) -> str:
    return f"{base_url.rstrip('/')}/{path.lstrip('/')}"


async def proxy_stream(
    method: str,
    url: str,
    *,
    query: list[tuple[str, str]] | None = None,
    headers: dict[str, str],
    content: AsyncIterable[bytes] | None,
    client: httpx.AsyncClient,
) -> StreamingResponse | JSONResponse:
    """Forward the request with a fully streamed body and a fully streamed response body.

    Streaming everything (JSON included) keeps audio uploads/PCM segments, release downloads
    and the dashboard SSE byte-exact without special cases.
    """
    request = client.build_request(method=method, url=url, params=query, headers=headers, content=content)
    try:
        response = await client.send(request, stream=True)
    except httpx.HTTPError as exc:
        logger.warning("Downstream %s unreachable: %s", url, exc)
        return JSONResponse({"detail": "上游服务不可用"}, status_code=502)

    out_headers = sanitize_response_headers(response.headers)
    media_type = response.headers.get("content-type")

    async def iterator():
        try:
            async for chunk in response.aiter_bytes():
                if chunk:
                    yield chunk
        except httpx.StreamClosed:
            return
        finally:
            await response.aclose()

    return StreamingResponse(iterator(), status_code=response.status_code, headers=out_headers, media_type=media_type)
