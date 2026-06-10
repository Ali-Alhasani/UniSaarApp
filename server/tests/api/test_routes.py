from __future__ import annotations

from unittest.mock import AsyncMock, patch

import pytest
from httpx import AsyncClient

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

_NEWS_FEED = {
    "itemCount": 2,
    "categoriesLastChanged": "2024-01-01T00:00:00Z",
    "hasNextPage": False,
    "items": [
        {
            "id": 1,
            "title": "News A",
            "publishedDate": "2024-01-15",
            "happeningDate": None,
            "description": "desc",
            "link": "https://example.com",
            "imageURL": None,
            "categories": [{"id": 5, "name": "Campus"}],
            "isEvent": False,
        },
        {
            "id": 2,
            "title": "News B",
            "publishedDate": "2024-01-16",
            "happeningDate": None,
            "description": "desc",
            "link": "https://example.com",
            "imageURL": None,
            "categories": [{"id": 7, "name": "Research"}],
            "isEvent": False,
        },
    ],
}

_EVENTS_FEED = {
    "itemCount": 1,
    "categoriesLastChanged": "2024-01-01T00:00:00Z",
    "hasNextPage": False,
    "items": [
        {
            "id": 10,
            "title": "Event A",
            "publishedDate": "2024-03-01",
            "happeningDate": "2024-03-15",
            "description": "desc",
            "link": "https://example.com",
            "imageURL": None,
            "categories": [],
            "isEvent": True,
        }
    ],
}

_MENSA_MENU = {
    "days": [
        {
            "date": "Montag 03.06.",
            "meals": [
                {
                    "id": 0,
                    "mealName": "Spaghetti",
                    "counterName": "Komplettmenü",
                    "openingHours": "11:30 - 14:00",
                    "color": {"r": 0, "g": 0, "b": 0},
                    "components": ["Pasta"],
                    "notices": [],
                    "prices": None,
                    "pricingNotice": None,
                }
            ],
        }
    ],
    "filtersLastChanged": "2024-01-01T00:00:00Z",
}

_MEAL_MAP = {
    "10202601010000": {
        "id": 10202601010000,
        "mealName": "Spaghetti",
        "description": "Pasta counter",
        "color": {"r": 0, "g": 0, "b": 0},
        "generalNotices": [],
        "prices": None,
        "pricingNotice": None,
        "mealComponents": [],
    }
}

_MENSA_INFO = {
    "name": "Mensa Saarbrücken",
    "description": "Main canteen.",
    "imageLink": "https://example.com/img.jpg",
}

_MENSA_FILTERS = {
    "locations": [{"locationID": "sb", "name": "Saarbrücken"}],
    "notices": [
        {"noticeID": "G", "name": "Gluten", "isAllergen": True, "isNegated": False}
    ],
}

_MAP = {"mapInfo": [], "updateTime": "2024-01-01"}
_MORE = {"linksLastChanged": "2024-01-01", "language": "de", "links": []}
_HELPFUL = {"numbers": []}


def _cache_returning(value: object) -> AsyncMock:
    m = AsyncMock(return_value=value)
    return m


# ---------------------------------------------------------------------------
# News
# ---------------------------------------------------------------------------


class TestNewsMainScreen:
    async def test_returns_200_with_cached_data(self, client: AsyncClient) -> None:
        with patch(
            "src.api.news.cache.get_async",
            _cache_returning(_NEWS_FEED),
        ):
            r = await client.get("/news/mainScreen?page=0&pageSize=10&language=de")
        assert r.status_code == 200
        assert "items" in r.json()

    async def test_v1_path_returns_same_data(self, client: AsyncClient) -> None:
        with patch(
            "src.api.news.cache.get_async",
            _cache_returning(_NEWS_FEED),
        ):
            r = await client.get("/v1/news/mainScreen?page=0&pageSize=10&language=de")
        assert r.status_code == 200

    async def test_missing_cache_returns_503(self, client: AsyncClient) -> None:
        with patch("src.api.news.cache.get_async", _cache_returning(None)):
            r = await client.get("/news/mainScreen?page=0&pageSize=10&language=de")
        assert r.status_code == 503
        assert "gestartet" in r.text  # German because language=de

    async def test_negfilter_excludes_matching_category(
        self, client: AsyncClient
    ) -> None:
        # negFilter=5 should exclude the item with category id=5
        with patch(
            "src.api.news.cache.get_async",
            _cache_returning(_NEWS_FEED),
        ):
            r = await client.get(
                "/news/mainScreen?page=0&pageSize=10&language=de&negFilter=5"
            )
        data = r.json()
        assert all(
            not any(c.get("id") == 5 for c in item.get("categories", []))
            for item in data["items"]
        )

    async def test_pagination_slices_items(self, client: AsyncClient) -> None:
        with patch(
            "src.api.news.cache.get_async",
            _cache_returning(_NEWS_FEED),
        ):
            r = await client.get("/news/mainScreen?page=0&pageSize=1&language=de")
        assert len(r.json()["items"]) == 1

    async def test_has_next_page_set_correctly(self, client: AsyncClient) -> None:
        with patch(
            "src.api.news.cache.get_async",
            _cache_returning(_NEWS_FEED),
        ):
            r = await client.get("/news/mainScreen?page=0&pageSize=1&language=de")
        assert r.json()["hasNextPage"] is True


