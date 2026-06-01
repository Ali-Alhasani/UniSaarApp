# UniSaarApp Server

Read-only information hub for Saarland University students — Mensa menus, news, events, staff directory, campus map, and helpful numbers.

> For architecture decisions and the full 7-PR implementation plan, see [`SERVER_GUIDE.md`](SERVER_GUIDE.md).  
> For the overall project roadmap across all phases, see [`../ROADMAP.md`](../ROADMAP.md).

---

## Stack

| Concern | Choice |
|---|---|
| Framework | FastAPI + Uvicorn |
| HTTP client | httpx (async, non-blocking) |
| Parsing | selectolax (HTML) + stdlib `xml.etree` (RSS) |
| Data validation | Pydantic v2 |
| Config / secrets | pydantic-settings + `.env` + `.secrets` |
| Scheduling | APScheduler `AsyncIOScheduler` — `worker` container only *(PR 4)* |
| Cache | DiskCache (SQLite WAL, shared volume) *(PR 4)* |
| Logging | loguru |
| Error tracking | Sentry *(PR 7)* |
| Python | 3.13+ |
| Package manager | Poetry |

---

## Prerequisites

- Python 3.13+
- [Poetry](https://python-poetry.org/) — `pip install poetry`

---

## Setup

```bash
# Install dependencies
poetry install

# Create local config files (both are gitignored)
cp .env.example .env
cp .secrets.example .secrets
# Edit .secrets: fill in SERVER_ADDRESS, PROXY_URL, MENSA_API_KEY, SENTRY_DSN
```

`.env` holds non-sensitive config (ports, intervals, log level).  
`.secrets` holds credentials and hostnames — never committed, never logged.

---

## Dev Commands

```bash
# Run dev server with auto-reload
uvicorn src.main:app --reload

# Run all tests (zero live network calls)
pytest tests/ -v

# Lint
ruff check src/ tests/

# Format check
ruff format --check src/ tests/

# Type check
mypy src/

# Run all pre-commit hooks on every file
pre-commit run --all-files
```

---

## Project Structure

```
server/
  src/
    api/          # FastAPI routers — one file per resource
    core/         # config.py (pydantic-settings), constants
    models/       # Pydantic v2 schemas — the iOS JSON contract
    services/     # Scrapers and business logic
    storage/      # DiskCache async wrapper (PR 4)
  tests/
    contracts/    # JSON key contract tests — assert exact iOS Codable field names
    models/       # Pydantic validation tests
    services/     # Scraper and service unit tests
    api/          # Route tests (PR 5)
  source/         # Legacy static data files (map, helpful numbers, more links)
  .env.example
  .secrets.example
  SERVER_GUIDE.md
```

---

## Data Sources

| Resource | Source | Method |
|---|---|---|
| News DE / EN / FR | `uni-saarland.de/.../news/feed.rss` | RSS (TYPO3 EXT:news) |
| Events DE / EN / FR | `uni-saarland.de/.../veranstaltungen/feed.rss` | RSS (TYPO3 EXT:news) |
| Mensa menus | `mensaar.de/api/1/{key}/1/{lang}/getMenu/{location}` | JSON API |
| Staff search | `lsf.uni-saarland.de/qisserver/rds` | HTML scrape |
| Map | `source/map_data/campus_map_data` | Static file |
| Helpful Numbers | `source/helpful_number_files/helpfulNumbers_{lang}.info` | Static file |
| More links | `source/links_for_more_tab/` | Static files |

**Mensa locations:** `sb`, `hom`, `forum`, `mensagarten`  
**Languages:** `de`, `en`, `fr`

---

## Refactor Progress (Phase 2)

Branch: `upgrade/modern-python-server` — the old server on `master` stays running until PR 5 cutover.

| Status | PR | What it delivers |
|---|---|---|
| ✅ Done | PR 1 — Foundation + CI | Poetry stack, Python 3.13, CI pipeline, health endpoint |
| ✅ Done | PR 2 — Data Contracts | Pydantic v2 models, contract tests, iOS field alignment |
| ✅ Done | PR 3 — Scrapers | News/events/mensa/staff scrapers, map and helpful numbers services |
| ⏳ Next | PR 4 — Storage + Scheduling | DiskCache async wrapper, APScheduler standalone worker, cold-start scrape |
| ⏳ | PR 5 — FastAPI Routes | All endpoints (legacy + `/v1/`), cutover gate |
| ⏳ | PR 6 — Staff + HelpfulNumbers | TTLCache for search, rate limiting, HelpfulNumbers KeyError fix |
| ⏳ | PR 7 — Production | Dockerfile, docker-compose, Nginx, Sentry |

---

## Known Follow-up Items

These are implementation discoveries that don't change the architecture but need attention before or during their respective PRs.

**Before PR 4**
- **BaseScraper client lifecycle**: `httpx.AsyncClient` is created in `__init__` and only closed in `__aexit__`. The scheduler must instantiate scrapers with `async with scraper:` blocks, or the client must be moved to per-`fetch()` scope. Leaving this unresolved will leak connections in the worker process.

**Before PR 5**
- **Old legacy test files**: `tests/DirectoryParserUnitTest.py`, `tests/MensaParserUnitTest.py`, `tests/NewsAndEventsParserUnitTest.py`, `tests/RequestHandlerIntegrationTest.py`, `tests/ServerIntegrationTest.py`, `tests/modelsUnitTest.py` are excluded from ruff/mypy but still in the repo. Delete in a cleanup commit before the routes PR so CI runs clean.

**Before PR 7**
- **Weekly live-scraper CI job**: Described in SERVER_GUIDE PR 1 spec — runs all scrapers against real university URLs weekly and validates output against Pydantic models. Not yet implemented. Add to `.github/workflows/server-ci.yml` as a scheduled workflow.

**Phase 3 consideration**
- **`content:encoded` in RSS items**: Each news/event RSS item contains the full article HTML in a `<content:encoded>` CDATA block. Currently only `<description>` (the short summary) is parsed. If Phase 3 needs the full body, add namespace-aware parsing: `item_el.find("{http://purl.org/rss/1.0/modules/content/}encoded")`.

---

## Environment Variables Reference

**`.env`** — non-sensitive, gitignored
```bash
HOST=0.0.0.0
PORT=3000
LOG_LEVEL=INFO
CACHE_DIR=.cache
NEWS_UPDATE_INTERVAL_MIN=30
MENSA_UPDATE_CRON=0 6 * * *
HELPFUL_NUMBERS_UPDATE_CRON=0 7 * * *
MAP_UPDATE_CRON=0 8 * * *
```

**`.secrets`** — sensitive credentials, gitignored, never logged
```bash
SERVER_ADDRESS=        # university server hostname
PROXY_URL=             # proxy.cs.uni-saarland.de:3128 on university server, empty locally
MENSA_API_KEY=         # contact felix@fefrei.de for a key
SENTRY_DSN=            # leave empty to disable Sentry locally
```
