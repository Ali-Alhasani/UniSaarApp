from __future__ import annotations

import re
import xml.etree.ElementTree as ET
import zlib
from datetime import date
from email.utils import parsedate_to_datetime

from src.core.constants import EVENTS_URLS, NEWS_URLS
from src.models.news import Category, NewsFeed, NewsItem
from src.services.base_scraper import BaseScraper


class NewsAndEventsScraper(BaseScraper):
    def _parse_feed(self, xml_text: str, is_event: bool) -> list[NewsItem]:
        root = ET.fromstring(xml_text.strip())
        channel = root.find("channel")
        if channel is None:
            return []

        next_item_id = 0

        items: list[NewsItem] = []
        for item_el in channel.findall("item"):
            guid_el = item_el.find("guid")
            guid_text = guid_el.text if guid_el is not None else ""
            m = re.search(r"\d+", guid_text or "")
            item_id = int(m.group()) if m else next_item_id

            pub_date: date | None = None
            happening_date: date | None = None
            pub_el = item_el.find("pubDate")
            if pub_el is not None and pub_el.text:
                try:
                    parsed_dt = parsedate_to_datetime(pub_el.text)
                    parsed_date = parsed_dt.date()
                    if is_event:
                        happening_date = parsed_date
                    else:
                        pub_date = parsed_date
                except (ValueError, TypeError):
                    pass

            title_el = item_el.find("title")
            title = (title_el.text or "").strip() if title_el is not None else ""

            link_el = item_el.find("link")
            link = (link_el.text or "").strip() if link_el is not None else ""

            desc_el = item_el.find("description")
            description = (desc_el.text or "").strip() if desc_el is not None else ""

            seen_names: set[str] = set()
            categories: list[Category] = []
            for cat_el in item_el.findall("category"):
                cat_name = (cat_el.text or "").strip()
                if cat_name and cat_name not in seen_names:
                    cat_id = zlib.crc32(cat_name.encode()) & 0x7FFF_FFFF
                    categories.append(Category(id=cat_id, name=cat_name))
                    seen_names.add(cat_name)

            image_url: str | None = None
            for enc_el in item_el.findall("enclosure"):
                if "image" in enc_el.get("type", ""):
                    image_url = enc_el.get("url")
                    break

            if m is None:
                next_item_id += 1
            items.append(
                NewsItem(
                    id=item_id,
                    title=title,
                    published_date=pub_date,
                    happening_date=happening_date,
                    description=description,
                    link=link,
                    image_url=image_url,
                    categories=categories,
                    is_event=is_event,
                )
            )

        return items

    _MAX_ITEMS = 200

    @staticmethod
    def _sort_news(items: list[NewsItem]) -> list[NewsItem]:
        return sorted(items, key=lambda i: i.published_date or date.min, reverse=True)

    @staticmethod
    def _sort_events(items: list[NewsItem]) -> list[NewsItem]:
        return sorted(items, key=lambda i: i.happening_date or date.max)

    async def fetch_news(self, lang: str = "de") -> NewsFeed:
        url = NEWS_URLS.get(lang, NEWS_URLS["de"])
        xml_text = await self.fetch(url)
        items = self._sort_news(self._parse_feed(xml_text, is_event=False))[
            : self._MAX_ITEMS
        ]
        return NewsFeed(
            item_count=len(items),
            categories_last_changed="",
            has_next_page=False,
            items=items,
        )

    async def fetch_events(self, lang: str = "de") -> NewsFeed:
        url = EVENTS_URLS.get(lang, EVENTS_URLS["de"])
        xml_text = await self.fetch(url)
        items = self._sort_events(self._parse_feed(xml_text, is_event=True))
        return NewsFeed(
            item_count=len(items),
            categories_last_changed="",
            has_next_page=False,
            items=items,
        )
