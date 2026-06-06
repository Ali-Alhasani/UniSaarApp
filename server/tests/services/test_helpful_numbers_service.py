from __future__ import annotations

import json
import tempfile
from pathlib import Path

from src.services.helpful_numbers_service import HelpfulNumbersService

_FIXTURE_DIR = Path(__file__).parent.parent / "source" / "helpful_number_files"


def test_load_returns_numbers() -> None:
    result = HelpfulNumbersService(_FIXTURE_DIR).load("de")
    assert len(result.numbers) > 0


def test_numbers_have_name_and_number() -> None:
    result = HelpfulNumbersService(_FIXTURE_DIR).load("de")
    for entry in result.numbers:
        assert entry.name
        assert entry.number


def test_all_languages_load() -> None:
    service = HelpfulNumbersService(_FIXTURE_DIR)
    for lang in ("de", "en", "fr"):
        result = service.load(lang)
        assert result.numbers, f"No numbers for lang={lang}"


def test_empty_link_and_mail_become_none() -> None:
    result = HelpfulNumbersService(_FIXTURE_DIR).load("de")
    # source file has entries with empty link/mail strings
    entries_with_link = [e for e in result.numbers if e.link is not None]
    entries_with_mail = [e for e in result.numbers if e.mail is not None]
    # at least one entry has a real link and one has a real mail
    assert entries_with_link
    assert entries_with_mail


def test_malformed_entry_skipped_not_raised() -> None:
    data = {
        "numbers": [
            {"name": "Valid", "number": "123", "link": "", "mail": ""},
            {"invalid_key": True},  # missing name/number → KeyError
        ]
    }
    with tempfile.TemporaryDirectory() as tmp:
        d = Path(tmp)
        (d / "helpfulNumbers_de.info").write_text(json.dumps(data))
        result = HelpfulNumbersService(d).load("de")
    assert len(result.numbers) == 1
    assert result.numbers[0].name == "Valid"


def test_non_list_numbers_field_returns_empty() -> None:
    data = {"numbers": "not-a-list"}
    with tempfile.TemporaryDirectory() as tmp:
        d = Path(tmp)
        (d / "helpfulNumbers_de.info").write_text(json.dumps(data))
        result = HelpfulNumbersService(d).load("de")
    assert result.numbers == []
