from __future__ import annotations

from pathlib import Path
from unittest.mock import AsyncMock, patch

from src.core.enums import Language
from src.services.base_scraper import BaseScraper
from src.services.news_scraper import NewsAndEventsScraper

_FIXTURE_DIR = Path(__file__).parent.parent / "testdata" / "newsAndEvents"


def _read(name: str) -> str:
    return (_FIXTURE_DIR / name).read_text(encoding="utf-8")


def _patch(xml: str) -> object:
    return patch.object(BaseScraper, "fetch", new_callable=AsyncMock, return_value=xml)


async def test_fetch_news_item_id_and_date() -> None:
    with _patch(_read("exampleNewsfeed.xml")):
        feed = await NewsAndEventsScraper().fetch_news(Language.DE)
    assert feed.item_count == 1
    item = feed.items[0]
    assert item.id == 21414
    assert str(item.published_date) == "2020-01-02"


async def test_fetch_news_title_link_description() -> None:
    with _patch(_read("exampleNewsfeed.xml")):
        feed = await NewsAndEventsScraper().fetch_news(Language.DE)
    item = feed.items[0]
    assert item.title == "Title"
    assert item.link == "Link"
    assert item.description == "Description"


async def test_fetch_news_image_and_categories_deduped() -> None:
    with _patch(_read("exampleNewsfeed.xml")):
        feed = await NewsAndEventsScraper().fetch_news(Language.DE)
    item = feed.items[0]
    assert item.image_url == "imagelink"
    assert len(item.categories) == 1
    assert item.categories[0].name == "Category1"


async def test_fetch_events_item_id_and_date() -> None:
    with _patch(_read("eventsfeed.xml")):
        feed = await NewsAndEventsScraper().fetch_events(Language.DE)
    assert feed.item_count >= 1
    item = next(i for i in feed.items if i.id == 21323)
    assert str(item.happening_date) == "2020-05-16"


async def test_fetch_events_all_months_cached() -> None:
    # Past, present, and future events are all kept — the endpoint filters by month.
    xml = """<?xml version="1.0" encoding="utf-8"?>
    <rss version="2.0"><channel>
        <item>
            <guid isPermaLink="false">event-1</guid>
            <pubDate>Wed, 15 Apr 2020 10:00:00 +0200</pubDate>
            <title>Past event</title><link>http://example.com/1</link><description/>
        </item>
        <item>
            <guid isPermaLink="false">event-2</guid>
            <pubDate>Sat, 02 May 2020 10:00:00 +0200</pubDate>
            <title>Current event</title><link>http://example.com/2</link><description/>
        </item>
        <item>
            <guid isPermaLink="false">event-3</guid>
            <pubDate>Mon, 01 Jun 2020 10:00:00 +0200</pubDate>
            <title>Future event</title><link>http://example.com/3</link><description/>
        </item>
    </channel></rss>"""
    with _patch(xml):
        feed = await NewsAndEventsScraper().fetch_events(Language.DE)
    dates = [str(i.happening_date) for i in feed.items]
    assert "2020-04-15" in dates
    assert "2020-05-02" in dates
    assert "2020-06-01" in dates


async def test_fetch_news_empty_feed() -> None:
    with _patch(_read("emptyNewsfeed.xml")):
        feed = await NewsAndEventsScraper().fetch_news(Language.DE)
    assert feed.item_count == 0
    assert feed.items == []


async def test_fetch_news_missing_pubdate_leaves_date_none() -> None:
    xml = """<?xml version="1.0" encoding="utf-8"?>
    <rss version="2.0"><channel>
        <item>
            <guid isPermaLink="false">news-99</guid>
            <title>No Date</title><link>http://example.com</link>
            <description>desc</description>
        </item>
    </channel></rss>"""
    with _patch(xml):
        feed = await NewsAndEventsScraper().fetch_news(Language.DE)
    item = feed.items[0]
    assert item.published_date is None


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
        feed = await NewsAndEventsScraper().fetch_news(Language.DE)
    # After DESC sort: item B (03 Jan, newer) is first, item A (02 Jan) is second
    item_b = feed.items[0]  # newer item with Science + Campus
    item_a = feed.items[1]  # older item with Science only
    science_id_b = item_b.categories[0].id
    science_id_a = item_a.categories[0].id
    campus_id = item_b.categories[1].id
    assert science_id_b == science_id_a
    assert campus_id != science_id_b


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
        feed = await NewsAndEventsScraper().fetch_news(Language.DE)
    assert feed.item_count == 2
    assert feed.items[0].id == 0
    assert feed.items[1].id == 1
