from __future__ import annotations

from unittest.mock import AsyncMock, patch

import httpx
import pytest
import respx

from src.services.base_scraper import BaseScraper, ScraperError


async def test_fetch_returns_text_on_success() -> None:
    with respx.mock:
        respx.get("http://example.com/").mock(
            return_value=httpx.Response(200, text="hello world")
        )
        result = await BaseScraper().fetch("http://example.com/")
    assert result == "hello world"


async def test_fetch_raises_scraper_error_after_all_retries() -> None:
    with patch("asyncio.sleep", new_callable=AsyncMock), respx.mock:
        respx.get("http://example.com/").mock(side_effect=httpx.ConnectError("refused"))
        with pytest.raises(ScraperError):
            await BaseScraper().fetch("http://example.com/")


async def test_fetch_retries_and_succeeds_on_second_attempt() -> None:
    with patch("asyncio.sleep", new_callable=AsyncMock), respx.mock:
        route = respx.get("http://example.com/").mock(
            side_effect=[
                httpx.ConnectError("refused"),
                httpx.Response(200, text="recovered"),
            ]
        )
        result = await BaseScraper().fetch("http://example.com/")
    assert result == "recovered"
    assert route.call_count == 2


async def test_fetch_raises_scraper_error_on_http_404() -> None:
    with patch("asyncio.sleep", new_callable=AsyncMock), respx.mock:
        respx.get("http://example.com/").mock(return_value=httpx.Response(404))
        with pytest.raises(ScraperError):
            await BaseScraper().fetch("http://example.com/")


async def test_fetch_raises_scraper_error_on_http_500() -> None:
    with patch("asyncio.sleep", new_callable=AsyncMock), respx.mock:
        respx.get("http://example.com/").mock(return_value=httpx.Response(500))
        with pytest.raises(ScraperError):
            await BaseScraper().fetch("http://example.com/")


async def test_fetch_retries_exactly_max_times() -> None:
    with patch("asyncio.sleep", new_callable=AsyncMock), respx.mock:
        route = respx.get("http://example.com/").mock(
            side_effect=httpx.ConnectError("refused")
        )
        with pytest.raises(ScraperError):
            await BaseScraper().fetch("http://example.com/")
    assert route.call_count == BaseScraper._MAX_RETRIES


def test_clean_text_strips_and_normalises_nbsp() -> None:
    node = type("N", (), {"text": lambda self, deep: "  Preis:\xa03,10\xa0€  "})()
    assert BaseScraper.clean_text(node) == "Preis: 3,10 €"
