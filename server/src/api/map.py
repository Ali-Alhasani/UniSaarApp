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


@router.get("/map/")
@router.get("/v1/map/")
async def get_map(lastUpdated: str = "never") -> Response:
    data = await cache.get_async("map")
    if data is None:
        return _unavailable()
    return JSONResponse(data)
