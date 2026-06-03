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


@router.get("/mensa/mainScreen")
@router.get("/v1/mensa/mainScreen")
async def get_mensa_menu(location: str = "sb", language: str = "de") -> Response:
    data = await cache.get_async(f"mensa:{location}:{language}")
    if data is None:
        return _unavailable()
    return JSONResponse(data)


@router.get("/mensa/mealDetail")
@router.get("/v1/mensa/mealDetail")
async def get_meal_detail(
    meal: int,
    location: str = "sb",
    language: str = "de",
) -> Response:
    meal_map = await cache.get_async(f"mensa:meal:{location}:{language}")
    if meal_map is None:
        return _unavailable()
    detail = meal_map.get(str(meal))
    if detail is None:
        return Response(
            status_code=404,
            content="Meal details not found.",
            media_type="text/plain",
        )
    return JSONResponse(detail)


@router.get("/mensa/info")
@router.get("/v1/mensa/info")
async def get_mensa_info(location: str = "sb", language: str = "de") -> Response:
    data = await cache.get_async(f"mensa:info:{location}:{language}")
    if data is None:
        return _unavailable()
    return JSONResponse(data)


@router.get("/mensa/filters")
@router.get("/v1/mensa/filters")
async def get_mensa_filters(language: str = "de") -> Response:
    data = await cache.get_async(f"mensa:filters:{language}")
    if data is None:
        return _unavailable()
    return JSONResponse(data)
