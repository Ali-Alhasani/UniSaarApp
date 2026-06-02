from __future__ import annotations

from pathlib import Path

from src.storage.cache import CacheClient


async def test_set_and_get_roundtrip(tmp_path: Path) -> None:
    cache = CacheClient(cache_dir=str(tmp_path))
    await cache.set_async("key", {"foo": "bar"})
    assert await cache.get_async("key") == {"foo": "bar"}


async def test_missing_key_returns_none(tmp_path: Path) -> None:
    # Routes treat None as "data unavailable" — a missing key must behave
    # identically to a key that was never written.
    cache = CacheClient(cache_dir=str(tmp_path))
    assert await cache.get_async("nonexistent") is None


async def test_set_none_is_indistinguishable_from_missing(tmp_path: Path) -> None:
    # The mensa stale-clearing path writes None to signal "unavailable".
    # Routes check `if data is None` — so an explicit None must read back
    # as None, not raise or return a sentinel object.
    cache = CacheClient(cache_dir=str(tmp_path))
    await cache.set_async("k", None)
    assert await cache.get_async("k") is None


async def test_overwrite_updates_value(tmp_path: Path) -> None:
    cache = CacheClient(cache_dir=str(tmp_path))
    await cache.set_async("k", "old")
    await cache.set_async("k", "new")
    assert await cache.get_async("k") == "new"


async def test_different_keys_are_independent(tmp_path: Path) -> None:
    cache = CacheClient(cache_dir=str(tmp_path))
    await cache.set_async("a", 1)
    await cache.set_async("b", 2)
    assert await cache.get_async("a") == 1
    assert await cache.get_async("b") == 2
