from __future__ import annotations

from pydantic import BaseModel, ConfigDict


class Category(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    id: int
    name: str
