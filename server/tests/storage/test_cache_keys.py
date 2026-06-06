from __future__ import annotations

from src.storage import cache_keys


def test_news_key_format() -> None:
    assert cache_keys.news("de") == "news:de"


def test_events_key_format() -> None:
    assert cache_keys.events("en") == "events:en"


def test_mensa_menu_key_format() -> None:
    assert cache_keys.mensa_menu("sb", "de") == "mensa:sb:de"


def test_mensa_meal_key_format() -> None:
    assert cache_keys.mensa_meal("hom", "fr") == "mensa:meal:hom:fr"


def test_mensa_filters_key_format() -> None:
    assert cache_keys.mensa_filters("de") == "mensa:filters:de"


def test_mensa_info_key_format() -> None:
    assert cache_keys.mensa_info("sb", "en") == "mensa:info:sb:en"


def test_helpful_numbers_key_format() -> None:
    assert cache_keys.helpful_numbers("de") == "helpful_numbers:de"


def test_more_key_format() -> None:
    assert cache_keys.more("fr") == "more:fr"


def test_article_body_key_format() -> None:
    assert cache_keys.article_body(42, "de") == "article_body:42:de"


def test_campus_map_key_is_stable() -> None:
    assert cache_keys.campus_map() == "map"


def test_scheduler_status_key_is_stable() -> None:
    assert cache_keys.scheduler_status() == "scheduler:status"


def test_scheduler_last_run_key_format() -> None:
    assert cache_keys.scheduler_last_run("mensa") == "scheduler:last_run:mensa"


def test_keys_are_distinct() -> None:
    keys = [
        cache_keys.news("de"),
        cache_keys.events("de"),
        cache_keys.mensa_menu("sb", "de"),
        cache_keys.mensa_meal("sb", "de"),
        cache_keys.mensa_filters("de"),
        cache_keys.mensa_info("sb", "de"),
        cache_keys.helpful_numbers("de"),
        cache_keys.more("de"),
        cache_keys.campus_map(),
        cache_keys.scheduler_status(),
    ]
    assert len(keys) == len(set(keys)), "cache key collision detected"
