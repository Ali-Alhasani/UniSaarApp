from __future__ import annotations

from datetime import date

from pydantic import BaseModel, ConfigDict, Field


class Category(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    id: int
    name: str


class NewsItem(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    id: int
    title: str
    published_date: date | None = Field(
        default=None, serialization_alias="publishedDate"
    )
    happening_date: date | None = Field(
        default=None, serialization_alias="happeningDate"
    )
    description: str
    link: str
    image_url: str | None = Field(default=None, serialization_alias="imageURL")
    categories: list[Category]
    is_event: bool = Field(serialization_alias="isEvent")


class NewsFeed(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    item_count: int = Field(serialization_alias="itemCount")
    categories_last_changed: str = Field(serialization_alias="categoriesLastChanged")
    has_next_page: bool = Field(serialization_alias="hasNextPage")
    items: list[NewsItem]
