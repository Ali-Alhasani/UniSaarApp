"""Cache management CLI for UniSaarApp server.

Usage (after poetry install):
    poetry run manage status
    poetry run manage list
    poetry run manage get <key>
    poetry run manage clear
    poetry run manage clear <key>
"""

from __future__ import annotations

import argparse
import asyncio
import json
import sys
import time
from typing import Any

import diskcache
from loguru import logger

from src.core.config import settings
from src.core.constants import MENSA_LANGUAGES, MENSA_LOCATIONS, NEWSFEED_LANGUAGES

# ---------------------------------------------------------------------------
# All cache keys the scheduler is expected to populate
# ---------------------------------------------------------------------------

_SCHEDULER_KEYS = [
    "scheduler:status",
    "scheduler:last_run:news",
    "scheduler:last_run:mensa",
    "scheduler:last_run:helpful_numbers",
    "scheduler:last_run:map",
]

_DATA_KEYS: list[str] = (
    ["map"]
    + [f"news:{lang}" for lang in NEWSFEED_LANGUAGES]
    + [f"events:{lang}" for lang in NEWSFEED_LANGUAGES]
    + [f"helpful_numbers:{lang}" for lang in NEWSFEED_LANGUAGES]
    + [f"more:{lang}" for lang in NEWSFEED_LANGUAGES]
    + [f"mensa:{loc}:{lang}" for loc in MENSA_LOCATIONS for lang in MENSA_LANGUAGES]
    + [
        f"mensa:meal:{loc}:{lang}"
        for loc in MENSA_LOCATIONS
        for lang in MENSA_LANGUAGES
    ]
    + [f"mensa:filters:{lang}" for lang in MENSA_LANGUAGES]
    + [
        f"mensa:info:{loc}:{lang}"
        for loc in MENSA_LOCATIONS
        for lang in MENSA_LANGUAGES
    ]
)

ALL_EXPECTED_KEYS = _SCHEDULER_KEYS + _DATA_KEYS


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _open_cache() -> diskcache.Cache:
    return diskcache.Cache(directory=settings.cache_dir, timeout=10)


def _summarize(value: Any) -> str:
    if value is None:
        return "—"
    if isinstance(value, dict):
        return f"dict  {len(value)} keys"
    if isinstance(value, list):
        return f"list  {len(value)} items"
    if isinstance(value, str):
        return value[:60].strip()
    return repr(value)[:60]


def _tick(present: bool) -> str:
    return "✓" if present else "✗"


# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------


def cmd_config(_args: argparse.Namespace) -> None:
    """Show all resolved config values. Secrets are masked."""
    from pydantic import SecretStr

    print("\nConfig (loaded from .env + .secrets)\n")
    for field_name in settings.model_fields:
        value = getattr(settings, field_name)
        if isinstance(value, SecretStr):
            raw = value.get_secret_value()
            display = (
                f"{'*' * min(len(raw), 8)}  ({len(raw)} chars)" if raw else "NOT SET"
            )
        else:
            display = str(value)
        print(f"  {field_name:<35} {display}")
    print()


def cmd_status(_args: argparse.Namespace) -> None:
    """Show scheduler state and presence of every expected cache key."""
    cache = _open_cache()

    print(f"\nCache dir: {settings.cache_dir}\n")

    print("── Scheduler ───────────────────────────────────────────")
    for key in _SCHEDULER_KEYS:
        value = cache.get(key)
        mark = _tick(value is not None)
        print(f"  {mark}  {key:<45}  {_summarize(value)}")

    print("\n── Data keys ───────────────────────────────────────────")
    missing = 0
    for key in _DATA_KEYS:
        value = cache.get(key)
        present = value is not None
        if not present:
            missing += 1
        mark = _tick(present)
        print(f"  {mark}  {key:<45}  {_summarize(value)}")

    total = len(_DATA_KEYS)
    print(f"\n  {total - missing}/{total} data keys populated")
    if missing:
        print(f"  {missing} key(s) missing — run the worker to populate them\n")
    else:
        print("  Cache fully populated\n")

    cache.close()


def cmd_list(_args: argparse.Namespace) -> None:
    """List every key currently in the cache with a value summary."""
    cache = _open_cache()
    keys = list(cache)
    if not keys:
        print("Cache is empty.")
        cache.close()
        return

    print(f"\n{len(keys)} key(s) in cache ({settings.cache_dir}):\n")
    for key in sorted(keys):
        value = cache.get(key)
        print(f"  {key:<50}  {_summarize(value)}")
    print()
    cache.close()


def cmd_get(args: argparse.Namespace) -> None:
    """Pretty-print the JSON value stored under a cache key."""
    cache = _open_cache()
    value = cache.get(args.key)
    cache.close()

    if value is None:
        print(f"Key not found or empty: {args.key}", file=sys.stderr)
        sys.exit(1)

    print(json.dumps(value, indent=2, ensure_ascii=False, default=str))


