from __future__ import annotations

from fastapi import APIRouter
from fastapi.responses import JSONResponse

from src.storage.cache import cache

router = APIRouter()

_UNAVAILABLE = JSONResponse(
    status_code=503, content={"available": False, "reason": "data_pending"}
)


@router.get("/map/")
@router.get("/v1/map/")
async def get_map(lastUpdated: str = "never") -> JSONResponse:
    data = await cache.get_async("map")
    if data is None:
        return _UNAVAILABLE
    return JSONResponse(data)
