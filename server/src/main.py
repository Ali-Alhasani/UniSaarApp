import time
from collections.abc import AsyncGenerator
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import Response
from loguru import logger
from slowapi.errors import RateLimitExceeded

from src.api.campus_map import router as map_router
from src.api.directory import router as directory_router
from src.api.events import router as events_router
from src.api.health import router as health_router
from src.api.mensa import router as mensa_router
from src.api.more import router as more_router
from src.api.news import router as news_router
from src.core.logging import setup_logging
from src.core.rate_limits import limiter


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None]:
    setup_logging()
    yield


app = FastAPI(title="UniSaarApp Server", lifespan=lifespan)
app.state.limiter = limiter


@app.exception_handler(RateLimitExceeded)
async def rate_limit_exceeded_handler(
    request: Request, exc: RateLimitExceeded
) -> Response:
    ip = request.client.host if request.client else "unknown"
    logger.warning(
        "rate_limit_hit | ip={} path={} limit={}", ip, request.url.path, exc.detail
    )
    return Response(
        status_code=429, content="Too many requests.", media_type="text/plain"
    )


@app.exception_handler(HTTPException)
async def plain_text_http_exception_handler(
    request: Request, exc: HTTPException
) -> Response:
    return Response(
        status_code=exc.status_code,
        content=str(exc.detail),
        media_type="text/plain",
    )


app.include_router(health_router, prefix="/v1")

_versioned_routers = [
    news_router,
    events_router,
    mensa_router,
    directory_router,
    map_router,
    more_router,
]
for _router in _versioned_routers:
    app.include_router(_router)
    app.include_router(_router, prefix="/v1")


@app.middleware("http")
async def request_logger(request: Request, call_next: object) -> Response:
    start = time.perf_counter()
    response: Response = await call_next(request)  # type: ignore[operator]
    duration_ms = (time.perf_counter() - start) * 1000
    # No IP logged — path alone is sufficient for usage analytics and avoids
    # storing personal data on every request (GDPR). IP is only logged on 429.
    logger.info(
        "request | {} {} {} {:.0f}ms",
        request.method,
        request.url.path,
        response.status_code,
        duration_ms,
    )
    path = request.url.path
    if path.startswith("/v1/") or path.startswith("/v2/"):
        response.headers["X-Route-Generation"] = path.split("/")[1]
    else:
        response.headers["X-Route-Generation"] = "legacy"
    return response
