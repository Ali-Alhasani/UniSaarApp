from __future__ import annotations

from datetime import UTC, datetime, timedelta
from pathlib import Path
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from apscheduler.schedulers.asyncio import AsyncIOScheduler

from src.core.constants import MENSA_LANGUAGES, MENSA_LOCATIONS
from src.models.mensa import MensaMenu
from src.services.scheduler import (
    _initialize,
    _is_mensa_stale,
    _run_helpful_numbers_job,
    _run_map_job,
    _run_mensa_job,
    _run_news_job,
    run_all_jobs_once,
)
from src.storage.cache import CacheClient

_ALL_MENSA_KEYS = [
    f"mensa:{loc}:{lang}" for loc in MENSA_LOCATIONS for lang in MENSA_LANGUAGES
]


def _mock_feed(data: dict[str, object] | None = None) -> MagicMock:
    feed = MagicMock()
    feed.model_dump.return_value = data or {}
    return feed


def _mock_news_scraper(feed: MagicMock) -> AsyncMock:
    scraper = AsyncMock()
    scraper.__aenter__ = AsyncMock(return_value=scraper)
    scraper.__aexit__ = AsyncMock(return_value=False)
    scraper.fetch_news.return_value = feed
    scraper.fetch_events.return_value = feed
    return scraper


def _mock_mensa_scraper(feed: MagicMock | None = None) -> AsyncMock:  # noqa: ARG001
    scraper = AsyncMock()
    scraper.__aenter__ = AsyncMock(return_value=scraper)
    scraper.__aexit__ = AsyncMock(return_value=False)
    # Return a real MensaMenu so _merge_mensa_menus can iterate days/fields.
    scraper.fetch_menu.return_value = MensaMenu(
        days=[], filters_last_changed="2026-01-01T00:00:00Z"
    )
    # get_meal_details and build_filters are synchronous methods
    scraper.get_meal_details = MagicMock(return_value={})
    scraper.build_filters = MagicMock(
        return_value=_mock_feed({"locations": [], "notices": []})
    )
    return scraper


async def _seed_all_mensa_keys(cache: CacheClient) -> None:
    for key in _ALL_MENSA_KEYS:
        await cache.set_async(key, {"days": [{"date": "last week"}]})


# --- _is_mensa_stale ---
# Mensa menus are date-bound — serving last week's schedule is actively
# misleading. These tests guard the staleness decision that controls whether
# a failed scrape clears the cache or leaves it intact.


def test_is_mensa_stale_returns_true_for_none() -> None:
    # No prior run recorded → treat as stale so routes return "unavailable"
    # rather than serving whatever happens to be in cache.
    assert _is_mensa_stale(None) is True


def test_is_mensa_stale_returns_true_for_yesterday() -> None:
    yesterday = (datetime.now(UTC) - timedelta(days=1)).strftime("%Y-%m-%dT%H:%M:%SZ")
    assert _is_mensa_stale(yesterday) is True


def test_is_mensa_stale_returns_true_for_last_week() -> None:
    last_week = (datetime.now(UTC) - timedelta(days=7)).strftime("%Y-%m-%dT%H:%M:%SZ")
    assert _is_mensa_stale(last_week) is True


def test_is_mensa_stale_returns_false_for_today() -> None:
    # A scrape that ran earlier today is still valid — the menu hasn't changed.
    now = datetime.now(UTC).strftime("%Y-%m-%dT%H:%M:%SZ")
    assert _is_mensa_stale(now) is False


def test_is_mensa_stale_returns_true_for_invalid_string() -> None:
    # Corrupt cache value must not crash — treat as stale and clear.
    assert _is_mensa_stale("not-a-date") is True


# --- _run_news_job ---


async def test_news_job_writes_all_language_cache_keys(tmp_path: Path) -> None:
    cache = CacheClient(cache_dir=str(tmp_path))
    scraper = _mock_news_scraper(_mock_feed({"items": []}))
    with patch("src.services.scheduler.NewsAndEventsScraper", return_value=scraper):
        await _run_news_job(cache)
    for lang in ("de", "en", "fr"):
        assert await cache.get_async(f"news:{lang}") == {"items": []}
        assert await cache.get_async(f"events:{lang}") == {"items": []}


async def test_news_job_writes_heartbeat(tmp_path: Path) -> None:
    cache = CacheClient(cache_dir=str(tmp_path))
    scraper = _mock_news_scraper(_mock_feed())
    with patch("src.services.scheduler.NewsAndEventsScraper", return_value=scraper):
        await _run_news_job(cache)
    heartbeat = await cache.get_async("scheduler:last_run:news")
    assert heartbeat is not None
    assert heartbeat.endswith("Z")


