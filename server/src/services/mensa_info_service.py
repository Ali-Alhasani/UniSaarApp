from __future__ import annotations

import json
from pathlib import Path

from loguru import logger

from src.models.mensa import MensaInfo

_DEFAULT_DIR = Path(__file__).parent.parent.parent / "source" / "location_info_files"


class MensaInfoService:
    def __init__(self, source_dir: Path = _DEFAULT_DIR) -> None:
        self._source_dir = source_dir

    def load(self, location: str, lang: str = "de") -> MensaInfo | None:
        path = self._source_dir / f"{location}.info"
        if not path.exists():
            logger.warning("No location info file for location '{}'", location)
            return None
        data: dict[str, object] = json.loads(path.read_text(encoding="utf-8"))
        lang_data_list = data.get("langData", [])
        if not isinstance(lang_data_list, list):
            return None
        lang_entry = next(
            (
                x
                for x in lang_data_list
                if isinstance(x, dict) and x.get("lang") == lang
            ),
            None,
        )
        if lang_entry is None:
            lang_entry = next(
                (x for x in lang_data_list if isinstance(x, dict)),
                None,
            )
        if lang_entry is None:
            return None
        return MensaInfo(
            name=str(lang_entry.get("name", "")),
            description=str(lang_entry.get("description", "")),
            image_link=str(data.get("image", "")),
        )
