from __future__ import annotations

from pydantic import BaseModel, ConfigDict, Field


class MapEntry(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    campus: str
    name: str
    function: str
    latitude: str
    longitude: str
    website: str


class MapResponse(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    map_info: list[MapEntry] = Field(serialization_alias="mapInfo")
    update_time: str = Field(serialization_alias="updateTime")
