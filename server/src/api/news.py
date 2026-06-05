from __future__ import annotations

from fastapi import APIRouter, BackgroundTasks, Query, Request
from fastapi.responses import JSONResponse, Response

from src.api._html import preferred_lang, render_detail_html, render_error_html
from src.api._responses import cache_not_ready
from src.core.enums import Language
from src.core.routes import Route
from src.models.news import NewsFeed, NewsItem
from src.services.article_scraper import scrape_and_cache_article
from src.services.feed_service import apply_neg_filter, paginate_items
from src.storage import cache_keys
from src.storage.cache import cache

router = APIRouter()


async def _find_news_item(
    item_id: int, language: Language
) -> tuple[NewsItem, Language] | None:
    langs = [language] + [lg for lg in Language if lg != language]
    for lang in langs:
        feed = await cache.get_model(cache_keys.news(lang), NewsFeed)
        if feed is not None:
            item = next((i for i in feed.items if i.id == item_id), None)
            if item is not None:
                return item, lang
    return None


@router.get(Route.NEWS_MAIN_SCREEN)
async def get_news(
    page: int = 0,
    pageSize: int = 10,
    language: Language = Language.DE,
    negFilter: list[int] = Query(default=[]),  # noqa: B008
) -> Response:
    feed = await cache.get_model(cache_keys.news(language), NewsFeed)
    if feed is None:
        return cache_not_ready(language)
    filtered = apply_neg_filter(feed.items, negFilter)
    page_items, has_next = paginate_items(filtered, page, pageSize)
    return JSONResponse(
        NewsFeed(
            item_count=len(filtered),
            categories_last_changed=feed.categories_last_changed,
            has_next_page=has_next,
            items=page_items,
        ).model_dump(by_alias=True, mode="json")
    )


@router.get(Route.NEWS_CATEGORIES)
async def get_news_categories(language: Language = Language.DE) -> Response:
    feed = await cache.get_model(cache_keys.news(language), NewsFeed)
    if feed is None:
        return cache_not_ready(language)
    seen: set[int] = set()
    categories = []
    for item in feed.items:
        for cat in item.categories:
            if cat.id not in seen:
                seen.add(cat.id)
                categories.append(cat.model_dump())
    return JSONResponse(categories)


@router.get(Route.NEWS_DETAILS)
async def get_news_detail(
    id: int, request: Request, background_tasks: BackgroundTasks
) -> Response:
    lang = preferred_lang(request.headers.get("accept-language", ""))
    result = await _find_news_item(id, lang)
    if result is None:
        return Response(content=render_error_html(lang), media_type="text/html")
    item, lang = result

    article_body: str | None = await cache.get_async(cache_keys.article_body(id, lang))
    if article_body is None and item.link:
        background_tasks.add_task(
            scrape_and_cache_article, item.link, cache_keys.article_body(id, lang)
        )

    return Response(
        content=render_detail_html(
            item, lang, is_event=False, article_body=article_body
        ),
        media_type="text/html",
    )