def cmd_clear(args: argparse.Namespace) -> None:
    """Clear one key or the entire cache."""
    cache = _open_cache()

    if args.key:
        if cache.get(args.key) is None:
            print(f"Key not found: {args.key}")
            cache.close()
            return
        del cache[args.key]
        print(f"Cleared: {args.key}")
    else:
        if not args.yes:
            answer = input(
                f"Clear ALL keys in '{settings.cache_dir}'? "
                "This cannot be undone. Type 'yes' to confirm: "
            )
            if answer.strip().lower() != "yes":
                print("Aborted.")
                cache.close()
                return
        count = len(cache)
        cache.clear()
        print(f"Cleared {count} key(s) from cache.")

    cache.close()


# ---------------------------------------------------------------------------
# Run jobs on demand
# ---------------------------------------------------------------------------

_JOB_NAMES = ("news", "mensa", "helpful-numbers", "map", "all")


def cmd_run(args: argparse.Namespace) -> None:
    """Trigger one or all scraper jobs immediately, without restarting the scheduler."""
    from src.services.scheduler import (
        _run_helpful_numbers_job,
        _run_map_job,
        _run_mensa_job,
        _run_news_job,
    )
    from src.storage.cache import CacheClient

    logger.remove()
    logger.add(
        sys.stderr,
        level="INFO",
        format="{time:HH:mm:ss} | <level>{level: <8}</level> | {message}",
        colorize=True,
    )

    job_map: list[tuple[str, Any]] = [
        ("news", _run_news_job),
        ("mensa", _run_mensa_job),
        ("helpful-numbers", _run_helpful_numbers_job),
        ("map", _run_map_job),
    ]

    cache = CacheClient()

    async def _run_one(name: str, fn: Any) -> bool:
        logger.info("running job:{}", name)
        job_start = time.monotonic()
        try:
            await fn(cache)
            logger.info("job:{} done in {:.1f}s", name, time.monotonic() - job_start)
            return True
        except Exception as exc:
            logger.error(
                "job:{} failed in {:.1f}s — {}",
                name,
                time.monotonic() - job_start,
                exc,
            )
            return False

    async def _run() -> None:
        start = time.monotonic()
        if args.job == "all":
            failures = 0
            for name, fn in job_map:
                if not await _run_one(name, fn):
                    failures += 1
            elapsed = time.monotonic() - start
            if failures:
                logger.error(
                    "all jobs done in {:.1f}s — {} failure(s)",
                    elapsed,
                    failures,
                )
                sys.exit(1)
            else:
                logger.info("all jobs done in {:.1f}s", elapsed)
        else:
            fn = dict(job_map)[args.job]
            ok = await _run_one(args.job, fn)
            if not ok:
                sys.exit(1)

    asyncio.run(_run())


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------


def main() -> None:
    # Remove all loguru handlers so TRACE/DEBUG/INFO from the server runtime
    # (cache layer, diskcache, stdlib interceptor) don't pollute CLI output.
    # Only WARNING+ surfaces on stderr so real errors stay visible.
    logger.remove()
    logger.add(sys.stderr, level="WARNING", format="{level}: {message}", colorize=False)

    # Reconfigure stdout to UTF-8 so German umlauts (ä, ö, ü) and other
    # non-ASCII characters print as-is instead of being replaced with '?'.
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")

    parser = argparse.ArgumentParser(
        prog="manage",
        description="UniSaarApp server cache management",
    )
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("config", help="show resolved config values (secrets masked)")
    sub.add_parser("status", help="show scheduler state and key presence")
    sub.add_parser("list", help="list all keys currently in the cache")

    get_p = sub.add_parser("get", help="print the value of a cache key as JSON")
    get_p.add_argument("key", help="cache key (e.g. news:de, mensa:sb:de)")

    clear_p = sub.add_parser("clear", help="clear one key or the entire cache")
    clear_p.add_argument(
        "key", nargs="?", default=None, help="key to clear (omit to clear all)"
    )
    clear_p.add_argument("--yes", action="store_true", help="skip confirmation prompt")

    run_p = sub.add_parser("run", help="trigger a scraper job immediately")
    run_p.add_argument(
        "job",
        choices=_JOB_NAMES,
        help="job to run: news | mensa | helpful-numbers | map | all",
    )

    args = parser.parse_args()
    dispatch = {
        "config": cmd_config,
        "status": cmd_status,
        "list": cmd_list,
        "get": cmd_get,
        "clear": cmd_clear,
        "run": cmd_run,
    }
    dispatch[args.command](args)


if __name__ == "__main__":
    main()
