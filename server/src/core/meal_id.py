from __future__ import annotations

from datetime import date
from typing import Annotated

from pydantic import Field

from src.core.enums import CampusLocation, MensaLocation

# Derived from enum metadata — update MensaLocation when sources change.
CAMPUS_SOURCES: dict[CampusLocation, list[MensaLocation]] = {
    campus: sorted(
        (s for s in MensaLocation if s.campus == campus),
        key=lambda s: s.source_idx,
    )
    for campus in CampusLocation
}


def generate_meal_id(source: MensaLocation, day: date, counter: int, meal: int) -> int:
    """Return a stable 14-digit int ID for a meal.

    Format: {campus.code:1}{source.source_idx:1}{YYYYMMDD:8}{counter:02}{meal:02}
    Same meal always produces the same ID across scrape runs.
    Raises ValueError if counter or meal exceed 99.
    """
    if not (0 <= counter <= 99 and 0 <= meal <= 99):
        raise ValueError(
            f"counter and meal must be 0–99, got counter={counter}, meal={meal}"
        )
    return int(
        f"{source.campus.code}{source.source_idx}"
        f"{day.strftime('%Y%m%d')}{counter:02d}{meal:02d}"
    )


def campus_from_id(meal_id: int) -> CampusLocation:
    """Extract the CampusLocation encoded in a 14-digit meal ID.

    Raises ValueError for an unrecognised campus code.
    """
    campus_code = meal_id // 10_000_000_000_000
    try:
        return next(c for c in CampusLocation if c.code == campus_code)
    except StopIteration:
        raise ValueError(
            f"Invalid meal ID {meal_id}: unknown campus code {campus_code}"
        ) from None


# 14-digit int: campus(1) + source_idx(1) + YYYYMMDD(8) + counter(02) + meal(02)
MealId = Annotated[int, Field(ge=10_000_000_000_000, le=99_999_999_999_999)]
