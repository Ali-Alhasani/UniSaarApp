from __future__ import annotations

from datetime import date

from src.models.category import Category
from src.models.event import EventItem
from src.models.news import NewsItem
from src.services.feed_service import (
    apply_neg_filter,
    filter_events_by_month,
    paginate_items,
)


def _cat(*ids: int) -> list[Category]:
    return [Category(id=i, name=str(i)) for i in ids]


def _news(item_id: int, *cat_ids: int) -> NewsItem:
    return NewsItem(
        id=item_id,
        title="t",
        description="d",
        link="http://example.com",
        categories=_cat(*cat_ids),
    )


def _event(
    item_id: int, *cat_ids: int, happening_date: date | None = None
) -> EventItem:
    return EventItem(
        id=item_id,
        title="t",
        description="d",
        link="http://example.com",
        categories=_cat(*cat_ids),
        happening_date=happening_date,
    )


# ── apply_neg_filter ──────────────────────────────────────────────────────────


class TestApplyNegFilter:
    def test_empty_neg_filter_returns_all(self) -> None:
        items = [_news(1, 10), _news(2, 20)]
        assert apply_neg_filter(items, []) == items

    def test_item_with_no_categories_is_kept(self) -> None:
        item = _news(1)
        assert apply_neg_filter([item], [99]) == [item]

    def test_item_excluded_only_when_all_categories_match(self) -> None:
        # Both cats in neg set → excluded
        excluded = _news(1, 10, 20)
        # One cat NOT in neg set → kept
        kept = _news(2, 10, 30)
        result = apply_neg_filter([excluded, kept], [10, 20])
        assert result == [kept]

    def test_partial_category_match_keeps_item(self) -> None:
        item = _news(1, 10, 20)
        # Only one of the two cats is filtered → kept
        assert apply_neg_filter([item], [10]) == [item]

    def test_single_category_item_excluded_when_matched(self) -> None:
        item = _news(1, 5)
        assert apply_neg_filter([item], [5]) == []

    def test_multiple_items_mixed(self) -> None:
        items = [_news(1, 1, 2), _news(2, 2, 3), _news(3, 1, 2, 3)]
        result = apply_neg_filter(items, [1, 2])
        # item 1: cats {1,2} all in neg → excluded
        # item 2: cats {2,3}, 3 not in neg → kept
        # item 3: cats {1,2,3}, 3 not in neg → kept
        assert [i.id for i in result] == [2, 3]


# ── paginate_items ────────────────────────────────────────────────────────────


class TestPaginateItems:
    def test_first_page_zero_indexed(self) -> None:
        items = [_news(i) for i in range(5)]
        page, has_next = paginate_items(items, page=0, page_size=2)
        assert [i.id for i in page] == [0, 1]
        assert has_next is True

    def test_second_page(self) -> None:
        items = [_news(i) for i in range(5)]
        page, has_next = paginate_items(items, page=1, page_size=2)
        assert [i.id for i in page] == [2, 3]
        assert has_next is True

    def test_last_page_has_no_next(self) -> None:
        items = [_news(i) for i in range(4)]
        page, has_next = paginate_items(items, page=1, page_size=2)
        assert [i.id for i in page] == [2, 3]
        assert has_next is False

    def test_page_beyond_end_returns_empty(self) -> None:
        items = [_news(i) for i in range(3)]
        page, has_next = paginate_items(items, page=5, page_size=10)
        assert page == []
        assert has_next is False

    def test_exact_page_boundary(self) -> None:
        # 6 items, page_size=3: last valid page is page=1 (start=3).
        # page=2 would start at index 6 — out of bounds.
        items = [_news(i) for i in range(6)]
        page, has_next = paginate_items(items, page=1, page_size=3)
        assert [i.id for i in page] == [3, 4, 5]
        assert has_next is False

    def test_empty_list(self) -> None:
        page, has_next = paginate_items([], page=0, page_size=10)
        assert page == []
        assert has_next is False


# ── filter_events_by_month ────────────────────────────────────────────────────


class TestFilterEventsByMonth:
    def test_matching_month_included(self) -> None:
        ev = _event(1, happening_date=date(2024, 3, 15))
        assert filter_events_by_month([ev], 2024, 3) == [ev]

    def test_different_month_excluded(self) -> None:
        ev = _event(1, happening_date=date(2024, 4, 1))
        assert filter_events_by_month([ev], 2024, 3) == []

    def test_different_year_excluded(self) -> None:
        ev = _event(1, happening_date=date(2023, 3, 15))
        assert filter_events_by_month([ev], 2024, 3) == []

    def test_none_date_excluded(self) -> None:
        ev = _event(1, happening_date=None)
        assert filter_events_by_month([ev], 2024, 3) == []

    def test_mixed_events(self) -> None:
        march = _event(1, happening_date=date(2024, 3, 10))
        april = _event(2, happening_date=date(2024, 4, 1))
        no_date = _event(3, happening_date=None)
        result = filter_events_by_month([march, april, no_date], 2024, 3)
        assert result == [march]
