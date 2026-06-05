from datetime import date

import pytest
from pydantic import ValidationError

from src.models.category import Category
from src.models.event import EventItem
from src.models.news import NewsFeed, NewsItem


def make_news_item(**overrides: object) -> NewsItem:
    defaults: dict[str, object] = {
        "id": 1,
        "title": "Title",
        "published_date": date(2024, 1, 15),
        "description": "Description",
        "link": "https://example.com",
        "image_url": "https://example.com/image.jpg",
        "categories": [Category(id=1, name="Campus")],
    }
    defaults.update(overrides)
    return NewsItem(**defaults)


def make_event_item(**overrides: object) -> EventItem:
    defaults: dict[str, object] = {
        "id": 2,
        "title": "Event Title",
        "happening_date": date(2024, 6, 1),
        "description": "Event Description",
        "link": "https://example.com/event",
        "image_url": None,
        "categories": [],
    }
    defaults.update(overrides)
    return EventItem(**defaults)


def make_news_feed(**overrides: object) -> NewsFeed:
    defaults: dict[str, object] = {
        "item_count": 1,
        "categories_last_changed": "2024-01-15T10:00:00Z",
        "has_next_page": False,
        "items": [make_news_item()],
    }
    defaults.update(overrides)
    return NewsFeed(**defaults)


class TestCategory:
    def test_valid(self) -> None:
        cat = Category(id=5, name="Research")
        assert cat.id == 5
        assert cat.name == "Research"

    def test_missing_name_raises(self) -> None:
        with pytest.raises(ValidationError):
            Category(id=1)  # type: ignore[call-arg]


class TestNewsItem:
    def test_published_date_optional(self) -> None:
        item = make_news_item(published_date=None)
        assert item.published_date is None

    def test_image_url_optional(self) -> None:
        item = make_news_item(image_url=None)
        assert item.image_url is None

    def test_categories_empty_list(self) -> None:
        item = make_news_item(categories=[])
        assert item.categories == []

    def test_missing_required_id_raises(self) -> None:
        with pytest.raises(ValidationError):
            NewsItem(  # type: ignore[call-arg]
                title="t",
                description="d",
                link="l",
                categories=[],
            )

    def test_published_date_format(self) -> None:
        item = make_news_item(published_date=date(2024, 1, 15))
        data = item.model_dump(by_alias=True, mode="json")
        assert data["publishedDate"] == "2024-01-15"


class TestEventItem:
    def test_happening_date_optional(self) -> None:
        item = make_event_item(happening_date=None)
        assert item.happening_date is None

    def test_happening_date_format(self) -> None:
        item = make_event_item(happening_date=date(2024, 6, 1))
        data = item.model_dump(by_alias=True, mode="json")
        assert data["happeningDate"] == "2024-06-01"

    def test_image_url_optional(self) -> None:
        item = make_event_item(image_url=None)
        assert item.image_url is None


class TestNewsFeed:
    def test_valid_feed(self) -> None:
        feed = make_news_feed()
        assert feed.item_count == 1
        assert feed.has_next_page is False

    def test_empty_items(self) -> None:
        feed = make_news_feed(item_count=0, items=[])
        assert feed.items == []
