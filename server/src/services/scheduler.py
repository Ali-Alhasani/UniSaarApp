from __future__ import annotations

import asyncio
import signal
from collections.abc import Awaitable, Callable
from datetime import UTC, datetime
from typing import Any

import sentry_sdk
from apscheduler.events import EVENT_JOB_ERROR
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
from loguru import logger

from src.core.config import settings
from src.core.constants import (
    MENSA_CAMPUS_LOCATIONS,
    SUPPORTED_LANGUAGES,
)
from src.core.enums import Language
from src.core.logging import setup_logging
from src.core.meal_id import CAMPUS_SOURCES
from src.models.mensa import MensaDay, MensaMealDetail, MensaMenu
from src.services.helpful_numbers_service import HelpfulNumbersService
from src.services.map_service import MapService
from src.services.mensa_info_service import MensaInfoService
from src.services.mensa_scraper import MensaScraper
from src.services.more_links_service import MoreLinksService
from src.services.news_scraper import NewsAndEventsScraper
from src.storage import cache_keys
from src.storage.cache import CacheClient

_JobFn = Callable[[CacheClient], Awaitable[None]]


def _now_iso() -> str:
    return datetime.now(UTC).strftime("%Y-%m-%dT%H:%M:%SZ")


def _capture(exc: Exception) -> None:
    if settings.sentry_dsn.get_secret_value():
        sentry_sdk.capture_exception(exc)


def _is_mensa_stale(last_run_iso: str | None) -> bool:
    """Returns True if the last successful mensa scrape was not today (UTC).

    Mensa menus are date-bound — a schedule from a previous day has no value
    for users. Unlike news, stale mensa data should not be served.
    """
    if not isinstance(last_run_iso, str):
        return True
    try:
        last = datetime.fromisoformat(last_run_iso)
        return last.date() < datetime.now(UTC).date()
    except ValueError:
        return True


def _merge_mensa_menus(primary: MensaMenu, secondary: MensaMenu) -> MensaMenu:
    """Merge secondary days into primary by date.

    Days that share the same formatted date string have their meal lists
    concatenated (secondary appended after primary). Days present only in
    secondary (e.g. mensagarten dinner slots) are appended at the end in
    their original order.
    """
    days_by_date: dict[str, MensaDay] = {day.date: day for day in primary.days}
    secondary_only: list[MensaDay] = []
    for sec_day in secondary.days:
        if sec_day.date in days_by_date:
            pri_day = days_by_date[sec_day.date]
            days_by_date[sec_day.date] = MensaDay(
                date=pri_day.date, meals=pri_day.meals + sec_day.meals
            )
        else:
            secondary_only.append(sec_day)
    primary_days = [days_by_date[day.date] for day in primary.days]
    return MensaMenu(
        days=primary_days + secondary_only,
        filters_last_changed=primary.filters_last_changed,
    )


async def _run_news_job(cache: CacheClient) -> None:
    async with NewsAndEventsScraper() as scraper:
        for lang in SUPPORTED_LANGUAGES:
            feed = await scraper.fetch_news(lang)
            logger.info("fetched news:{} → {} items → cached", lang, len(feed.items))
            logger.trace(
                "parsed news:{} — first item: {}",
                lang,
                feed.items[0].model_dump(by_alias=True) if feed.items else None,
            )
            await cache.set_async(
                cache_keys.news(lang), feed.model_dump(by_alias=True, mode="json")
            )
            events = await scraper.fetch_events(lang)
            logger.info(
                "fetched events:{} → {} items → cached", lang, len(events.items)
            )
            logger.trace(
                "parsed events:{} — first item: {}",
                lang,
                events.items[0].model_dump(by_alias=True) if events.items else None,
            )
            await cache.set_async(
                cache_keys.events(lang), events.model_dump(by_alias=True, mode="json")
            )
    await cache.set_async(cache_keys.scheduler_last_run("news"), _now_iso())


async def _cache_mensa_for_lang(
    cache: CacheClient, scraper: MensaScraper, lang: Language
) -> None:
    for campus, sources in CAMPUS_SOURCES.items():
        campus_menu: MensaMenu | None = None
        campus_meal_details: dict[int, MensaMealDetail] = {}
        last_exc: Exception | None = None
        for source in sources:
            try:
                menu = await scraper.fetch_menu(source, lang)
            except Exception as exc:
                logger.warning(
                    "mensa:{}:{} — fetch failed, skipping: {}", source, lang, exc
                )
                last_exc = exc
                continue
            meal_details = scraper.get_meal_details()
            logger.info("fetched mensa:{}:{} → {} days", source, lang, len(menu.days))
            if campus_menu is None:
                campus_menu = menu
                campus_meal_details = dict(meal_details)
            else:
                campus_menu = _merge_mensa_menus(campus_menu, menu)
                campus_meal_details.update(meal_details)
                logger.info(
                    "merged mensa:{} into campus:{} → {} days",
                    source,
                    campus,
                    len(campus_menu.days),
                )
        if campus_menu is None and last_exc is not None:
            raise last_exc
        if campus_menu is not None:
            await cache.set_async(
                cache_keys.mensa_menu(campus, lang),
                campus_menu.model_dump(by_alias=True, mode="json"),
            )
            await cache.set_async(
                cache_keys.mensa_meal(campus, lang),
                {
                    str(k): v.model_dump(by_alias=True, mode="json")
                    for k, v in campus_meal_details.items()
                },
            )
    filters = scraper.build_filters()
    logger.trace(
        "built mensa:filters:{} → {} locations, {} notices → cached",
        lang,
        len(filters.locations),
        len(filters.notices),
    )
    await cache.set_async(
        cache_keys.mensa_filters(lang), filters.model_dump(by_alias=True, mode="json")
    )


