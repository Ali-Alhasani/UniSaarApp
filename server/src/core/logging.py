from __future__ import annotations

import logging
import sys

from loguru import logger

from src.core.config import settings

_CONSOLE_FORMAT = (
    "<green>{time:YYYY-MM-DD HH:mm:ss}</green> | "
    "<level>{level: <8}</level> | "
    "<cyan>{name}</cyan>:<cyan>{line}</cyan> — "
    "<level>{message}</level>"
)
_FILE_FORMAT = "{time:YYYY-MM-DD HH:mm:ss} | {level: <8} | {name}:{line} — {message}"


class _InterceptHandler(logging.Handler):
    """Routes every stdlib logging record through loguru.

    Uvicorn, httpx, APScheduler, and diskcache all use stdlib logging.
    Without this, their messages never reach loguru's sinks.

    The frame walk is required so loguru reports the real caller site
    (e.g. uvicorn/protocols/http.py:312) instead of this interceptor.
    """

    def emit(self, record: logging.LogRecord) -> None:
        try:
            level: str | int = logger.level(record.levelname).name
        except ValueError:
            level = record.levelno

        frame, depth = sys._getframe(6), 6
        while frame and frame.f_code.co_filename == logging.__file__:
            frame = frame.f_back  # type: ignore[assignment]
            depth += 1

        logger.opt(depth=depth, exception=record.exc_info).log(
            level, record.getMessage()
        )


def setup_logging() -> None:
    logger.remove()
    level = settings.log_level.upper()
    logger.add(sys.stderr, level=level, format=_CONSOLE_FORMAT, colorize=True)
    logger.add(
        "logs/server.log",
        level=level,
        rotation="10 MB",
        retention="7 days",
        compression="gz",
        format=_FILE_FORMAT,
    )

    # Replace the root stdlib handler with our interceptor.
    # level=0 (NOTSET) means "pass everything" — loguru's level filter takes over.
    # force=True clears any handlers that uvicorn or other libs installed before us.
    logging.basicConfig(handlers=[_InterceptHandler()], level=0, force=True)

    # Walk all already-registered loggers and remove their own handlers so records
    # propagate to the root interceptor instead of being emitted twice.
    for name in list(logging.root.manager.loggerDict):
        lib_logger = logging.getLogger(name)
        lib_logger.handlers = []
        lib_logger.propagate = True
