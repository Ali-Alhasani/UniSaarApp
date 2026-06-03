from collections.abc import AsyncGenerator
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import Response

from src.api.directory import router as directory_router
from src.api.events import router as events_router
from src.api.health import router as health_router
from src.api.map import router as map_router
from src.api.mensa import router as mensa_router
from src.api.more import router as more_router
from src.api.news import router as news_router
from src.core.logging import setup_logging


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None]:
    setup_logging()
    yield


app = FastAPI(title="UniSaarApp Server", lifespan=lifespan)


@app.exception_handler(HTTPException)
async def plain_text_http_exception_handler(
    request: Request, exc: HTTPException
) -> Response:
    return Response(
        status_code=exc.status_code,
        content=str(exc.detail),
        media_type="text/plain",
    )


app.include_router(health_router)
app.include_router(news_router)
app.include_router(events_router)
app.include_router(mensa_router)
app.include_router(directory_router)
app.include_router(map_router)
app.include_router(more_router)


@app.middleware("http")
async def route_generation_header(request: Request, call_next: object) -> Response:
    response: Response = await call_next(request)  # type: ignore[operator]
    path = request.url.path
    if path.startswith("/v1/") or path.startswith("/v2/"):
        response.headers["X-Route-Generation"] = path.split("/")[1]
    else:
        response.headers["X-Route-Generation"] = "legacy"
    return response