async def test_news_job_failure_preserves_existing_cache(tmp_path: Path) -> None:
    # News failure must leave the last successful feed intact — yesterday's
    # headlines are still more useful than an empty response.
    cache = CacheClient(cache_dir=str(tmp_path))
    await cache.set_async("news:de", {"items": ["old"]})

    scraper = AsyncMock()
    scraper.__aenter__ = AsyncMock(return_value=scraper)
    scraper.__aexit__ = AsyncMock(return_value=False)
    scraper.fetch_news.side_effect = Exception("network error")

    with (
        patch("src.services.scheduler.NewsAndEventsScraper", return_value=scraper),
        pytest.raises(Exception, match="network error"),
    ):
        await _run_news_job(cache)

    assert await cache.get_async("news:de") == {"items": ["old"]}
    # Heartbeat must not advance — a failed run did not produce fresh data.
    assert await cache.get_async("scheduler:last_run:news") is None


# --- _run_mensa_job ---


async def test_mensa_job_writes_all_location_language_keys(tmp_path: Path) -> None:
    cache = CacheClient(cache_dir=str(tmp_path))
    scraper = _mock_mensa_scraper(_mock_feed({"days": []}))
    with (
        patch("src.services.scheduler.MensaScraper", return_value=scraper),
        patch("src.services.scheduler.MensaInfoService") as MockInfo,
    ):
        MockInfo.return_value.load.return_value = None
        await _run_mensa_job(cache)
    for key in _ALL_MENSA_KEYS:
        assert await cache.get_async(key) is not None
    assert await cache.get_async("scheduler:last_run:mensa") is not None


async def test_mensa_job_failure_clears_all_stale_keys(tmp_path: Path) -> None:
    # If the last successful scrape was a previous day, every location/language
    # key must be cleared so routes return "unavailable" rather than serving
    # last week's schedule. All 12 keys are pre-seeded to ensure the clear
    # actually fires for each one, not just the ones that happen to be missing.
    cache = CacheClient(cache_dir=str(tmp_path))
    yesterday = (datetime.now(UTC) - timedelta(days=1)).strftime("%Y-%m-%dT%H:%M:%SZ")
    await cache.set_async("scheduler:last_run:mensa", yesterday)
    await _seed_all_mensa_keys(cache)

    failing_scraper = AsyncMock()
    failing_scraper.__aenter__ = AsyncMock(return_value=failing_scraper)
    failing_scraper.__aexit__ = AsyncMock(return_value=False)
    failing_scraper.fetch_menu.side_effect = Exception("mensa down")

    with (
        patch("src.services.scheduler.MensaScraper", return_value=failing_scraper),
        patch("src.services.scheduler.MensaInfoService"),
        pytest.raises(Exception, match="mensa down"),
    ):
        await _run_mensa_job(cache)

    for key in _ALL_MENSA_KEYS:
        assert await cache.get_async(key) is None
    # Heartbeat must not advance after a failed run.
    assert await cache.get_async("scheduler:last_run:mensa") == yesterday


async def test_mensa_job_failure_clears_cache_when_no_prior_run(
    tmp_path: Path,
) -> None:
    # First-ever cold start: scraper fails before writing any data.
    # No last_run key exists — _is_mensa_stale(None) must trigger the clear
    # path, even though there was nothing to clear in this case.
    cache = CacheClient(cache_dir=str(tmp_path))
    await _seed_all_mensa_keys(cache)  # simulate orphaned cache with no run record

    failing_scraper = AsyncMock()
    failing_scraper.__aenter__ = AsyncMock(return_value=failing_scraper)
    failing_scraper.__aexit__ = AsyncMock(return_value=False)
    failing_scraper.fetch_menu.side_effect = Exception("first run failed")

    with (
        patch("src.services.scheduler.MensaScraper", return_value=failing_scraper),
        patch("src.services.scheduler.MensaInfoService"),
        pytest.raises(Exception, match="first run failed"),
    ):
        await _run_mensa_job(cache)

    for key in _ALL_MENSA_KEYS:
        assert await cache.get_async(key) is None


async def test_mensa_job_failure_preserves_fresh_cache(tmp_path: Path) -> None:
    # If the last successful scrape was earlier today (e.g. 06:00 cron ran
    # fine, but a retry at 06:05 hits a brief outage), keep the morning data.
    # Clearing it would leave users with nothing for the rest of the day.
    cache = CacheClient(cache_dir=str(tmp_path))
    today = datetime.now(UTC).strftime("%Y-%m-%dT%H:%M:%SZ")
    await cache.set_async("scheduler:last_run:mensa", today)
    await _seed_all_mensa_keys(cache)

    failing_scraper = AsyncMock()
    failing_scraper.__aenter__ = AsyncMock(return_value=failing_scraper)
    failing_scraper.__aexit__ = AsyncMock(return_value=False)
    failing_scraper.fetch_menu.side_effect = Exception("brief outage")

    with (
        patch("src.services.scheduler.MensaScraper", return_value=failing_scraper),
        patch("src.services.scheduler.MensaInfoService"),
        pytest.raises(Exception, match="brief outage"),
    ):
        await _run_mensa_job(cache)

    for key in _ALL_MENSA_KEYS:
        assert await cache.get_async(key) == {"days": [{"date": "last week"}]}
    # Heartbeat must remain at today's value — not wiped by the failed retry.
    assert await cache.get_async("scheduler:last_run:mensa") == today


