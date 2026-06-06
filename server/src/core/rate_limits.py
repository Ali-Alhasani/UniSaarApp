from __future__ import annotations

from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)


class RateLimit:
    # Live outbound HTTP to university LSF — protects our IP from being banned.
    # Per-IP limits; students on campus NAT share a bucket, so values are generous.
    DIRECTORY_SEARCH = "30/minute"
    DIRECTORY_PERSON = "60/minute"

    # Background article scrape to uni-saarland.de on first open only;
    # subsequent requests for the same article are cache hits (24h TTL).
    DETAIL_PAGE = "60/minute"
