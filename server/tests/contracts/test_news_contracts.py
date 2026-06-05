"""Contract tests — assert serialized keys match iOS Codable field names."""

from datetime import date

from src.models.category import Category
from src.models.event import EventFeed, EventItem
from src.models.news import NewsFeed, NewsItem


def make_news_item() -> NewsItem:
    return NewsItem(
        id=1,
        title="Uni News",
        published_date=date(2024, 1, 15),
        description="A description",
        link="https://example.com",
        image_url="https://example.com/img.jpg",
        categories=[Category(id=2, name="Research")],
    )


def make_event_item() -> EventItem:
    return EventItem(
        id=2,
        title="Campus Event",
        happening_date=date(2024, 6, 1),
        description="An event",
        link="https://example.com/event",
        image_url=None,
        categories=[Category(id=3, name="Events")],
    )


class TestCategoryContract:
    def test_category_keys(self) -> None:
        data = Category(id=5, name="Campus").model_dump(by_alias=True)
        assert "id" in data
        assert "name" in data

    def test_no_extra_keys(self) -> None:
        data = Category(id=5, name="Campus").model_dump(by_alias=True)
        assert set(data.keys()) == {"id", "name"}


class TestNewsItemContract:
    def test_ios_field_names_present(self) -> None:
        data = make_news_item().model_dump(by_alias=True)
        assert "id" in data
        assert "title" in data
        assert "publishedDate" in data
        assert "description" in data
        assert "link" in data
        assert "imageURL" in data
        assert "categories" in data

    def test_no_snake_case_keys(self) -> None:
        data = make_news_item().model_dump(by_alias=True)
        assert "published_date" not in data
        assert "image_url" not in data

    def test_no_event_fields_on_news_item(self) -> None:
        data = make_news_item().model_dump(by_alias=True)
        assert "happeningDate" not in data
        assert "isEvent" not in data

    def test_published_date_plain_iso(self) -> None:
        data = make_news_item().model_dump(by_alias=True, mode="json")
        assert data["publishedDate"] == "2024-01-15"

    def test_image_url_present_when_set(self) -> None:
        data = make_news_item().model_dump(by_alias=True)
        assert data["imageURL"] == "https://example.com/img.jpg"

    def test_categories_contain_id_and_name(self) -> None:
        data = make_news_item().model_dump(by_alias=True)
        cat = data["categories"][0]
        assert "id" in cat
        assert "name" in cat


class TestEventItemContract:
    def test_ios_field_names_present(self) -> None:
        data = make_event_item().model_dump(by_alias=True)
        assert "id" in data
        assert "title" in data
        assert "happeningDate" in data
        assert "description" in data
        assert "link" in data
        assert "imageURL" in data
        assert "categories" in data

    def test_no_snake_case_keys(self) -> None:
        data = make_event_item().model_dump(by_alias=True)
        assert "happening_date" not in data
        assert "image_url" not in data

    def test_no_news_fields_on_event_item(self) -> None:
        data = make_event_item().model_dump(by_alias=True)
        assert "publishedDate" not in data
        assert "isEvent" not in data

    def test_happening_date_plain_iso(self) -> None:
        data = make_event_item().model_dump(by_alias=True, mode="json")
        assert data["happeningDate"] == "2024-06-01"

    def test_image_url_none_when_missing(self) -> None:
        data = make_event_item().model_dump(by_alias=True)
        assert data["imageURL"] is None


class TestNewsFeedContract:
    def test_ios_field_names_present(self) -> None:
        feed = NewsFeed(
            item_count=1,
            categories_last_changed="2024-01-15T10:00:00Z",
            has_next_page=False,
            items=[make_news_item()],
        )
        data = feed.model_dump(by_alias=True)
        assert "itemCount" in data
        assert "categoriesLastChanged" in data
        assert "hasNextPage" in data
        assert "items" in data

    def test_no_snake_case_keys(self) -> None:
        feed = NewsFeed(
            item_count=0,
            categories_last_changed="2024-01-01",
            has_next_page=False,
            items=[],
        )
        data = feed.model_dump(by_alias=True)
        assert "item_count" not in data
        assert "categories_last_changed" not in data
        assert "has_next_page" not in data


class TestEventFeedContract:
    def test_ios_field_names_present(self) -> None:
        feed = EventFeed(
            item_count=1,
            categories_last_changed="",
            has_next_page=False,
            items=[make_event_item()],
        )
        data = feed.model_dump(by_alias=True)
        assert "itemCount" in data
        assert "categoriesLastChanged" in data
        assert "hasNextPage" in data
        assert "items" in data
