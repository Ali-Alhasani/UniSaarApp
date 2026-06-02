from __future__ import annotations

import json
import tempfile
from pathlib import Path

from src.services.map_service import MapService

_FIXTURE_PATH = Path(__file__).parent.parent / "source" / "map_data" / "campus_map_data"


def test_load_returns_entries() -> None:
    result = MapService(_FIXTURE_PATH).load()
    assert len(result.map_info) > 0


def test_entries_have_required_fields() -> None:
    result = MapService(_FIXTURE_PATH).load()
    entry = result.map_info[0]
    assert entry.campus
    assert entry.name
    assert entry.latitude
    assert entry.longitude


def test_update_time_is_iso8601_z() -> None:
    result = MapService(_FIXTURE_PATH).load()
    assert result.update_time.endswith("Z")


def test_malformed_entry_skipped() -> None:
    data = {
        "mapInfo": [
            {
                "campus": "saar",
                "name": "Good",
                "function": "Lib",
                "latitude": "49.0",
                "longitude": "7.0",
                "website": "",
            },
            "not-a-dict",
        ]
    }
    with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as f:
        json.dump(data, f)
        tmp = Path(f.name)
    result = MapService(tmp).load()
    assert len(result.map_info) == 1
    assert result.map_info[0].name == "Good"
