from __future__ import annotations

from typing import Any

from fastapi import APIRouter, Query
from fastapi.responses import JSONResponse

from src.storage.cache import cache

router = APIRouter()

_UNAVAILABLE = JSONResponse(
    status_code=503, content={"available": False, "reason": "data_pending"}
)


def _filter_events_by_month(
    feed: dict[str, Any],
    month: int,
    year: int,
    neg_filter: list[int],
) -> dict[str, Any]:
    items = feed.get("items", [])
    filtered = []
    for item in items:
        hd = item.get("happeningDate")
        if hd is None:
            continue
        try:
            parts = str(hd).split("-")
            item_year, item_month = int(parts[0]), int(parts[1])
        except (IndexError, ValueError):
            continue
        if item_year != year or item_month != month:
            continue
        if neg_filter:
            neg_set = set(neg_filter)
            if any(
                cat.get("id") in neg_set
                for cat in (item.get("categories") or [])
                if isinstance(cat, dict)
            ):
                continue
        filtered.append(item)
    return {
        **feed,
        "items": filtered,
        "itemCount": len(filtered),
        "hasNextPage": False,
    }


@router.get("/events/mainScreen")
@router.get("/v1/events/mainScreen")
async def get_events(
    month: int = 1,
    year: int = 2024,
    language: str = "de",
    negFilter: list[int] = Query(default=[]),  # noqa: B008
) -> JSONResponse:
    data = await cache.get_async(f"events:{language}")
    if data is None:
        return _UNAVAILABLE
    return JSONResponse(_filter_events_by_month(data, month, year, negFilter))


@router.get("/events/categories")
@router.get("/v1/events/categories")
async def get_event_categories(language: str = "de") -> JSONResponse:
    data = await cache.get_async(f"events:{language}")
    if data is None:
        return _UNAVAILABLE
    seen: set[int] = set()
    categories = []
    for item in data.get("items", []):
        for cat in item.get("categories") or []:
            if isinstance(cat, dict) and cat.get("id") not in seen:
                seen.add(cat["id"])
                categories.append(cat)
    return JSONResponse(categories)