class TestNewsCategories:
    async def test_returns_unique_categories(self, client: AsyncClient) -> None:
        with patch(
            "src.api.news.cache.get_async",
            _cache_returning(_NEWS_FEED),
        ):
            r = await client.get("/news/categories?language=de")
        ids = [c["id"] for c in r.json()]
        assert sorted(ids) == sorted({5, 7})

    async def test_missing_cache_returns_503(self, client: AsyncClient) -> None:
        with patch("src.api.news.cache.get_async", _cache_returning(None)):
            r = await client.get("/news/categories?language=de")
        assert r.status_code == 503


# ---------------------------------------------------------------------------
# Events
# ---------------------------------------------------------------------------


class TestEventsMainScreen:
    async def test_filters_by_month_year(self, client: AsyncClient) -> None:
        with patch(
            "src.api.events.cache.get_async",
            _cache_returning(_EVENTS_FEED),
        ):
            r = await client.get("/events/mainScreen?month=3&year=2024&language=de")
        assert r.status_code == 200
        items = r.json()["items"]
        assert len(items) == 1

    async def test_wrong_month_returns_empty(self, client: AsyncClient) -> None:
        with patch(
            "src.api.events.cache.get_async",
            _cache_returning(_EVENTS_FEED),
        ):
            r = await client.get("/events/mainScreen?month=1&year=2024&language=de")
        assert r.json()["items"] == []

    async def test_v1_path_works(self, client: AsyncClient) -> None:
        with patch(
            "src.api.events.cache.get_async",
            _cache_returning(_EVENTS_FEED),
        ):
            r = await client.get("/v1/events/mainScreen?month=3&year=2024&language=de")
        assert r.status_code == 200

    async def test_missing_cache_returns_503(self, client: AsyncClient) -> None:
        with patch("src.api.events.cache.get_async", _cache_returning(None)):
            r = await client.get("/events/mainScreen?month=3&year=2024&language=de")
        assert r.status_code == 503


# ---------------------------------------------------------------------------
# Mensa
# ---------------------------------------------------------------------------


class TestMensaMainScreen:
    async def test_returns_full_menu(self, client: AsyncClient) -> None:
        with patch(
            "src.api.mensa.cache.get_async",
            _cache_returning(_MENSA_MENU),
        ):
            r = await client.get("/mensa/mainScreen?location=sb&language=de")
        assert r.status_code == 200
        assert "days" in r.json()
        assert "filtersLastChanged" in r.json()

    async def test_missing_cache_returns_503(self, client: AsyncClient) -> None:
        with patch("src.api.mensa.cache.get_async", _cache_returning(None)):
            r = await client.get("/mensa/mainScreen?location=sb&language=de")
        assert r.status_code == 503

    async def test_v1_path_works(self, client: AsyncClient) -> None:
        with patch(
            "src.api.mensa.cache.get_async",
            _cache_returning(_MENSA_MENU),
        ):
            r = await client.get("/v1/mensa/mainScreen?location=sb&language=de")
        assert r.status_code == 200


class TestMensaMealDetail:
    async def test_returns_detail_by_id(self, client: AsyncClient) -> None:
        with patch(
            "src.api.mensa.cache.get_async",
            _cache_returning(_MEAL_MAP),
        ):
            r = await client.get("/mensa/mealDetail?meal=10202601010000&language=de")
        assert r.status_code == 200
        data = r.json()
        assert data["mealName"] == "Spaghetti"
        assert "mealComponents" in data
        assert "generalNotices" in data

    async def test_unknown_meal_id_returns_404(self, client: AsyncClient) -> None:
        with patch(
            "src.api.mensa.cache.get_async",
            _cache_returning(_MEAL_MAP),
        ):
            r = await client.get("/mensa/mealDetail?meal=10202601019999&language=de")
        assert r.status_code == 404

    async def test_missing_cache_returns_503(self, client: AsyncClient) -> None:
        with patch("src.api.mensa.cache.get_async", _cache_returning(None)):
            r = await client.get("/mensa/mealDetail?meal=10202601010000&language=de")
        assert r.status_code == 503


