from __future__ import annotations

import asyncio
from typing import Any, TypeVar

import diskcache
import sentry_sdk
from loguru import logger
from pydantic import BaseModel, ValidationError

from src.core.config import settings

T = TypeVar("T", bound=BaseModel)


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

    async def set_async(self, key: str, value: Any, expire: int | None = None) -> None:
        # Snapshot summary before the await — captures object state at call time,
        # not whenever loguru decides to format the message.
        _snap = _summarize(value)
        await asyncio.to_thread(self._cache.set, key, value, expire)
        logger.opt(lazy=True).trace(
            "[cache] set key={} value={}",
            lambda _k=key: _k,
            lambda _s=_snap: _s,
        )

    async def get_model(self, key: str, model: type[T]) -> T | None:
        data = await self.get_async(key)
        if data is None:
            return None
        try:
            return model.model_validate(data)
        except ValidationError as exc:
            logger.error("Schema drift on cache key '{}': {}", key, exc)
            if settings.sentry_dsn.get_secret_value():
                sentry_sdk.capture_exception(exc)
            return None

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
