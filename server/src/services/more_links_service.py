from __future__ import annotations

import json
from pathlib import Path

from src.models.more import MoreLink, MoreLinksResponse

_DEFAULT_DIR = Path(__file__).parent.parent.parent / "source" / "links_for_more_tab"

_LANG_FILE: dict[str, str] = {
    "de": "deMoreLinks.info",
    "en": "enMoreLinks.info",
    "fr": "frMoreLinks.info",
}


class MoreLinksService:
    def __init__(self, source_dir: Path = _DEFAULT_DIR) -> None:
        self._source_dir = source_dir

    def load(self, lang: str = "de") -> MoreLinksResponse:
        filename = _LANG_FILE.get(lang, _LANG_FILE["de"])
        path = self._source_dir / filename
        data: dict[str, object] = json.loads(path.read_text(encoding="utf-8"))
        raw_links = data.get("links", [])
        links: list[MoreLink] = []
        if isinstance(raw_links, list):
            for item in raw_links:
                if isinstance(item, dict):
                    links.append(
                        MoreLink(
                            name=str(item.get("name", "")),
                            link=str(item.get("link", "")),
                            importance=int(item.get("importance", 0)),
                        )
                    )
        links.sort(key=lambda lnk: lnk.importance)
        return MoreLinksResponse(
            links_last_changed=str(data.get("linksLastChanged", "")),
            language=str(data.get("language", lang)),
            links=links,
        )
