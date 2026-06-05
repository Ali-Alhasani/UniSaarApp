from __future__ import annotations

import pytest

from src.core import locale
from src.core.enums import Language

_ALL_LANGUAGES = list(Language)

_LOCALE_DICTS = [
    ("READ_MORE", locale.READ_MORE),
    ("VIEW_EVENT", locale.VIEW_EVENT),
    ("ERROR_TITLE", locale.ERROR_TITLE),
    ("ERROR_BODY", locale.ERROR_BODY),
    ("CACHE_NOT_READY", locale.CACHE_NOT_READY),
    ("MEAL_NOT_FOUND", locale.MEAL_NOT_FOUND),
    ("DIRECTORY_QUERY_TOO_SHORT", locale.DIRECTORY_QUERY_TOO_SHORT),
    ("DIRECTORY_QUERY_TOO_BROAD", locale.DIRECTORY_QUERY_TOO_BROAD),
    ("DIRECTORY_UNAVAILABLE", locale.DIRECTORY_UNAVAILABLE),
]


@pytest.mark.parametrize("name,d", _LOCALE_DICTS)
def test_locale_dict_covers_all_languages(name: str, d: dict[Language, str]) -> None:
    missing = [lang for lang in _ALL_LANGUAGES if lang not in d]
    assert not missing, f"{name} missing entries for: {missing}"


@pytest.mark.parametrize("name,d", _LOCALE_DICTS)
def test_locale_dict_values_are_non_empty(name: str, d: dict[Language, str]) -> None:
    empty = [lang for lang, text in d.items() if not text.strip()]
    assert not empty, f"{name} has empty strings for: {empty}"


@pytest.mark.parametrize("name,d", _LOCALE_DICTS)
def test_locale_dict_has_no_extra_keys(name: str, d: dict[Language, str]) -> None:
    extra = [k for k in d if k not in _ALL_LANGUAGES]
    assert not extra, f"{name} has keys outside Language enum: {extra}"