# --- _run_helpful_numbers_job ---


async def test_helpful_numbers_job_writes_all_language_cache_keys(
    tmp_path: Path,
) -> None:
    cache = CacheClient(cache_dir=str(tmp_path))
    mock_data = _mock_feed({"numbers": []})
    with (
        patch("src.services.scheduler.HelpfulNumbersService") as MockService,
        patch("src.services.scheduler.MoreLinksService") as MockMore,
    ):
        MockService.return_value.load.return_value = mock_data
        MockMore.return_value.load.return_value = _mock_feed({"links": []})
        await _run_helpful_numbers_job(cache)
    for lang in ("de", "en", "fr"):
        assert await cache.get_async(f"helpful_numbers:{lang}") == {"numbers": []}


async def test_helpful_numbers_job_writes_heartbeat(tmp_path: Path) -> None:
    cache = CacheClient(cache_dir=str(tmp_path))
    with (
        patch("src.services.scheduler.HelpfulNumbersService") as MockService,
        patch("src.services.scheduler.MoreLinksService") as MockMore,
    ):
        MockService.return_value.load.return_value = _mock_feed()
        MockMore.return_value.load.return_value = _mock_feed()
        await _run_helpful_numbers_job(cache)
    heartbeat = await cache.get_async("scheduler:last_run:helpful_numbers")
    assert heartbeat is not None
    assert heartbeat.endswith("Z")


async def test_helpful_numbers_job_partial_failure_preserves_written_keys(
    tmp_path: Path,
) -> None:
    # If de loads successfully but en raises, the de key is already written
    # and must be retained. The heartbeat must not be written since the
    # job did not complete successfully.
    cache = CacheClient(cache_dir=str(tmp_path))
    de_data = _mock_feed({"numbers": [{"name": "Emergency", "number": "110"}]})

    def _load_side_effect(lang: str) -> MagicMock:
        if lang == "de":
            return de_data
        raise Exception(f"load failed for {lang}")

    with (
        patch("src.services.scheduler.HelpfulNumbersService") as MockService,
        patch("src.services.scheduler.MoreLinksService") as MockMore,
    ):
        MockService.return_value.load.side_effect = _load_side_effect
        MockMore.return_value.load.return_value = _mock_feed()
        with pytest.raises(Exception, match="load failed for en"):
            await _run_helpful_numbers_job(cache)

    assert await cache.get_async("helpful_numbers:de") == {
        "numbers": [{"name": "Emergency", "number": "110"}]
    }
    assert await cache.get_async("helpful_numbers:en") is None
    assert await cache.get_async("scheduler:last_run:helpful_numbers") is None


# --- _run_map_job ---


async def test_map_job_writes_cache_and_heartbeat(tmp_path: Path) -> None:
    cache = CacheClient(cache_dir=str(tmp_path))
    mock_map_data = _mock_feed({"mapInfo": []})
    with patch("src.services.scheduler.MapService") as MockMapService:
        MockMapService.return_value.load.return_value = mock_map_data
        await _run_map_job(cache)
    assert await cache.get_async("map") == {"mapInfo": []}
    assert await cache.get_async("scheduler:last_run:map") is not None


# --- run_all_jobs_once ---


async def test_run_all_jobs_once_does_not_raise_when_all_jobs_fail(
    tmp_path: Path,
) -> None:
    # The worker process must not crash-loop when the university is unreachable.
    # Every job failure is caught individually so _initialize can still write
    # scheduler:status = "ready" and unblock the web container health check.
    cache = CacheClient(cache_dir=str(tmp_path))

    failing_scraper = AsyncMock()
    failing_scraper.__aenter__ = AsyncMock(return_value=failing_scraper)
    failing_scraper.__aexit__ = AsyncMock(return_value=False)
    failing_scraper.fetch_news.side_effect = Exception("down")
    failing_scraper.fetch_events.side_effect = Exception("down")
    failing_scraper.fetch_menu.side_effect = Exception("down")

    _news = "src.services.scheduler.NewsAndEventsScraper"
    _mensa = "src.services.scheduler.MensaScraper"
    with (
        patch(_news, return_value=failing_scraper),
        patch(_mensa, return_value=failing_scraper),
        patch("src.services.scheduler.HelpfulNumbersService") as MockHN,
        patch("src.services.scheduler.MapService") as MockMap,
        patch("src.services.scheduler.MensaInfoService"),
        patch("src.services.scheduler.MoreLinksService") as MockMore,
    ):
        MockHN.return_value.load.side_effect = Exception("down")
        MockMap.return_value.load.side_effect = Exception("down")
        MockMore.return_value.load.side_effect = Exception("down")
        await run_all_jobs_once(cache)  # must not raise


