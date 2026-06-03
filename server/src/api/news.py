from __future__ import annotations

from typing import Any

from fastapi import APIRouter, Query, Request
from fastapi.responses import JSONResponse, Response

from src.api._html import preferred_lang, render_detail_html, render_error_html
from src.services.article_scraper import ArticleScraper
from src.storage.cache import cache

router = APIRouter()

_LANGS = ["de", "en", "fr"]


async def _find_news_item(
    item_id: int, language: str
) -> tuple[dict[str, object], str] | None:
    langs = [language] + [lg for lg in _LANGS if lg != language]
    for lang in langs:
        data = await cache.get_async(f"news:{lang}")
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
) -> Response:
    data = await cache.get_async(f"news:{language}")
    if data is None:
        return _unavailable()
    return JSONResponse(_paginate_feed(data, page, pageSize, negFilter))


@router.get("/news/categories")
@router.get("/v1/news/categories")
async def get_news_categories(language: str = "de") -> Response:
    data = await cache.get_async(f"news:{language}")
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


@router.get("/news/details")
@router.get("/v1/news/details")
async def get_news_detail(id: int, request: Request) -> Response:
    lang = preferred_lang(request.headers.get("accept-language", ""))
    result = await _find_news_item(id, lang)
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
        content=render_detail_html(item, lang, is_event=False, article_body=article_body),
        media_type="text/html",
    )
