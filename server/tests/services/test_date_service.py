from __future__ import annotations

from datetime import date, datetime

import pytest

from src.services.date_service import format_mensa_date, mensa_target_date


@pytest.mark.parametrize(
    "now, expected",
    [
        (datetime(2020, 1, 6, 9, 0), date(2020, 1, 6)),  # Monday morning → today
        (datetime(2020, 1, 6, 14, 0), date(2020, 1, 7)),  # Monday 14:00 → tomorrow
        (datetime(2020, 1, 9, 9, 0), date(2020, 1, 9)),  # Thursday morning → today
        (datetime(2020, 1, 9, 14, 0), date(2020, 1, 10)),  # Thursday 14:00 → Friday
        (datetime(2020, 1, 10, 9, 0), date(2020, 1, 10)),  # Friday morning → today
        (datetime(2020, 1, 10, 14, 0), date(2020, 1, 13)),  # Friday 14:00 → Monday
        (datetime(2020, 1, 11, 12, 0), date(2020, 1, 13)),  # Saturday → Monday
        (datetime(2020, 1, 12, 12, 0), date(2020, 1, 13)),  # Sunday → Monday
    ],
)
def test_mensa_target_date(now: datetime, expected: date) -> None:
    assert mensa_target_date(now) == expected


def test_format_mensa_date_german() -> None:
    assert format_mensa_date(date(2020, 1, 6), "de") == "Montag 06.01."


def test_format_mensa_date_english() -> None:
    assert format_mensa_date(date(2020, 1, 6), "en") == "Monday 06.01."


def test_format_mensa_date_french() -> None:
    assert format_mensa_date(date(2020, 1, 6), "fr") == "Lundi 06.01."


def test_format_mensa_date_unknown_lang_falls_back_to_german() -> None:
    assert format_mensa_date(date(2020, 1, 6), "xx") == "Montag 06.01."


def test_format_mensa_date_zero_pad_day_and_month() -> None:
    assert format_mensa_date(date(2020, 3, 2), "de") == "Montag 02.03."
