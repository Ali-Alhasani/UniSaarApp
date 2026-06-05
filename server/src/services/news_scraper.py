from __future__ import annotations

import re
import xml.etree.ElementTree as ET
import zlib
from datetime import date
from email.utils import parsedate_to_datetime

from src.core.constants import EVENTS_URLS, NEWS_URLS
from src.core.enums import Language
from src.models.category import Category
from src.models.event import EventFeed, EventItem
from src.models.news import NewsFeed, NewsItem
from src.services.base_scraper import BaseScraper


class NewsAndEventsScraper(BaseScraper):
    @staticmethod
    def _clean(el: ET.Element | None) -> str:
        return (el.text or "").strip() if el is not None else ""

    def _parse_id(self, item_el: ET.Element, fallback_id: int) -> tuple[int, bool]:
        guid_el = item_el.find("guid")
        guid_text = guid_el.text if guid_el is not None else ""
        m = re.search(r"\d+", guid_text or "")
        return (int(m.group()), False) if m else (fallback_id, True)

    def _parse_date(self, item_el: ET.Element) -> date | None:
        pub_el = item_el.find("pubDate")
        if pub_el is not None and pub_el.text:
            try:
                return parsedate_to_datetime(pub_el.text).date()
            except (ValueError, TypeError):
                pass
        return None

    def _parse_categories(self, item_el: ET.Element) -> list[Category]:
        seen: set[str] = set()
        categories: list[Category] = []
        for cat_el in item_el.findall("category"):
            cat_name = self._clean(cat_el)
            if cat_name and cat_name not in seen:
                cat_id = zlib.crc32(cat_name.encode()) & 0x7FFF_FFFF
                categories.append(Category(id=cat_id, name=cat_name))
                seen.add(cat_name)
        return categories

    def _parse_image_url(self, item_el: ET.Element) -> str | None:
        for enc_el in item_el.findall("enclosure"):
            if "image" in enc_el.get("type", ""):
                return enc_el.get("url")
        return None

    def _parse_news_item(
        self, item_el: ET.Element, fallback_id: int
    ) -> tuple[NewsItem, bool]:
        item_id, used_fallback = self._parse_id(item_el, fallback_id)
        return NewsItem(
            id=item_id,
            title=self._clean(item_el.find("title")),
            published_date=self._parse_date(item_el),
            description=self._clean(item_el.find("description")),
            link=self._clean(item_el.find("link")),
            image_url=self._parse_image_url(item_el),
            categories=self._parse_categories(item_el),
        ), used_fallback

    def _parse_event_item(
        self, item_el: ET.Element, fallback_id: int
    ) -> tuple[EventItem, bool]:
        item_id, used_fallback = self._parse_id(item_el, fallback_id)
        return EventItem(
            id=item_id,
            title=self._clean(item_el.find("title")),
            happening_date=self._parse_date(item_el),
            description=self._clean(item_el.find("description")),
            link=self._clean(item_el.find("link")),
            image_url=self._parse_image_url(item_el),
            categories=self._parse_categories(item_el),
        ), used_fallback

    def _parse_news_feed(self, xml_text: str) -> list[NewsItem]:
        root = ET.fromstring(xml_text.strip().encode())
        channel = root.find("channel")
        if channel is None:
            return []
        next_id = 0
        items: list[NewsItem] = []
        for item_el in channel.findall("item"):
            item, used_fallback = self._parse_news_item(item_el, next_id)
            if used_fallback:
                next_id += 1
            items.append(item)
        return sorted(items, key=lambda i: i.published_date or date.min, reverse=True)

    def _parse_events_feed(self, xml_text: str) -> list[EventItem]:
        root = ET.fromstring(xml_text.strip().encode())
        channel = root.find("channel")
        if channel is None:
            return []
        next_id = 0
        items: list[EventItem] = []
        for item_el in channel.findall("item"):
            item, used_fallback = self._parse_event_item(item_el, next_id)
            if used_fallback:
                next_id += 1
            items.append(item)
        return sorted(items, key=lambda i: i.happening_date or date.max)

    async def fetch_news(self, lang: Language = Language.DE) -> NewsFeed:
        url = NEWS_URLS[lang]
        xml_text = await self.fetch(url)
        items = self._parse_news_feed(xml_text)
        return NewsFeed(
            item_count=len(items),
            categories_last_changed="",
            has_next_page=False,
            items=items,
        )

    async def fetch_events(self, lang: Language = Language.DE) -> EventFeed:
        url = EVENTS_URLS[lang]
        xml_text = await self.fetch(url)
        items = self._parse_events_feed(xml_text)
        return EventFeed(
            item_count=len(items),
            categories_last_changed="",
            has_next_page=False,
            items=items,
        )