async def test_run_all_jobs_once_continues_after_single_job_failure(
    tmp_path: Path,
) -> None:
    # A network failure for one endpoint (e.g. news) must not prevent the
    # other jobs (mensa, helpful numbers, map) from running and writing cache.
    cache = CacheClient(cache_dir=str(tmp_path))

    failing_news = AsyncMock()
    failing_news.__aenter__ = AsyncMock(return_value=failing_news)
    failing_news.__aexit__ = AsyncMock(return_value=False)
    failing_news.fetch_news.side_effect = Exception("news down")

    working_mensa = _mock_mensa_scraper(_mock_feed({"days": []}))

    with (
        patch("src.services.scheduler.NewsAndEventsScraper", return_value=failing_news),
        patch("src.services.scheduler.MensaScraper", return_value=working_mensa),
        patch("src.services.scheduler.HelpfulNumbersService") as MockHN,
        patch("src.services.scheduler.MapService") as MockMap,
        patch("src.services.scheduler.MensaInfoService") as MockInfo,
        patch("src.services.scheduler.MoreLinksService") as MockMore,
    ):
        MockHN.return_value.load.return_value = _mock_feed()
        MockMap.return_value.load.return_value = _mock_feed()
        MockInfo.return_value.load.return_value = None
        MockMore.return_value.load.return_value = _mock_feed()
        await run_all_jobs_once(cache)

    assert await cache.get_async("mensa:sb:de") is not None


# --- _initialize ---


async def test_initialize_writes_ready_status_after_successful_startup(
    tmp_path: Path,
) -> None:
    # scheduler:status = "ready" is the signal the Docker health check polls.
    # The web container blocks on it before accepting traffic.
    cache = CacheClient(cache_dir=str(tmp_path))
    scheduler = AsyncIOScheduler()
    scraper = _mock_news_scraper(_mock_feed())
    working_mensa = _mock_mensa_scraper(_mock_feed())
    with (
        patch("src.services.scheduler.NewsAndEventsScraper", return_value=scraper),
        patch("src.services.scheduler.MensaScraper", return_value=working_mensa),
        patch("src.services.scheduler.HelpfulNumbersService") as MockHN,
        patch("src.services.scheduler.MapService") as MockMap,
        patch("src.services.scheduler.MensaInfoService") as MockInfo,
        patch("src.services.scheduler.MoreLinksService") as MockMore,
    ):
        MockHN.return_value.load.return_value = _mock_feed()
        MockMap.return_value.load.return_value = _mock_feed()
        MockInfo.return_value.load.return_value = None
        MockMore.return_value.load.return_value = _mock_feed()
        await _initialize(cache, scheduler)
    scheduler.shutdown(wait=False)
    assert await cache.get_async("scheduler:status") == "ready"


async def test_initialize_writes_ready_status_even_when_all_jobs_fail(
    tmp_path: Path,
) -> None:
    # Even if every scraper is unreachable on cold start, the worker must still
    # write "ready" so the web container can start up and serve any cached data
    # that survived from a previous deployment. Blocking the web container
    # indefinitely would cause a full outage on every cold start.
    cache = CacheClient(cache_dir=str(tmp_path))
    scheduler = AsyncIOScheduler()

    failing_scraper = AsyncMock()
    failing_scraper.__aenter__ = AsyncMock(return_value=failing_scraper)
    failing_scraper.__aexit__ = AsyncMock(return_value=False)
    failing_scraper.fetch_news.side_effect = Exception("down")
    failing_scraper.fetch_events.side_effect = Exception("down")
    failing_scraper.fetch_menu.side_effect = Exception("down")

    _news = "src.services.scheduler.NewsAndEventsScraper"
    _mensa = "src.services.scheduler.MensaScraper"
    with (
        patch(_news, return_value=failing_scraper),
        patch(_mensa, return_value=failing_scraper),
        patch("src.services.scheduler.HelpfulNumbersService") as MockHN,
        patch("src.services.scheduler.MapService") as MockMap,
        patch("src.services.scheduler.MensaInfoService"),
        patch("src.services.scheduler.MoreLinksService") as MockMore,
    ):
        MockHN.return_value.load.side_effect = Exception("down")
        MockMap.return_value.load.side_effect = Exception("down")
        MockMore.return_value.load.side_effect = Exception("down")
        await _initialize(cache, scheduler)
    scheduler.shutdown(wait=False)
    assert await cache.get_async("scheduler:status") == "ready"
