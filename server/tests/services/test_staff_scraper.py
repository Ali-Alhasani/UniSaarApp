from __future__ import annotations

from pathlib import Path
from unittest.mock import AsyncMock, patch

import pytest

from src.services.base_scraper import BaseScraper
from src.services.staff_scraper import StaffScraper, StaffSearchTooVagueError

_FIXTURE_DIR = Path(__file__).parent.parent / "testdata" / "directory"


def _html(name: str) -> str:
    return (_FIXTURE_DIR / name).read_text(encoding="utf-8")


# --- Parsing (no network) ---


def test_parse_search_results_count() -> None:
    items = StaffScraper._parse_search_results(_html("searchResults.html"))
    assert len(items) == 4


def test_parse_search_results_zeller_pid_and_title() -> None:
    items = StaffScraper._parse_search_results(_html("searchResults.html"))
    zeller = next(i for i in items if i.pid == 2307)
    assert zeller.name == "Andreas Zeller"
    assert zeller.title == "Univ.-Professor Dr.-Ing."


def test_parse_search_results_no_title() -> None:
    items = StaffScraper._parse_search_results(_html("searchResults.html"))
    tanja = next(i for i in items if i.pid == 13107)
    assert tanja.name == "Tanja Zeller"
    assert tanja.title == ""


def test_parse_search_results_title_prefix() -> None:
    items = StaffScraper._parse_search_results(_html("searchResults.html"))
    julia = next(i for i in items if i.pid == 19585)
    assert julia.title == "Dr.med."
    assert "Julia" in julia.name


def test_parse_empty_results() -> None:
    assert StaffScraper._parse_search_results(_html("searchResultsEmpty.html")) == []


def test_too_many_results_raises() -> None:
    with pytest.raises(StaffSearchTooVagueError):
        StaffScraper._parse_search_results(_html("searchResultsTooManyResults.html"))


def test_too_few_chars_raises() -> None:
    with pytest.raises(StaffSearchTooVagueError):
        StaffScraper._parse_search_results(_html("searchResultsTooFewCharacters.html"))


def test_parse_details_basic_fields() -> None:
    details = StaffScraper()._parse_details(_html("detailsNormal.html"))
    assert details.first_name == "Andreas"
    assert details.last_name == "Zeller"
    assert details.title == "Univ.-Professor Dr.-Ing."
    assert details.gender == "männlich"


def test_parse_details_address() -> None:
    details = StaffScraper()._parse_details(_html("detailsNormal.html"))
    assert details.office == "2.07"
    assert details.building == "Gebäude E9 1"
    assert details.postal_code == "66123"
    assert details.city == "Saarbrücken"
    assert details.street == "Stuhlsatzenhaus 5"
    assert details.phone == "+49 (0)681 / 302-70971"
    assert details.fax == "+49 (0)681 / 302-70972"
    assert details.mail == "zeller@cispa.saarland"
    assert "cispa.saarland" in details.webpage


def test_parse_details_functions() -> None:
    details = StaffScraper()._parse_details(_html("detailsNormal.html"))
    assert len(details.functions) >= 1
    dept_names = [f.f_department or "" for f in details.functions]
    assert any("Software Engineering" in d for d in dept_names)


def test_parse_details_image_link_is_none() -> None:
    details = StaffScraper()._parse_details(_html("detailsNormal.html"))
    assert details.image_link is None


def test_parse_details_empty_address_no_crash() -> None:
    details = StaffScraper()._parse_details(_html("detailsEmptyAddress.html"))
    assert isinstance(details.first_name, str)


def test_parse_details_no_address_table_no_crash() -> None:
    details = StaffScraper()._parse_details(_html("detailsNoAddressTable.html"))
    assert isinstance(details.first_name, str)


# --- Full integration via AsyncMock ---


async def test_search_integration() -> None:
    html = _html("searchResults.html")
    with patch.object(BaseScraper, "fetch", new_callable=AsyncMock, return_value=html):
        result = await StaffScraper().search("zeller")
    assert result.item_count == 4
    assert result.has_next_page is False


async def test_fetch_details_integration() -> None:
    html = _html("detailsNormal.html")
    with patch.object(BaseScraper, "fetch", new_callable=AsyncMock, return_value=html):
        details = await StaffScraper().fetch_details(2307)
    assert details.first_name == "Andreas"
    assert details.last_name == "Zeller"
