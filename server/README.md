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
    core/         # config.py (pydantic-settings), constants
    models/       # Pydantic v2 schemas — the iOS JSON contract
    services/     # Scrapers, business logic, and scheduler entry point
      scheduler.py      # Standalone worker — run as: python src/services/scheduler.py
    storage/
      cache.py          # Async DiskCache wrapper — all cache reads/writes go here
  tests/
    contracts/    # JSON key contract tests — assert exact iOS Codable field names
    models/       # Pydantic validation tests
    services/     # Scraper, service, and scheduler unit tests
    storage/      # Cache layer unit tests
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

**Mensa locations:** `sb`, `hom`, `mensagarten`  
**Languages:** `de`, `en`, `fr`

---

## Cache Layer

`src/storage/cache.py` wraps DiskCache (SQLite WAL mode) behind an async interface so it never blocks the event loop.

```python
from src.storage.cache import cache

await cache.set_async("news:de", data)
result = await cache.get_async("news:de")  # returns None on cache miss
```

All reads and writes use `asyncio.to_thread()` internally. The module-level `cache` singleton is the only instance used in production. Tests create their own `CacheClient(cache_dir=str(tmp_path))` instances to stay isolated.

**Cache key reference** — used by routes in PR 5 to look up data:

| Key | Set by | Content |
|---|---|---|
| `news:{lang}` | news job | `NewsFeed` dict (lang = `de`/`en`/`fr`) |
| `events:{lang}` | news job | `NewsFeed` dict |
| `mensa:{location}:{lang}` | mensa job | `MensaMenu` dict (12 keys total) |
| `helpful_numbers:{lang}` | helpful numbers job | `HelpfulNumbersResponse` dict |
| `map` | map job | `MapResponse` dict |
| `scheduler:status` | scheduler startup | `"ready"` — written after cold-start attempt |
| `scheduler:last_run:{job}` | each job | ISO 8601 UTC timestamp of last successful run |

A missing key means the first scrape has not run yet or failed. Routes should return a structured `{"available": false}` response (HTTP 503) rather than a 500 when a key is absent — implemented in PR 5.

---

## Scheduler

`src/services/scheduler.py` is a **standalone process** — it is not imported by `main.py` and never runs inside the web container.

```bash
python src/services/scheduler.py   # starts the worker
```

In production (PR 7), Docker Compose runs this as the `worker` service. The `web` service waits for `scheduler:status = "ready"` before accepting traffic.

**Job schedule:**

| Job | Trigger | Scrapes |
|---|---|---|
| `news` | Every 30 min | News + events for `de`, `en`, `fr` (6 cache writes) |
| `mensa` | Daily 06:00 | All 4 locations × 3 languages (12 cache writes) |
| `helpful_numbers` | Daily 07:00 | `de`, `en`, `fr` (3 cache writes) |
| `map` | Daily 08:00 | Single static file read (1 cache write) |

**Cold-start behaviour:**  
On startup, `_initialize()` attempts all four jobs once before the scheduler's interval/cron timers begin. Each job is wrapped in its own `try/except` so a failure in one (e.g. university unreachable) does not skip the others. After all attempts — successful or not — `scheduler:status = "ready"` is written unconditionally so the web container's health check can proceed.