class TestMensaInfo:
    async def test_returns_info(self, client: AsyncClient) -> None:
        with patch(
            "src.api.mensa.cache.get_async",
            _cache_returning(_MENSA_INFO),
        ):
            r = await client.get("/mensa/info?location=sb&language=de")
        assert r.status_code == 200
        assert r.json()["imageLink"] == "https://example.com/img.jpg"

    async def test_missing_cache_returns_503(self, client: AsyncClient) -> None:
        with patch("src.api.mensa.cache.get_async", _cache_returning(None)):
            r = await client.get("/mensa/info?location=sb&language=de")
        assert r.status_code == 503


class TestMensaFilters:
    async def test_returns_filters(self, client: AsyncClient) -> None:
        with patch(
            "src.api.mensa.cache.get_async",
            _cache_returning(_MENSA_FILTERS),
        ):
            r = await client.get("/mensa/filters?language=de")
        assert r.status_code == 200
        assert "locations" in r.json()
        assert "notices" in r.json()

    async def test_missing_cache_returns_503(self, client: AsyncClient) -> None:
        with patch("src.api.mensa.cache.get_async", _cache_returning(None)):
            r = await client.get("/mensa/filters?language=de")
        assert r.status_code == 503


# ---------------------------------------------------------------------------
# Map
# ---------------------------------------------------------------------------


class TestMap:
    async def test_returns_map(self, client: AsyncClient) -> None:
        with patch("src.api.campus_map.cache.get_async", _cache_returning(_MAP)):
            r = await client.get("/map/")
        assert r.status_code == 200

    async def test_v1_path_works(self, client: AsyncClient) -> None:
        with patch("src.api.campus_map.cache.get_async", _cache_returning(_MAP)):
            r = await client.get("/v1/map/")
        assert r.status_code == 200

    async def test_missing_cache_returns_503(self, client: AsyncClient) -> None:
        with patch("src.api.campus_map.cache.get_async", _cache_returning(None)):
            r = await client.get("/map/")
        assert r.status_code == 503


# ---------------------------------------------------------------------------
# More links
# ---------------------------------------------------------------------------


class TestMoreLinks:
    async def test_returns_links(self, client: AsyncClient) -> None:
        with patch("src.api.more.cache.get_async", _cache_returning(_MORE)):
            r = await client.get("/more?language=de")
        assert r.status_code == 200

    async def test_missing_cache_returns_503(self, client: AsyncClient) -> None:
        with patch("src.api.more.cache.get_async", _cache_returning(None)):
            r = await client.get("/more?language=de")
        assert r.status_code == 503


# ---------------------------------------------------------------------------
# Helpful numbers
# ---------------------------------------------------------------------------


class TestHelpfulNumbers:
    async def test_returns_numbers(self, client: AsyncClient) -> None:
        with patch(
            "src.api.directory.cache.get_async",
            _cache_returning(_HELPFUL),
        ):
            r = await client.get("/directory/helpfulNumbers?language=de")
        assert r.status_code == 200

    async def test_missing_cache_returns_503(self, client: AsyncClient) -> None:
        with patch("src.api.directory.cache.get_async", _cache_returning(None)):
            r = await client.get("/directory/helpfulNumbers?language=de")
        assert r.status_code == 503


# ---------------------------------------------------------------------------
# Route generation header
# ---------------------------------------------------------------------------


class TestRouteGenerationHeader:
    async def test_legacy_path_gets_legacy_header(self, client: AsyncClient) -> None:
        with patch("src.api.campus_map.cache.get_async", _cache_returning(_MAP)):
            r = await client.get("/map/")
        assert r.headers.get("x-route-generation") == "legacy"

    async def test_v1_path_gets_v1_header(self, client: AsyncClient) -> None:
        with patch("src.api.campus_map.cache.get_async", _cache_returning(_MAP)):
            r = await client.get("/v1/map/")
        assert r.headers.get("x-route-generation") == "v1"


# ---------------------------------------------------------------------------
# Directory search input validation (no network call made for short queries)
# ---------------------------------------------------------------------------


