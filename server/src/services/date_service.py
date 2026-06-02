from __future__ import annotations

from datetime import date, datetime, timedelta

_WEEKDAY_NAMES: dict[str, list[str]] = {
    "de": [
        "Montag",
        "Dienstag",
        "Mittwoch",
        "Donnerstag",
        "Freitag",
        "Samstag",
        "Sonntag",
    ],
    "en": [
        "Monday",
        "Tuesday",
        "Wednesday",
        "Thursday",
        "Friday",
        "Saturday",
        "Sunday",
    ],
    "fr": [
        "Lundi",
        "Mardi",
        "Mercredi",
        "Jeudi",
        "Vendredi",
        "Samedi",
        "Dimanche",
    ],
}


def mensa_target_date(now: datetime) -> date:
    """Return the date whose menu to display for a given datetime.

    - Mon–Fri before 14:00: today
    - Mon–Thu at/after 14:00: tomorrow
    - Fri at/after 14:00, Sat, Sun: next Monday
    """
    current = now.date()
    weekday = current.weekday()  # 0 = Mon … 6 = Sun

    if weekday == 5:  # Saturday → Monday
        return current + timedelta(days=2)
    if weekday == 6:  # Sunday → Monday
        return current + timedelta(days=1)
    if now.hour >= 14:
        if weekday == 4:  # Friday after 14:00 → Monday
            return current + timedelta(days=3)
        return current + timedelta(days=1)
    return current


def format_mensa_date(d: date, lang: str = "de") -> str:
    """Format a date as 'Weekday DD.MM.' in the given language."""
    names = _WEEKDAY_NAMES.get(lang, _WEEKDAY_NAMES["de"])
    return f"{names[d.weekday()]} {d.day:02}.{d.month:02}."
