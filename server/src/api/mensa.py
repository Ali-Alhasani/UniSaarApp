from __future__ import annotations

from fastapi import APIRouter
from fastapi.responses import JSONResponse, Response

from src.api._responses import cache_not_ready
from src.core.enums import Language, MensaLocation
from src.core.locale import MEAL_NOT_FOUND
from src.core.routes import Route
from src.models.mensa import MensaFilters, MensaInfo, MensaMenu
from src.storage import cache_keys
from src.storage.cache import cache

router = APIRouter()


@router.get(Route.MENSA_MAIN_SCREEN)
async def get_mensa_menu(
    location: MensaLocation = MensaLocation.SB, language: Language = Language.DE
) -> Response:
    menu = await cache.get_model(cache_keys.mensa_menu(location, language), MensaMenu)
    if menu is None:
        return cache_not_ready(language)
    return JSONResponse(menu.model_dump(by_alias=True, mode="json"))


@router.get(Route.MENSA_MEAL_DETAIL)
async def get_meal_detail(
    meal: int,
    location: MensaLocation = MensaLocation.SB,
    language: Language = Language.DE,
) -> Response:
    meal_map = await cache.get_async(cache_keys.mensa_meal(location, language))
    if meal_map is None:
        return cache_not_ready(language)
    detail = meal_map.get(str(meal))
    if detail is None:
        return Response(
            status_code=404, content=MEAL_NOT_FOUND[language], media_type="text/plain"
        )
    return JSONResponse(detail)


@router.get(Route.MENSA_INFO)
async def get_mensa_info(
    location: MensaLocation = MensaLocation.SB, language: Language = Language.DE
) -> Response:
    info = await cache.get_model(cache_keys.mensa_info(location, language), MensaInfo)
    if info is None:
        return cache_not_ready(language)
    return JSONResponse(info.model_dump(by_alias=True, mode="json"))


@router.get(Route.MENSA_FILTERS)
async def get_mensa_filters(language: Language = Language.DE) -> Response:
    filters = await cache.get_model(cache_keys.mensa_filters(language), MensaFilters)
    if filters is None:
        return cache_not_ready(language)
    return JSONResponse(filters.model_dump(by_alias=True, mode="json"))
