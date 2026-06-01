from __future__ import annotations

from pydantic import BaseModel, ConfigDict, Field


class HelpfulNumber(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    name: str
    number: str
    link: str | None = None
    mail: str | None = None


class HelpfulNumbersResponse(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    numbers_last_changed: str | None = Field(
        default=None, serialization_alias="numbersLastChanged"
    )
    numbers: list[HelpfulNumber]
