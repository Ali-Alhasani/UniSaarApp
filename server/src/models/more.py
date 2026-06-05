from __future__ import annotations

from pydantic import BaseModel, ConfigDict, Field

from src.core.enums import Language


class MoreLink(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    name: str
    link: str
    importance: int = 0


class MoreLinksResponse(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    links_last_changed: str = Field(alias="linksLastChanged")
    language: Language
    links: list[MoreLink]
