from __future__ import annotations

import asyncio
from typing import Any

import diskcache
from loguru import logger

from src.core.config import settings


def _summarize(value: Any) -> str:
    if value is None:
        return "None"
    if isinstance(value, dict):
        return f"dict({len(value)} keys)"
    if isinstance(value, list):
        return f"list({len(value)} items)"
    if isinstance(value, str):
        return f"str({len(value)}b)"
    return type(value).__name__


class CacheClient:
    def __init__(self, cache_dir: str | None = None) -> None:
        directory = cache_dir or settings.cache_dir
        # timeout=10 reduces SQLite lock contention under concurrent readers
        self._cache = diskcache.Cache(directory=directory, timeout=10)

    async def set_async(self, key: str, value: Any) -> None:
        # Snapshot summary before the await — captures object state at call time,
        # not whenever loguru decides to format the message.
        _snap = _summarize(value)
        await asyncio.to_thread(self._cache.set, key, value)
        logger.opt(lazy=True).trace(
            "[cache] set key={} value={}",
            lambda _k=key: _k,
            lambda _s=_snap: _s,
        )

    async def get_async(self, key: str) -> Any:
        value = await asyncio.to_thread(self._cache.get, key)
        # Snapshot immediately after the get — same reason.
        _snap = _summarize(value)
        _hit = value is not None
        logger.opt(lazy=True).trace(
            "[cache] get key={} hit={} value={}",
            lambda _k=key: _k,
            lambda _h=_hit: _h,
            lambda _s=_snap: _s,
        )
        return value


cache = CacheClient()