**Failure behaviour:**  
- News, helpful numbers, map: on failure, existing cache is left untouched (yesterday's news is still useful).
- Mensa: on failure, the cache is checked against `scheduler:last_run:mensa`. If the last successful run was not today (UTC), the mensa cache keys are cleared and routes return "unavailable". A week-old menu has no value for users and should not be served.

**APScheduler settings:**  
`misfire_grace_period=60` — if a job is still running when its next trigger fires, allow up to 60 s before treating the missed fire as skipped.  
`max_instances=1` — never queue a second concurrent run of the same job.

**Graceful shutdown:**  
SIGTERM and SIGINT set a stop event. The process then calls `scheduler.shutdown(wait=True)` so any in-progress scrape finishes (or its socket closes) before the process exits.

---

## Logging

All output goes through **loguru** with a single uniform format across every process:

```
2026-06-03 10:42:01 | INFO     | src.services.scheduler:57 — fetched news:de → 45 items → cached
2026-06-03 10:42:01 | WARNING  | src.services.base_scraper:76 — Attempt 1/3 failed for https://… Retrying in 1.0s
2026-06-03 10:42:04 | ERROR    | src.services.scheduler:184 — job:mensa raised during startup — MENSA_API_KEY is not set
```

**Log levels and what each surfaces:**

| Level | When it appears | Examples |
|---|---|---|
| `ERROR` | Job failures, unhandled exceptions | `job:mensa raised during startup — …` |
| `WARNING` | HTTP retries, malformed source data, missing files | `Attempt 2/3 failed for https://… Retrying in 2.0s` |
| `INFO` | Per-language/location data milestones, job lifecycle | `fetched news:de → 45 items → cached`, `job:news done in 3.1s` |
| `DEBUG` | (reserved for future use) | — |
| `TRACE` | Hot-path detail: first-item previews, cache hit/miss, meal/filter counts | `parsed news:de — first item: {…}` |

**Controlling verbosity** — set `LOG_LEVEL` in `.env`:

```bash
LOG_LEVEL=INFO    # default — milestones and warnings only
LOG_LEVEL=TRACE   # full pipeline detail — every cache read/write, first-item previews
LOG_LEVEL=WARNING # quiet — only retries and failures
```

**What `TRACE` shows that `INFO` does not:**
- Every `cache.get_async` / `cache.set_async` call with key, hit/miss, and value summary
- First item of each scraped feed (for verifying parser output without `manage get`)
- Meal details and filter counts per mensa location
- `more:{lang}` source `last_changed` timestamps

**Performance:** TRACE logs in hot paths (cache layer) use `logger.opt(lazy=True)` — string formatting is skipped entirely when TRACE is disabled, so `LOG_LEVEL=INFO` has zero formatting overhead.

**Third-party libraries** (uvicorn, httpx, APScheduler, diskcache) are intercepted via `_InterceptHandler` in `src/core/logging.py` and routed through loguru — their output appears in the same format rather than mixing with stdlib's default handler.

**Log files:** `logs/server.log` — 10 MB rotation, 7-day retention, gzip compression. Created automatically on first run; the `logs/` directory is gitignored.

---

## Management CLI

```bash
poetry run manage <command>
```

| Command | What it does |
|---|---|
| `manage config` | Show all resolved config values — secrets are masked |
| `manage status` | Scheduler state + presence of every expected cache key |
| `manage list` | List every key currently in the cache with a value summary |
| `manage get <key>` | Pretty-print the JSON stored under a cache key |
| `manage clear [key]` | Clear one key, or the entire cache (prompts for confirmation) |
| `manage run <job\|all>` | Trigger a scraper job immediately without restarting the scheduler |

**Jobs available for `manage run`:** `news`, `mensa`, `helpful-numbers`, `map`, `all`

`manage run` re-enables the loguru INFO handler so job progress streams to the terminal in the same uniform format as the server logs — no separate output channel:

```
10:42:01 | INFO     | running job:news
10:42:01 | INFO     | fetched news:de → 45 items → cached
10:42:02 | INFO     | fetched events:de → 12 items → cached
…
10:42:04 | INFO     | job:news done in 3.1s
10:42:07 | INFO     | all jobs done in 6.2s
```

`manage status` output — use this to verify a fresh deployment or diagnose a cold-start failure:

```
── Scheduler ───────────────────────────────────────────
  ✓  scheduler:status                          ready
  ✓  scheduler:last_run:news                   2026-06-03T08:42:01Z
  …

── Data keys ───────────────────────────────────────────
  ✓  news:de                                   dict  2 keys
  ✓  mensa:sb:de                               dict  3 keys
  …
  42/42 data keys populated
```

---

## Refactor Progress (Phase 2)

Branch: `upgrade/modern-python-server` — the old server on `master` stays running until PR 5 cutover.

| Status | PR | What it delivers |
|---|---|---|
| ✅ Done | PR 1 — Foundation + CI | Poetry stack, Python 3.13, CI pipeline, health endpoint |
| ✅ Done | PR 2 — Data Contracts | Pydantic v2 models, contract tests, iOS field alignment |
| ✅ Done | PR 3 — Scrapers | News/events/mensa/staff scrapers, map and helpful numbers services |
| ✅ Done | PR 4 — Storage + Scheduling | DiskCache async wrapper, APScheduler standalone worker, cold-start scrape, mensa staleness rule |
| ✅ Done | PR 5 — FastAPI Routes | All endpoints (legacy + `/v1/`), structured logging, management CLI |
| ⏳ Next | PR 6 — Staff + HelpfulNumbers | TTLCache for search, rate limiting, HelpfulNumbers KeyError fix |
| ⏳ | PR 7 — Production | Dockerfile, docker-compose, Nginx, Sentry |

---

## Known Follow-up Items

These are implementation discoveries that don't change the architecture but need attention before or during their respective PRs.

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
