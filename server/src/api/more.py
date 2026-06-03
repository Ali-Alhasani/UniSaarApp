from __future__ import annotations

from fastapi import APIRouter
from fastapi.responses import JSONResponse, Response

from src.storage.cache import cache

router = APIRouter()


def _unavailable() -> Response:
    return Response(
        status_code=503,
        content="Service is starting up. Please try again in a moment.",
        media_type="text/plain",
    )


@router.get("/more")
@router.get("/v1/more")
async def get_more_links(
    language: str = "de",
    lastUpdated: str = "never",
) -> Response:
    data = await cache.get_async(f"more:{language}")
    if data is None:
        return _unavailable()
    return JSONResponse(data)
