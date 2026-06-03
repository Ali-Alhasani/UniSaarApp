from __future__ import annotations

from fastapi import APIRouter
from fastapi.responses import JSONResponse, Response

from src.services.base_scraper import ScraperError
from src.services.staff_scraper import StaffScraper, StaffSearchTooVagueError
from src.storage.cache import cache

router = APIRouter()


def _unavailable() -> Response:
    return Response(
        status_code=503,
        content="Service is starting up. Please try again in a moment.",
        media_type="text/plain",
    )


@router.get("/directory/search")
@router.get("/v1/directory/search")
async def search_directory(
    query: str,
    page: int = 1,
    pageSize: int = 10,
    language: str = "de",
) -> Response:
    if len(query.strip()) < 3:
        return Response(
            status_code=400,
            content="Search query must be at least 3 characters.",
            media_type="text/plain",
        )
    try:
        async with StaffScraper() as scraper:
            result = await scraper.search(query)
    except StaffSearchTooVagueError:
        return Response(
            status_code=400,
            content="Search query returned too many results. Please be more specific.",
            media_type="text/plain",
        )
    items = result.results if result.results is not None else []
    start = (page - 1) * pageSize
    end = start + pageSize
    page_items = items[start:end]
    payload = {
        "itemCount": len(items),
        "hasNextPage": end < len(items),
        "results": [item.model_dump(by_alias=True, mode="json") for item in page_items],
    }
    return JSONResponse(payload)


@router.get("/directory/personDetails")
@router.get("/v1/directory/personDetails")
async def get_person_details(pid: int, language: str = "de") -> Response:
    try:
        async with StaffScraper() as scraper:
            details = await scraper.fetch_details(pid)
    except ScraperError:
        return Response(
            status_code=503,
            content="The staff directory is not available right now.",
            media_type="text/plain",
        )
    return JSONResponse(details.model_dump(by_alias=True, mode="json"))


@router.get("/directory/helpfulNumbers")
@router.get("/v1/directory/helpfulNumbers")
async def get_helpful_numbers(
    language: str = "de",
    lastUpdated: str = "never",
) -> Response:
    data = await cache.get_async(f"helpful_numbers:{language}")
    if data is None:
        return _unavailable()
    return JSONResponse(data)
