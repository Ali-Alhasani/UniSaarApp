from __future__ import annotations

from typing import Protocol

from src.models.category import Category
from src.models.event import EventItem


class _HasCategories(Protocol):
    categories: list[Category]


def apply_neg_filter[T: _HasCategories](
    items: list[T], neg_filter: list[int]
) -> list[T]:
    """Excludes items only when ALL their categories are in the neg set.
    Matches existing iOS filtering contract."""
    if not neg_filter:
        return items
    neg_set = set(neg_filter)
    return [
        it
        for it in items
        if not (it.categories and all(c.id in neg_set for c in it.categories))
    ]


def paginate_items[T: _HasCategories](
    items: list[T], page: int, page_size: int
) -> tuple[list[T], bool]:
    """0-indexed pagination. page=0 is the first page."""
    start = page * page_size
    end = start + page_size
    return items[start:end], end < len(items)


def filter_events_by_month(
    items: list[EventItem], year: int, month: int
) -> list[EventItem]:
    return [
        it
        for it in items
        if it.happening_date is not None
        and it.happening_date.year == year
        and it.happening_date.month == month
    ]
