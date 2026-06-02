from __future__ import annotations

import asyncio
import types
from typing import Any, Self

import httpx
from loguru import logger

from src.core.config import settings


class ScraperError(Exception):
    pass


class BaseScraper:
    _MAX_RETRIES = 3
    _BACKOFF_BASE = 1.0  # seconds

    def __init__(self) -> None:
        proxy = settings.proxy_url or None
        self._client = httpx.AsyncClient(
            proxy=proxy,
            timeout=30.0,
            follow_redirects=True,
        )

    async def __aenter__(self) -> Self:
        return self

    async def __aexit__(
        self,
        exc_type: type[BaseException] | None,
        exc_val: BaseException | None,
        exc_tb: types.TracebackType | None,
    ) -> None:
        await self._client.aclose()

    async def fetch(self, url: str) -> str:
        for attempt in range(self._MAX_RETRIES):
            try:
                response = await self._client.get(url)
                response.raise_for_status()
                html = response.text
                # German pages sometimes serve ISO-8859-1/Windows-1252 with a wrong
                # UTF-8 charset header. Try both common encodings before giving up.
                if "â€" in html or "Ã" in html:
                    for enc in ("iso-8859-1", "cp1252"):
                        try:
                            candidate = response.content.decode(enc)
                            if "â€" not in candidate and "Ã" not in candidate:
                                html = candidate
                                break
                        except (UnicodeDecodeError, LookupError):
                            pass
                return html
            except httpx.HTTPError as exc:
                if attempt == self._MAX_RETRIES - 1:
                    raise ScraperError(
                        f"All {self._MAX_RETRIES} attempts failed for {url}"
                    ) from exc
                wait = self._BACKOFF_BASE * (2**attempt)
                logger.warning(
                    "Attempt {}/{} failed for {}: {}. Retrying in {:.1f}s",
                    attempt + 1,
                    self._MAX_RETRIES,
                    url,
                    exc,
                    wait,
                )
                await asyncio.sleep(wait)
        raise ScraperError("No attempts made")  # unreachable

    @staticmethod
    def clean_text(node: Any) -> str:
        return str(node.text(deep=True)).strip().replace("\xa0", " ")
