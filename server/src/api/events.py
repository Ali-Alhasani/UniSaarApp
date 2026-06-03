from __future__ import annotations

from typing import Any

from fastapi import APIRouter, Query, Request
from fastapi.responses import JSONResponse, Response

from src.api._html import preferred_lang, render_detail_html, render_error_html
from src.services.article_scraper import ArticleScraper
from src.storage.cache import cache

router = APIRouter()

_LANGS = ["de", "en", "fr"]


async def _find_event_item(
    item_id: int, language: str
) -> tuple[dict[str, object], str] | None:
    langs = [language] + [lg for lg in _LANGS if lg != language]
    for lang in langs:
        data = await cache.get_async(f"events:{lang}")
        if data:
            item = next(
                (i for i in data.get("items", []) if i.get("id") == item_id), None
            )
            if item is not None:
                return item, lang
    return None


def _unavailable() -> Response:
    return Response(
        status_code=503,
        content="Service is starting up. Please try again in a moment.",
        media_type="text/plain",
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
) -> Response:
    data = await cache.get_async(f"events:{language}")
    if data is None:
        return _unavailable()
    return JSONResponse(_filter_events_by_month(data, month, year, negFilter))


@router.get("/events/categories")
@router.get("/v1/events/categories")
async def get_event_categories(language: str = "de") -> Response:
    data = await cache.get_async(f"events:{language}")
    if data is None:
        return _unavailable()
    seen: set[int] = set()
    categories = []
    for item in data.get("items", []):
        for cat in item.get("categories") or []:
            if isinstance(cat, dict) and cat.get("id") not in seen:
                seen.add(cat["id"])
                categories.append(cat)
    return JSONResponse(categories)


_ARTICLE_BODY_TTL = 86_400  # 24 hours


@router.get("/events/details")
@router.get("/v1/events/details")
async def get_event_detail(id: int, request: Request) -> Response:
    lang = preferred_lang(request.headers.get("accept-language", ""))
    result = await _find_event_item(id, lang)
    if result is None:
        return Response(content=render_error_html(lang), media_type="text/html")
    item, lang = result

    cache_key = f"article_body:{id}:{lang}"
    article_body: str | None = await cache.get_async(cache_key)
    if article_body is None:
        link = str(item.get("link") or "")
        if link:
            async with ArticleScraper() as scraper:
                article_body = await scraper.fetch_article_body(link)
            if article_body:
                await cache.set_async(cache_key, article_body, expire=_ARTICLE_BODY_TTL)

    return Response(
        content=render_detail_html(item, lang, is_event=True, article_body=article_body),
        media_type="text/html",
    )
