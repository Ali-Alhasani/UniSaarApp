from __future__ import annotations

from fastapi import APIRouter
from fastapi.responses import JSONResponse

from src.storage.cache import cache

router = APIRouter()

_UNAVAILABLE = JSONResponse(
    status_code=503, content={"available": False, "reason": "data_pending"}
)


@router.get("/more")
@router.get("/v1/more")
async def get_more_links(
    language: str = "de",
    lastUpdated: str = "never",
) -> JSONResponse:
    data = await cache.get_async(f"more:{language}")
    if data is None:
        return _UNAVAILABLE
    return JSONResponse(data)
