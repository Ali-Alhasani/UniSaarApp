from __future__ import annotations

from fastapi import APIRouter
from fastapi.responses import JSONResponse, Response

from src.api._responses import cache_not_ready
from src.core.enums import Language
from src.core.locale import (
    DIRECTORY_QUERY_TOO_BROAD,
    DIRECTORY_QUERY_TOO_SHORT,
    DIRECTORY_UNAVAILABLE,
)
from src.core.routes import Route
from src.models.helpful_numbers import HelpfulNumbersResponse
from src.services.base_scraper import ScraperError
from src.services.staff_scraper import StaffScraper, StaffSearchTooVagueError
from src.storage import cache_keys
from src.storage.cache import cache

router = APIRouter()


@router.get(Route.DIRECTORY_SEARCH)
async def search_directory(
    query: str,
    page: int = 1,
    pageSize: int = 10,
    language: Language = Language.DE,
) -> Response:
    if len(query.strip()) < 3:
        return Response(
            status_code=400,
            content=DIRECTORY_QUERY_TOO_SHORT[language],
            media_type="text/plain",
        )
    try:
        async with StaffScraper() as scraper:
            result = await scraper.search(query)
    except StaffSearchTooVagueError:
        return Response(
            status_code=400,
            content=DIRECTORY_QUERY_TOO_BROAD[language],
            media_type="text/plain",
        )
    items = result.results if result.results is not None else []
    start = page * pageSize
    end = start + pageSize
    page_items = items[start:end]
    payload = {
        "itemCount": len(items),
        "hasNextPage": end < len(items),
        "results": [item.model_dump(by_alias=True, mode="json") for item in page_items],
    }
    return JSONResponse(payload)


@router.get(Route.DIRECTORY_PERSON_DETAILS)
async def get_person_details(pid: int, language: Language = Language.DE) -> Response:
    try:
        async with StaffScraper() as scraper:
            details = await scraper.fetch_details(pid)
    except ScraperError:
        return Response(
            status_code=503,
            content=DIRECTORY_UNAVAILABLE[language],
            media_type="text/plain",
        )
    return JSONResponse(details.model_dump(by_alias=True, mode="json"))


@router.get(Route.DIRECTORY_HELPFUL_NUMBERS)
async def get_helpful_numbers(
    language: Language = Language.DE,
    lastUpdated: str = "never",
) -> Response:
    data = await cache.get_model(
        cache_keys.helpful_numbers(language), HelpfulNumbersResponse
    )
    if data is None:
        return cache_not_ready(language)
    return JSONResponse(data.model_dump(by_alias=True, mode="json"))
