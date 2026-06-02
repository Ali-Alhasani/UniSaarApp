from __future__ import annotations

from pathlib import Path
from unittest.mock import AsyncMock, patch

from src.services.base_scraper import BaseScraper
from src.services.news_scraper import NewsAndEventsScraper

_FIXTURE_DIR = Path(__file__).parent.parent / "testdata" / "newsAndEvents"


def _read(name: str) -> str:
    return (_FIXTURE_DIR / name).read_text(encoding="utf-8")


def _patch(xml: str) -> object:
    return patch.object(BaseScraper, "fetch", new_callable=AsyncMock, return_value=xml)


async def test_fetch_news_item_id_and_date() -> None:
    with _patch(_read("exampleNewsfeed.xml")):
        feed = await NewsAndEventsScraper().fetch_news("de")
    assert feed.item_count == 1
    item = feed.items[0]
    assert item.id == 21414
    assert str(item.published_date) == "2020-01-02"
    assert item.is_event is False
    assert item.happening_date is None


async def test_fetch_news_title_link_description() -> None:
    with _patch(_read("exampleNewsfeed.xml")):
        feed = await NewsAndEventsScraper().fetch_news("de")
    item = feed.items[0]
    assert item.title == "Title"
    assert item.link == "Link"
    assert item.description == "Description"


async def test_fetch_news_image_and_categories_deduped() -> None:
    with _patch(_read("exampleNewsfeed.xml")):
        feed = await NewsAndEventsScraper().fetch_news("de")
    item = feed.items[0]
    assert item.image_url == "imagelink"
    assert len(item.categories) == 1
    assert item.categories[0].name == "Category1"


async def test_fetch_events_item_id_and_date() -> None:
    with _patch(_read("eventsfeed.xml")):
        feed = await NewsAndEventsScraper().fetch_events("de")
    assert feed.item_count >= 1
    item = feed.items[0]
    assert item.id == 21323
    assert item.is_event is True
    assert item.published_date is None
    assert str(item.happening_date) == "2020-05-16"


async def test_fetch_news_empty_feed() -> None:
    with _patch(_read("emptyNewsfeed.xml")):
        feed = await NewsAndEventsScraper().fetch_news("de")
    assert feed.item_count == 0
    assert feed.items == []


async def test_fetch_news_missing_pubdate_leaves_dates_none() -> None:
    xml = """<?xml version="1.0" encoding="utf-8"?>
    <rss version="2.0"><channel>
        <item>
            <guid isPermaLink="false">news-99</guid>
            <title>No Date</title><link>http://example.com</link>
            <description>desc</description>
        </item>
    </channel></rss>"""
    with _patch(xml):
        feed = await NewsAndEventsScraper().fetch_news("de")
    item = feed.items[0]
    assert item.published_date is None
    assert item.happening_date is None


async def test_fetch_news_shared_category_ids_across_items() -> None:
    xml = """<?xml version="1.0" encoding="utf-8"?>
    <rss version="2.0"><channel>
        <item>
            <guid isPermaLink="false">news-1</guid>
            <pubDate>Thu, 02 Jan 2020 14:00:00 +0100</pubDate>
            <title>A</title><link>http://example.com/a</link><description>d</description>
            <category>Science</category>
        </item>
        <item>
            <guid isPermaLink="false">news-2</guid>
            <pubDate>Fri, 03 Jan 2020 14:00:00 +0100</pubDate>
            <title>B</title><link>http://example.com/b</link><description>d</description>
            <category>Science</category>
            <category>Campus</category>
        </item>
    </channel></rss>"""
    with _patch(xml):
        feed = await NewsAndEventsScraper().fetch_news("de")
    science_id_item1 = feed.items[0].categories[0].id
    science_id_item2 = feed.items[1].categories[0].id
    campus_id = feed.items[1].categories[1].id
    assert science_id_item1 == science_id_item2
    assert campus_id != science_id_item1


async def test_fetch_news_fallback_id_when_no_guid() -> None:
    xml = """<?xml version="1.0" encoding="utf-8"?>
    <rss version="2.0"><channel>
        <item>
            <pubDate>Thu, 02 Jan 2020 14:00:00 +0100</pubDate>
            <title>No GUID Item</title><link>http://example.com</link>
            <description>desc</description>
        </item>
        <item>
            <pubDate>Thu, 02 Jan 2020 15:00:00 +0100</pubDate>
            <title>Also No GUID</title><link>http://example.com/2</link>
            <description>desc2</description>
        </item>
    </channel></rss>"""
    with _patch(xml):
        feed = await NewsAndEventsScraper().fetch_news("de")
    assert feed.item_count == 2
    assert feed.items[0].id == 0
    assert feed.items[1].id == 1
