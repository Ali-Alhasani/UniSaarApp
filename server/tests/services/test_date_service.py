from __future__ import annotations

from datetime import date, datetime

import pytest

from src.core.enums import Language
from src.services.date_service import format_mensa_date, mensa_target_date


@pytest.mark.parametrize(
    "now, expected",
    [
        (datetime(2020, 1, 6, 9, 0), date(2020, 1, 6)),  # Monday morning → today
        (datetime(2020, 1, 6, 14, 0), date(2020, 1, 6)),  # Monday 14:00 → today
        (datetime(2020, 1, 9, 9, 0), date(2020, 1, 9)),  # Thursday morning → today
        (datetime(2020, 1, 9, 14, 0), date(2020, 1, 9)),  # Thursday 14:00 → today
        (datetime(2020, 1, 10, 9, 0), date(2020, 1, 10)),  # Friday morning → today
        (datetime(2020, 1, 10, 14, 0), date(2020, 1, 10)),  # Friday 14:00 → today
        (datetime(2020, 1, 11, 12, 0), date(2020, 1, 13)),  # Saturday → Monday
        (datetime(2020, 1, 12, 12, 0), date(2020, 1, 13)),  # Sunday → Monday
    ],
)
def test_mensa_target_date(now: datetime, expected: date) -> None:
    assert mensa_target_date(now) == expected


@pytest.mark.parametrize(
    "lang, expected",
    [
        (Language.DE, "Montag 06.01."),
        (Language.EN, "Monday 06.01."),
        (Language.FR, "Lundi 06.01."),
    ],
)
def test_format_mensa_date_all_supported_languages(
    lang: Language, expected: str
) -> None:
    assert format_mensa_date(date(2020, 1, 6), lang) == expected


def test_format_mensa_date_zero_pad_day_and_month() -> None:
    assert format_mensa_date(date(2020, 3, 2), Language.DE) == "Montag 02.03."
