from __future__ import annotations

from fastapi import APIRouter
from fastapi.responses import JSONResponse

from src.storage.cache import cache

router = APIRouter()

_UNAVAILABLE = JSONResponse(
    status_code=503, content={"available": False, "reason": "data_pending"}
)


@router.get("/mensa/mainScreen")
@router.get("/v1/mensa/mainScreen")
async def get_mensa_menu(location: str = "sb", language: str = "de") -> JSONResponse:
    data = await cache.get_async(f"mensa:{location}:{language}")
    if data is None:
        return _UNAVAILABLE
    return JSONResponse(data)


@router.get("/mensa/mealDetail")
@router.get("/v1/mensa/mealDetail")
async def get_meal_detail(
    meal: int,
    location: str = "sb",
    language: str = "de",
) -> JSONResponse:
    meal_map = await cache.get_async(f"mensa:meal:{location}:{language}")
    if meal_map is None:
        return _UNAVAILABLE
    detail = meal_map.get(str(meal))
    if detail is None:
        return JSONResponse(
            status_code=404,
            content={"available": False, "reason": "meal_not_found"},
        )
    return JSONResponse(detail)


@router.get("/mensa/info")
@router.get("/v1/mensa/info")
async def get_mensa_info(location: str = "sb", language: str = "de") -> JSONResponse:
    data = await cache.get_async(f"mensa:info:{location}:{language}")
    if data is None:
        return _UNAVAILABLE
    return JSONResponse(data)


@router.get("/mensa/filters")
@router.get("/v1/mensa/filters")
async def get_mensa_filters(language: str = "de") -> JSONResponse:
    data = await cache.get_async(f"mensa:filters:{language}")
    if data is None:
        return _UNAVAILABLE
    return JSONResponse(data)
