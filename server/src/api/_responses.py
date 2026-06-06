from __future__ import annotations

from fastapi.responses import Response

from src.core.enums import Language
from src.core.locale import CACHE_NOT_READY


def cache_not_ready(lang: Language = Language.DE) -> Response:
    return Response(
        status_code=503, content=CACHE_NOT_READY[lang], media_type="text/plain"
    )