async def _cache_mensa_info(cache: CacheClient) -> None:
    info_service = MensaInfoService()
    for campus in MENSA_CAMPUS_LOCATIONS:
        for lang in SUPPORTED_LANGUAGES:
            info = info_service.load(campus, lang)
            _outcome = "cached" if info is not None else "not found, skipped"
            logger.trace("read mensa:info:{}:{} → {}", campus, lang, _outcome)
            if info is not None:
                await cache.set_async(
                    cache_keys.mensa_info(campus, lang),
                    info.model_dump(by_alias=True, mode="json"),
                )


async def _run_mensa_job(cache: CacheClient) -> None:
    try:
        async with MensaScraper() as scraper:
            for lang in SUPPORTED_LANGUAGES:
                await _cache_mensa_for_lang(cache, scraper, lang)
        await _cache_mensa_info(cache)
    except Exception:
        last_run = await cache.get_async(cache_keys.scheduler_last_run("mensa"))
        if _is_mensa_stale(last_run):
            for campus in MENSA_CAMPUS_LOCATIONS:
                for lang in SUPPORTED_LANGUAGES:
                    await cache.set_async(cache_keys.mensa_menu(campus, lang), None)
                    await cache.set_async(cache_keys.mensa_meal(campus, lang), None)
        raise
    await cache.set_async(cache_keys.scheduler_last_run("mensa"), _now_iso())


async def _run_helpful_numbers_job(cache: CacheClient) -> None:
    service = HelpfulNumbersService()
    more_service = MoreLinksService()
    for lang in SUPPORTED_LANGUAGES:
        data = service.load(lang)
        logger.info(
            "loaded helpful_numbers:{} → {} entries → cached",
            lang,
            len(data.numbers),
        )
        await cache.set_async(
            cache_keys.helpful_numbers(lang),
            data.model_dump(by_alias=True, mode="json"),
        )
        more = more_service.load(lang)
        logger.info("loaded more:{} → {} links → cached", lang, len(more.links))
        logger.trace(
            "read more:{} — source last_changed={}",
            lang,
            more.links_last_changed,
        )
        await cache.set_async(
            cache_keys.more(lang),
            more.model_dump(by_alias=True, mode="json"),
        )
    await cache.set_async(cache_keys.scheduler_last_run("helpful_numbers"), _now_iso())


async def _run_map_job(cache: CacheClient) -> None:
    data = MapService().load()
    logger.info("loaded map → {} entries → cached", len(data.map_info))
    await cache.set_async(
        cache_keys.campus_map(), data.model_dump(by_alias=True, mode="json")
    )
    await cache.set_async(cache_keys.scheduler_last_run("map"), _now_iso())


async def run_all_jobs_once(cache: CacheClient) -> None:
    jobs: list[tuple[str, _JobFn]] = [
        ("news", _run_news_job),
        ("mensa", _run_mensa_job),
        ("helpful_numbers", _run_helpful_numbers_job),
        ("map", _run_map_job),
    ]
    for name, fn in jobs:
        logger.trace("dispatching job:{}", name)
        try:
            await fn(cache)
            logger.trace("job:{} finished", name)
        except Exception as exc:
            logger.error("job:{} raised during startup — {}", name, exc)
            _capture(exc)


async def _initialize(cache: CacheClient, scheduler: AsyncIOScheduler) -> None:
    """Run startup scrape and write ready status.

    Extracted so tests can verify the scheduler:status invariant without
    running the infinite event loop in main().
    """
    scheduler.start()
    logger.info("Scheduler started.")
    await run_all_jobs_once(cache)
    await cache.set_async(cache_keys.scheduler_status(), "ready")
    logger.info("Scheduler ready.")


async def main() -> None:
    setup_logging()
    if settings.sentry_dsn.get_secret_value():
        sentry_sdk.init(dsn=settings.sentry_dsn.get_secret_value())

    cache = CacheClient()

    # misfire_grace_period: if a job is still running when its next trigger fires,
    # allow up to 60s before treating the missed fire as skipped entirely.
    # max_instances=1: never queue a second run of the same job concurrently.
    scheduler = AsyncIOScheduler(
        job_defaults={"misfire_grace_period": 60, "max_instances": 1}
    )

    def _on_job_error(event: Any) -> None:
        logger.error("Scheduled job '{}' raised: {}", event.job_id, event.exception)
        _capture(event.exception)

    scheduler.add_listener(_on_job_error, EVENT_JOB_ERROR)

    scheduler.add_job(
        _run_news_job,
        "interval",
        minutes=settings.news_update_interval_min,
        args=[cache],
        id="news",
    )
    scheduler.add_job(
        _run_mensa_job,
        CronTrigger.from_crontab(settings.mensa_update_cron),
        args=[cache],
        id="mensa",
    )
    scheduler.add_job(
        _run_helpful_numbers_job,
        CronTrigger.from_crontab(settings.helpful_numbers_update_cron),
        args=[cache],
        id="helpful_numbers",
    )
    scheduler.add_job(
        _run_map_job,
        CronTrigger.from_crontab(settings.map_update_cron),
        args=[cache],
        id="map",
    )

    await _initialize(cache, scheduler)

    stop_event = asyncio.Event()
    loop = asyncio.get_running_loop()
    for sig in (signal.SIGTERM, signal.SIGINT):
        loop.add_signal_handler(sig, stop_event.set)

    try:
        await stop_event.wait()
    except asyncio.CancelledError:
        pass
    finally:
        scheduler.shutdown(wait=True)
        logger.info("Scheduler shut down.")


if __name__ == "__main__":
    asyncio.run(main())
