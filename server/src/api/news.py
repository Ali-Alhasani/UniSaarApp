from __future__ import annotations

from typing import Any

from fastapi import APIRouter, Query
from fastapi.responses import JSONResponse

from src.storage.cache import cache

router = APIRouter()

_UNAVAILABLE = JSONResponse(
    status_code=503, content={"available": False, "reason": "data_pending"}
)


def _paginate_feed(
    feed: dict[str, Any],
    page: int,
    page_size: int,
    neg_filter: list[int],
) -> dict[str, Any]:
    items = feed.get("items", [])
    if neg_filter:
        neg_set = set(neg_filter)
        items = [
            it
            for it in items
            if not any(
                cat.get("id") in neg_set
                for cat in (it.get("categories") or [])
                if isinstance(cat, dict)
            )
        ]
    start = (page - 1) * page_size
    end = start + page_size
    page_items = items[start:end]
    return {
        **feed,
        "items": page_items,
        "itemCount": len(items),
        "hasNextPage": end < len(items),
    }


@router.get("/news/mainScreen")
@router.get("/v1/news/mainScreen")
async def get_news(
    page: int = 1,
    pageSize: int = 10,
    language: str = "de",
    negFilter: list[int] = Query(default=[]),  # noqa: B008
) -> JSONResponse:
    data = await cache.get_async(f"news:{language}")
    if data is None:
        return _UNAVAILABLE
    return JSONResponse(_paginate_feed(data, page, pageSize, negFilter))


@router.get("/news/categories")
@router.get("/v1/news/categories")
async def get_news_categories(language: str = "de") -> JSONResponse:
    data = await cache.get_async(f"news:{language}")
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
