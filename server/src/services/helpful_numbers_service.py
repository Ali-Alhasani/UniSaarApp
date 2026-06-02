from __future__ import annotations

import json
from pathlib import Path

from loguru import logger

from src.models.helpful_numbers import HelpfulNumber, HelpfulNumbersResponse

_DEFAULT_DIR = Path(__file__).parent.parent.parent / "source" / "helpful_number_files"


class HelpfulNumbersService:
    def __init__(self, source_dir: Path = _DEFAULT_DIR) -> None:
        self._source_dir = source_dir

    def load(self, lang: str = "de") -> HelpfulNumbersResponse:
        path = self._source_dir / f"helpfulNumbers_{lang}.info"
        data: dict[str, object] = json.loads(path.read_text(encoding="utf-8"))
        numbers: list[HelpfulNumber] = []
        raw = data.get("numbers", [])
        if not isinstance(raw, list):
            raw = []
        for item in raw:
            if not isinstance(item, dict):
                continue
            try:
                numbers.append(
                    HelpfulNumber(
                        name=str(item["name"]),
                        number=str(item["number"]),
                        link=str(item["link"]) if item.get("link") else None,
                        mail=str(item["mail"]) if item.get("mail") else None,
                    )
                )
            except KeyError as exc:
                logger.warning(
                    "Skipping malformed helpful number entry, missing key {}: {}",
                    exc,
                    item,
                )
        return HelpfulNumbersResponse(numbers=numbers)
