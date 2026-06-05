from __future__ import annotations

from fastapi import APIRouter
from fastapi.responses import JSONResponse, Response

from src.api._responses import cache_not_ready
from src.core.enums import Language
from src.core.routes import Route
from src.models.map import MapResponse
from src.storage import cache_keys
from src.storage.cache import cache

router = APIRouter()


@router.get(Route.CAMPUS_MAP)
async def get_map(
    lastUpdated: str = "never", language: Language = Language.DE
) -> Response:
    data = await cache.get_model(cache_keys.campus_map(), MapResponse)
    if data is None:
        return cache_not_ready(language)
    return JSONResponse(data.model_dump(by_alias=True, mode="json"))
