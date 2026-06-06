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
| Scheduling | APScheduler `AsyncIOScheduler` — `worker` process only |
| Cache | DiskCache (SQLite WAL, shared volume) |
| Rate limiting | slowapi (per-IP, fixed window) |
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
poetry install
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

# Run the scheduler worker (separate process — populates cache)
python src/services/scheduler.py

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
    core/         # config.py (pydantic-settings), rate limits, enums
    models/       # Pydantic v2 schemas — the iOS JSON contract
    services/     # Scrapers, business logic, scheduler entry point
    storage/      # Async DiskCache wrapper and cache key definitions
  tests/
    contracts/    # JSON key contract tests — assert exact iOS Codable field names
    models/       # Pydantic validation tests
    services/     # Scraper and scheduler unit tests
    storage/      # Cache layer unit tests
  source/         # Legacy static data files (map, helpful numbers, more links)
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

**Mensa locations:** `sb`, `hom`, `mensagarten`  
**Languages:** `de`, `en`, `fr`

---

## Logging

All output goes through **loguru** with a single uniform format:

```
2026-06-03 10:42:01 | INFO  | src.services.scheduler:57 — fetched news:de → 45 items → cached
2026-06-03 10:42:01 | WARN  | src.services.base_scraper:76 — Attempt 1/3 failed for https://… Retrying in 1.0s
```

Set `LOG_LEVEL` in `.env` (`INFO` default, `TRACE` for full pipeline detail, `WARNING` for quiet).  
Log files: `logs/server.log` — 10 MB rotation, 7-day retention, gzip compression.

---

## Management CLI

```bash
poetry run manage <command>
```

| Command | What it does |
|---|---|
| `manage config` | Show all resolved config values — secrets are masked |
| `manage status` | Scheduler state, every expected cache key, and article body count |
| `manage list` | List every key in the cache with a value summary |
| `manage get <key>` | Pretty-print the JSON stored under a cache key |
| `manage validate` | Deserialize every cache entry against its Pydantic model — reports schema drift |
| `manage clear [key]` | Clear one key or the entire cache (prompts for confirmation) |
| `manage clear --job <job>` | Clear all keys for a job (`news`, `mensa`, `helpful-numbers`, `map`, `articles`) |
| `manage run <job\|all>` | Trigger a scraper job immediately without restarting the scheduler |

---

## Refactor Progress (Phase 2)

Branch: `upgrade/modern-python-server` — the old server on `master` stays running until PR 5 cutover.

| Status | PR | What it delivers |
|---|---|---|
| ✅ Done | PR 1 — Foundation + CI | Poetry stack, Python 3.13, CI pipeline, health endpoint |
| ✅ Done | PR 2 — Data Contracts | Pydantic v2 models, contract tests, iOS field alignment |
| ✅ Done | PR 3 — Scrapers | News/events/mensa/staff scrapers, map and helpful numbers services |
| ✅ Done | PR 4 — Storage + Scheduling | DiskCache async wrapper, APScheduler standalone worker, cold-start scrape, mensa staleness rule |
| ✅ Done | PR 5 — FastAPI Routes | All endpoints (legacy + `/v1/`), per-IP rate limiting, privacy-safe logging, management CLI |
| ⏳ Next | PR 6 — Staff + HelpfulNumbers | TTLCache for search results, HelpfulNumbers KeyError fix |
| ⏳ | PR 7 — Production | Dockerfile, docker-compose, Nginx, Sentry |

---

## Environment Variables

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
