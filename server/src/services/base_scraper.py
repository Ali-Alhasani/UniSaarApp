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
    _HEADERS = {
        "User-Agent": (
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
            "AppleWebKit/537.36 (KHTML, like Gecko) "
            "Chrome/125.0.0.0 Safari/537.36"
        ),
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "de,en;q=0.9",
    }

    def __init__(self) -> None:
        proxy = settings.proxy_url or None
        self._client = httpx.AsyncClient(
            proxy=proxy,
            timeout=settings.http_timeout_seconds,
            follow_redirects=True,
            headers=self._HEADERS,
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
                encoding_used = response.encoding or "utf-8"
                # German pages sometimes serve ISO-8859-1/Windows-1252 with a wrong
                # UTF-8 charset header. Try both common encodings before giving up.
                if "â€" in html or "Ã" in html:
                    for enc in ("iso-8859-1", "cp1252"):
                        try:
                            candidate = response.content.decode(enc)
                            if "â€" not in candidate and "Ã" not in candidate:
                                html = candidate
                                encoding_used = enc
                                break
                        except (UnicodeDecodeError, LookupError):
                            pass
                _html_len = len(html)
                logger.opt(lazy=True).trace(
                    "[fetch] url={} status={} encoding={} size={}b",
                    lambda _u=url: _u,
                    lambda _s=response.status_code: _s,
                    lambda _e=encoding_used: _e,
                    lambda _l=_html_len: _l,
                )
                return html
            except httpx.HTTPError as exc:
                if attempt == self._MAX_RETRIES - 1:
                    raise ScraperError(
                        f"All {self._MAX_RETRIES} attempts failed for {url}"
                    ) from exc
                wait = self._BACKOFF_BASE * (2**attempt)
                exc_msg = str(exc).strip() or type(exc).__name__
                logger.warning(
                    "Attempt {}/{} failed for {}: {}. Retrying in {:.1f}s",
                    attempt + 1,
                    self._MAX_RETRIES,
                    url,
                    exc_msg,
                    wait,
                )
                await asyncio.sleep(wait)
        raise ScraperError("No attempts made")  # unreachable

    @staticmethod
    def clean_text(node: Any) -> str:
        return str(node.text(deep=True)).strip().replace("\xa0", " ")