class TestDirectorySearchValidation:
    async def test_query_shorter_than_3_returns_400(self, client: AsyncClient) -> None:
        r = await client.get("/directory/search?query=ab&page=0&pageSize=10")
        assert r.status_code == 400

    async def test_single_char_returns_400(self, client: AsyncClient) -> None:
        r = await client.get("/directory/search?query=a&page=0&pageSize=10")
        assert r.status_code == 400

    @pytest.mark.asyncio
    async def test_valid_query_calls_scraper(self, client: AsyncClient) -> None:
        from src.models.staff import StaffList

        mock_result = StaffList(item_count=0, has_next_page=False, results=[])
        with patch("src.api.directory.StaffScraper") as MockScraper:
            instance = MockScraper.return_value.__aenter__.return_value
            instance.search = AsyncMock(return_value=mock_result)
            r = await client.get("/directory/search?query=Schmidt&page=0&pageSize=10")
        assert r.status_code == 200


# ---------------------------------------------------------------------------
# News detail
# ---------------------------------------------------------------------------


class TestNewsDetail:
    async def test_unknown_id_returns_error_html(self, client: AsyncClient) -> None:
        with patch("src.api.news.cache.get_async", _cache_returning(None)):
            r = await client.get("/news/details?id=9999")
        assert r.status_code == 200
        assert r.headers["content-type"].startswith("text/html")
        assert "error-owl" in r.text

    async def test_known_id_no_cached_body_returns_rss_fallback(
        self, client: AsyncClient
    ) -> None:
        side_effects = {
            "news:de": _NEWS_FEED,
            "article_body:1:de": None,
        }

        async def _cache_side_effect(key: str) -> object:
            return side_effects.get(key)

        with (
            patch("src.api.news.cache.get_async", side_effect=_cache_side_effect),
            patch("src.api.news.scrape_and_cache_article"),
        ):
            r = await client.get(
                "/news/details?id=1", headers={"Accept-Language": "de"}
            )
        assert r.status_code == 200
        assert r.headers["content-type"].startswith("text/html")
        assert "News A" in r.text
        assert "summary" in r.text

    async def test_known_id_with_cached_body_returns_full_article(
        self, client: AsyncClient
    ) -> None:
        side_effects = {
            "news:de": _NEWS_FEED,
            "article_body:1:de": "<p>Full article content.</p>",
        }

        async def _cache_side_effect(key: str) -> object:
            return side_effects.get(key)

        with patch("src.api.news.cache.get_async", side_effect=_cache_side_effect):
            r = await client.get(
                "/news/details?id=1", headers={"Accept-Language": "de"}
            )
        assert r.status_code == 200
        assert "article-body" in r.text
        assert "Full article content." in r.text

    async def test_v1_path_works(self, client: AsyncClient) -> None:
        with patch("src.api.news.cache.get_async", _cache_returning(None)):
            r = await client.get("/v1/news/details?id=9999")
        assert r.status_code == 200
        assert "error-owl" in r.text


# ---------------------------------------------------------------------------
# Events detail
# ---------------------------------------------------------------------------


class TestEventsDetail:
    async def test_unknown_id_returns_error_html(self, client: AsyncClient) -> None:
        with patch("src.api.events.cache.get_async", _cache_returning(None)):
            r = await client.get("/events/details?id=9999")
        assert r.status_code == 200
        assert r.headers["content-type"].startswith("text/html")
        assert "error-owl" in r.text

    async def test_known_id_no_cached_body_returns_rss_fallback(
        self, client: AsyncClient
    ) -> None:
        side_effects = {
            "events:de": _EVENTS_FEED,
            "article_body:10:de": None,
        }

        async def _cache_side_effect(key: str) -> object:
            return side_effects.get(key)

        with (
            patch("src.api.events.cache.get_async", side_effect=_cache_side_effect),
            patch("src.api.events.scrape_and_cache_article"),
        ):
            r = await client.get(
                "/events/details?id=10", headers={"Accept-Language": "de"}
            )
        assert r.status_code == 200
        assert "Event A" in r.text
        assert "summary" in r.text

    async def test_known_id_with_cached_body_returns_full_article(
        self, client: AsyncClient
    ) -> None:
        side_effects = {
            "events:de": _EVENTS_FEED,
            "article_body:10:de": "<p>Full event description.</p>",
        }

        async def _cache_side_effect(key: str) -> object:
            return side_effects.get(key)

        with patch("src.api.events.cache.get_async", side_effect=_cache_side_effect):
            r = await client.get(
                "/events/details?id=10", headers={"Accept-Language": "de"}
            )
        assert r.status_code == 200
        assert "article-body" in r.text
        assert "Full event description." in r.text
