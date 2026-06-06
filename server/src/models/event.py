from __future__ import annotations

from datetime import date

from pydantic import BaseModel, ConfigDict, Field

from src.models.category import Category


class EventItem(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    id: int
    title: str
    happening_date: date | None = Field(default=None, alias="happeningDate")
    description: str
    link: str
    image_url: str | None = Field(default=None, alias="imageURL")
    categories: list[Category]


class EventFeed(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    item_count: int = Field(alias="itemCount")
    categories_last_changed: str = Field(alias="categoriesLastChanged")
    has_next_page: bool = Field(alias="hasNextPage")
    items: list[EventItem]
