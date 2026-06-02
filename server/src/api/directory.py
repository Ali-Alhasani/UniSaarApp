from __future__ import annotations

from fastapi import APIRouter, HTTPException
from fastapi.responses import JSONResponse

from src.services.staff_scraper import StaffScraper, StaffSearchTooVagueError
from src.storage.cache import cache

router = APIRouter()

_UNAVAILABLE = JSONResponse(
    status_code=503, content={"available": False, "reason": "data_pending"}
)


@router.get("/directory/search")
@router.get("/v1/directory/search")
async def search_directory(
    query: str,
    page: int = 1,
    pageSize: int = 10,
    language: str = "de",
) -> JSONResponse:
    if len(query.strip()) < 3:
        raise HTTPException(
            status_code=400,
            detail="Search query must be at least 3 characters.",
        )
    try:
        async with StaffScraper() as scraper:
            result = await scraper.search(query)
    except StaffSearchTooVagueError as exc:
        raise HTTPException(
            status_code=400,
            detail="Search query returned too many results. Please be more specific.",
        ) from exc
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
async def get_person_details(pid: int, language: str = "de") -> JSONResponse:
    async with StaffScraper() as scraper:
        details = await scraper.fetch_details(pid)
    return JSONResponse(details.model_dump(by_alias=True, mode="json"))


@router.get("/directory/helpfulNumbers")
@router.get("/v1/directory/helpfulNumbers")
async def get_helpful_numbers(
    language: str = "de",
    lastUpdated: str = "never",
) -> JSONResponse:
    data = await cache.get_async(f"helpful_numbers:{language}")
    if data is None:
        return _UNAVAILABLE
    return JSONResponse(data)
