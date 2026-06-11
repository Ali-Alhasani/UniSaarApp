from __future__ import annotations

import json
from datetime import UTC, datetime
from pathlib import Path

from loguru import logger

from src.core.constants import CAMPUS_CITY_NAMES
from src.core.enums import CampusLocation
from src.models.map import MapEntry, MapResponse


def _campus_city(raw: str) -> str:
    try:
        return CAMPUS_CITY_NAMES[CampusLocation(raw)]
    except (KeyError, ValueError):
        return raw


_DEFAULT_PATH = (
    Path(__file__).parent.parent.parent / "source" / "map_data" / "campus_map_data"
)


class MapService:
    def __init__(self, source_path: Path = _DEFAULT_PATH) -> None:
        self._source_path = source_path

    def load(self) -> MapResponse:
        data: dict[str, object] = json.loads(
            self._source_path.read_text(encoding="utf-8")
        )
        entries: list[MapEntry] = []
        raw = data.get("mapInfo", [])
        if isinstance(raw, list):
            for item in raw:
                if not isinstance(item, dict):
                    continue
                try:
                    entries.append(
                        MapEntry(
                            campus=_campus_city(
                                "sb"
                                if item.get("campus") == "saar"
                                else str(item.get("campus", ""))
                            ),
                            name=str(item.get("name", "")),
                            function=str(item.get("function", "")),
                            latitude=str(item.get("latitude", "")),
                            longitude=str(item.get("longitude", "")),
                            website=str(item.get("website", "")),
                        )
                    )
                except Exception as exc:
                    logger.warning("Skipping malformed map entry {}: {}", item, exc)
        update_time = datetime.now(UTC).strftime("%Y-%m-%dT%H:%M:%SZ")
        return MapResponse(map_info=entries, update_time=update_time)
