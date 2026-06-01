# UniSaarApp Server — Refactor Guide (Phase 2)

> For the full project roadmap, see [`ROADMAP.md`](../ROADMAP.md).

---

## Context

The server is a read-only information hub (Mensa, News, Staff, Map, Links). The architectural priority is **reliability and data availability** — if the university website is down, the app must still show last-known data.

The refactor moves from a manual-threading scripting approach to a modular, self-healing architecture using the **Strangler Pattern**: build the new system alongside the old one, never delete the old code until the replacement is proven at every step.

**Branch:** `upgrade/modern-python-server`  
`master` is untouched throughout. The old server stays running until the cutover gate in PR 5 is signed off.

---

## Project Boundaries

- Modify files inside `server/` only.
- Permitted iOS touch-point: `iOSApp/.../NetworkingAndSessionManager/` to align Codable models with updated API contracts.
- Do not touch ViewControllers, storyboards, or any UI logic.

---

## Architecture Decisions (Locked — do not re-litigate)

| Concern | Choice | Reason |
|---|---|---|
| Web framework | FastAPI + Uvicorn | Async by default; native Pydantic integration; auto-docs at `/docs` |
| HTTP client | httpx | Non-blocking; proxy injection; replaces `requests` |
| HTML parsing | selectolax | Cleaner CSS selector API over BeautifulSoup tree traversal |
| Data contracts | Pydantic v2 | Validates at the boundary; aliases map to exact iOS field names |
| Config / secrets | pydantic-settings + `.env` + `.secrets` | `.env` for non-sensitive config, `.secrets` for credentials and hostnames — both gitignored |
| Scheduling | APScheduler 3.x `AsyncIOScheduler` | Runs in a dedicated `worker` container. The `web` container contains no scheduler. `BackgroundScheduler` must not be used. |
| Scheduler isolation | `worker` container (singleton) writes DiskCache; `web` container (N workers) reads DiskCache. Both share the same named Docker volume. | Eliminates APScheduler duplication across workers and retires the `--workers 1` constraint. |
| Persistence | DiskCache | Concurrent read/write safety; replaces `RWLock` + pickle cache files |
| Logging | loguru | Simpler than stdlib `logging`; structured output; file rotation built in |
| Error tracking | Sentry | Alerts when university HTML structure changes and a parser breaks |
| Linting | ruff | Replaces flake8 + isort in one tool |
| Type checking | mypy (strict) | Catches contract drift before runtime |
| Testing | pytest + pytest-asyncio + respx | `respx` mocks httpx transport; zero live network calls in CI |
| Deployment | Docker + Nginx | Multi-stage Dockerfile; Nginx handles SSL + 5-min JSON response cache |
| Packages | Poetry + `pyproject.toml` | Lockfile guarantees reproducible builds |

**Note on selectolax:** The benefit is the cleaner CSS selector API, not raw speed. At this scraping volume (4 pages every 30 minutes), the bottleneck is the network round-trip to the university server, not HTML parsing. Do not oversell the performance argument.

**Note on DiskCache and Phase 3 queries:** DiskCache is a key-value store — it has no query API. All Phase 2 routes work by cache key lookup (`get(f"news:{lang}")`), which fits perfectly. However, if Phase 3 introduces server-side filtering, pagination, or search across stored data (e.g., "return all news items tagged `#campus`"), DiskCache would require loading the entire list into memory and filtering in Python — not a scaling problem at this data volume, but an architectural mismatch. If Phase 3 scope grows to include such queries, evaluate replacing DiskCache with SQLite + SQLModel (same file-based deployment, adds query capability). Make that decision at the start of Phase 3, not mid-implementation.

---

## Non-Negotiable Constraints

1. **Cold-start (non-fatal)**: On `worker` container start, attempt to run all scraper jobs once inside `scheduler.py`'s `main()`. Wrap in `try/except` — if scrapers fail (university unreachable), log the error, fire a Sentry alert, and proceed. The `worker` container must not crash-loop on an unreachable university. After the startup scrape attempt (successful or not), write `scheduler:status = "ready"` to DiskCache so the `web` container's health check can proceed. The `web` container's FastAPI lifespan does **not** run any scrapers — it only starts the app and reads from DiskCache.
2. **Persistent cache volume**: `CACHE_DIR` must be mounted as a named Docker volume in `docker-compose.yml`. Cache must never live inside the container filesystem. This ensures cached data survives container recreations and deployments — so even if the university is unreachable during a cold-start, the server serves last-known data instead of an empty response.
3. **Empty cache handling**: Routes must return a structured "data currently unavailable" response (not a 500) when a cache key is missing. This covers the edge case of a brand-new first deployment where no persistent cache exists yet and the startup scrape failed.
4. **Scheduler/web isolation**: The `web` container runs `uvicorn src.main:app --workers 4` and only reads from DiskCache — it contains no APScheduler instance. The `worker` container runs `python src/services/scheduler.py` as a singleton and only writes to DiskCache. APScheduler must never run inside the `web` container. DiskCache (SQLite WAL mode) is safe for one writer + multiple readers across processes.
5. **API versioning strategy**: Three route generations, all served from the same cache handlers:
   - **`/getNews`** (no prefix) — legacy paths, kept alive permanently so the current iOS app never breaks
   - **`/v1/getNews`** — Phase 3 SwiftUI migration paths, same data contract as legacy
   - **`/v2/staff/search`** — Phase 3 screens requiring UI redesign (e.g., richer staff data with new fields). New Pydantic model, new route. Old `/staff/search` stays untouched until the new iOS screen ships.
   
   In Phase 2, register both legacy and `/v1/` paths on the same handler. No redirects. No iOS changes required.
6. **Strangler rule**: The iOS app must work against the new server at every PR boundary — not just at the final PR.
7. **Cache resilience**: A failed scraper job logs the error and leaves the cache completely untouched. Never wipe cache on failure.
8. **Alias-first field naming**: Before writing any Pydantic model, read the existing iOS `Codable` models (`iOSApp/.../NetworkingAndSessionManager/`) to extract the exact JSON key names the app currently decodes. Those names become the `serialization_alias` values. The Python attribute names (snake_case) are internal only.
9. **`response_model_by_alias=True` on every route**: FastAPI defaults to serializing Python field names, not aliases. Every route decorator must include `response_model_by_alias=True`, otherwise the iOS `Codable` models will silently fail to decode. This must be enforced via a contract test, not assumed.
10. **Pydantic v2 syntax**: Use `model_config = ConfigDict(populate_by_name=True)`. The `class Config` pattern is Pydantic v1 and must not be used.
11. **FastAPI lifespan**: Use `@asynccontextmanager` lifespan pattern — `@app.on_event("startup")` is deprecated in modern FastAPI. The lifespan context does **not** run any scrapers — startup scraping is the `worker` container's responsibility. The lifespan only starts the app and, optionally, logs that the `scheduler:status` key is present in DiskCache.
12. **Staff LRU cache**: Use `cachetools.TTLCache` — `functools.lru_cache` is synchronous and silently breaks in async context.
13. **Staff search input validation**: Reject queries shorter than 3 characters with HTTP 400 before any proxy call is made. Single and double character queries bypass the TTLCache (every query is unique) and directly hammer the university server.
14. **Staff search rate limiting**: Apply two layers — Nginx `limit_req` at the network level (blocks before Python runs) and `slowapi` at the FastAPI route level for per-IP granularity. Rate limit only `/v1/staff/search`, not the cache-backed routes.
15. **Image HEAD validation concurrency** *(applies only if Option B is chosen in PR 6 — see PR 6 notes)*: Run HEAD checks with `asyncio.gather` bounded by `asyncio.Semaphore(5)` with a 2.5-second timeout per request. On timeout or network error, **keep the URL** (optimistic default — transient failures should not discard valid images). Only confirmed non-200 responses set the URL to `null`. If Option A (iOS-side fallback) is chosen instead, this constraint is superseded and the `validate_images` function is removed.
16. **DiskCache writes are blocking**: DiskCache uses SQLite under the hood — its read/write operations are synchronous and block the event loop. Wrap all DiskCache operations in `asyncio.to_thread()` inside `src/storage/cache.py`. Expose only async methods (`set_async`, `get_async`) so the rest of the codebase never calls blocking cache operations directly from async context.
17. **HTML encoding in BaseScraper**: Always pass decoded strings to `selectolax.HTMLParser`, never raw bytes. Use `response.text` (httpx decodes via response headers). If the result looks garbled — a real risk for German university pages that serve ISO-8859-1 or Windows-1252 with missing or incorrect charset headers — fall back by trying `iso-8859-1` then `cp1252` directly on `response.content`. `httpx` does not expose `apparent_encoding`; charset detection must be done explicitly.
18. **Language-scoped cache keys**: News, Events, Mensa, and HelpfulNumbers all have `de`, `en`, `fr` variants. Cache keys must encode the language: `news:de`, `news:en`, `news:fr`. Routes accept a `?lang=` query param (default `de`). Scrapers run once per language per scheduled job. The `NEWSFEED_LANGUAGES = ['de', 'en', 'fr']` and `MENSA_LANGUAGES = ['de', 'en', 'fr']` constants from the old server define the full set.
19. **Mensa location-scoped cache keys**: The server scrapes 4 canteen locations (`sb`, `hom`, `forum`, `mensagarten`). Combined with 3 languages, Mensa has 12 cache keys: `mensa:{location}:{lang}`. The `/v1/getMensa` route accepts `?location=sb&lang=de`. All 4 locations × 3 languages must be populated on startup scrape and refreshed by the scheduler.
20. **Every route version gets its own contract tests**: When `/v2/` routes are added in Phase 3, they must include new contract tests in the same PR asserting the new response shape. The existing `/v1/` and legacy contract tests continue running unchanged — if a `/v2/` implementation accidentally drifts a `/v1/` response, the existing tests catch it. No separate parity test file needed; same-handler dual-path routing makes those redundant.
21. **DateTime serialization must produce `Z`-suffix ISO 8601**: iOS `JSONDecoder` with `.iso8601` strategy only accepts `"2024-01-15T10:30:00Z"` — not `+00:00`, not microseconds. Pydantic v2 defaults to `+00:00`. Override this on every `datetime` field using a custom serializer or `field_serializer`. Contract tests must explicitly assert the format: `assert serialized["eventDate"].endswith("Z")`.
22. **Normalize whitespace in all scraped text**: German university pages use `\xa0` (non-breaking space) in prices, table cells, and names. All text extracted via selectolax must pass through a `clean_text()` utility before being stored. Silently reaching iOS, `\xa0` causes string comparison failures and renders visibly wrong. Implement once in `BaseScraper`, use everywhere: `node.text(deep=True).strip().replace('\xa0', ' ')`.

---

## Environment Variables

Config is split across two files loaded by `pydantic-settings` in order — `.secrets` values override `.env`:

```python
model_config = SettingsConfigDict(
    env_file=['.env', '.secrets'],
    env_file_encoding='utf-8'
)
```

**`.env`** — non-sensitive configuration. Gitignored in all environments.
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

**`.secrets`** — sensitive values. Gitignored. Never logged. Never baked into a Docker image layer.
```bash
SERVER_ADDRESS=                   # University server hostname
PROXY_URL=                        # proxy.cs.uni-saarland.de:3128 on university server, empty locally
SENTRY_DSN=                       # Leave empty to disable Sentry locally
SMTP_HOST=                        # Email alert host (if used)
SMTP_USER=                        # Email credentials
SMTP_PASSWORD=                    # Email credentials
```

**Committed files:** `.env.example` and `.secrets.example` with all keys present and values empty.  
**Gitignored:** `.env` and `.secrets`.  
**Rule:** If a value would be embarrassing in a public GitHub commit, it belongs in `.secrets`, not `.env`.

---

## Directory Structure

```
server/
  src/
    api/          # FastAPI routers — one file per resource
    core/         # config.py (pydantic-settings), constants
    models/       # Pydantic v2 schemas — the JSON contract
    services/     # Scrapers, business logic (date offsets, Mensa time rules)
    storage/      # DiskCache wrapper, cache key definitions
  tests/
    fixtures/     # Committed HTML snapshot files for offline scraper tests
    contracts/    # JSON key contract tests (assert iOS field name alignment)
    models/       # Pydantic validation tests
    api/
      test_routes.py           # Functional route tests per version
  pyproject.toml
  .env.example
  .secrets.example
  Dockerfile
  docker-compose.yml
  nginx.conf
```

---

## 7-PR Roadmap

---

### PR 1 — Foundation + CI
**Goal:** Infrastructure and pipeline exist before any feature code. CI is green on an empty test suite.

**What gets built:**
- `pyproject.toml`: Poetry, Python 3.13+, all dependencies pinned to current versions — includes `slowapi` (staff search rate limiting)
- Full `src/` directory skeleton
- `src/core/config.py` (pydantic-settings): loads `.env` first, then `.secrets` (secrets override env). Sensitive values (`SERVER_ADDRESS`, `PROXY_URL`, `SENTRY_DSN`, credentials) live only in `.secrets` — immediately solves the hardcoded server address and commented-out `localhost` in `Constants.py`
- loguru: console + rotating file output
- `ruff.toml` + `mypy.ini` (strict mode)
- `.pre-commit-config.yaml`: ruff + mypy gates before every commit
- `.env.example` and `.secrets.example` committed with all keys and empty values; `.env` and `.secrets` gitignored
- GitHub Actions (runs on every PR): two jobs — `lint` (`ruff format --check` + `ruff check`, Python only, no Poetry) and `test` (`mypy` → `pytest`, needs lint) → `docker build` (needs test)
- GitHub Actions (runs weekly on schedule): live scraper validation — runs all scrapers against real university URLs, validates output against Pydantic models (not just assert no exceptions), fails the job if any model field is missing or mistyped. This catches HTML structure changes before students encounter broken data.
- `tests/conftest.py` skeleton

**Exit condition:** CI pipeline is green. `uvicorn src.main:app` starts and `/v1/health` returns 200. Nothing else works yet.

---

### PR 2 — Data Contracts
**Goal:** Define the JSON law. Every downstream component must produce data that conforms to these models.

**What gets built:**

Step 0 (before writing any model): Read `iOSApp/.../NetworkingAndSessionManager/` and extract the exact JSON key names each `Codable` struct currently decodes. Build a mapping table like the one below — this becomes the authoritative alias reference for the entire PR.

| Python attribute | `serialization_alias` (current iOS key) |
|---|---|
| `published_date` | `date` |
| `image_url` | `image` |
| `meal_price` | `price` |
| *(complete during PR 2 by reading actual iOS Codable files)* | |

- All 9 Pydantic models: `News`, `Event`, `MensaMeal`, `StaffItem`, `Map`, `More`, `Category`, `NewsFeed` (pagination wrapper), `HelpfulNumbers`
- Every model: `model_config = ConfigDict(populate_by_name=True)`
- `serialization_alias` on every field that has a different iOS key name — derived from the mapping table above, not guessed
- **Language decision made here**: News, Events, Mensa, HelpfulNumbers models include a `lang: Literal['de', 'en', 'fr']` field. Routes accept `?lang=de` (default). Cache keys are language-scoped (`news:de`, etc.).
- **Mensa location decision made here**: `MensaMeal` includes a `location: Literal['sb', 'hom', 'forum', 'mensagarten']` field. Route accepts `?location=sb&lang=de`. Cache key format: `mensa:{location}:{lang}`.
- **`More` tab note**: `More` model is not scraped — it reads from static files in `source/links_for_more_tab/`. The `/v1/getMore` route serves these directly. No scheduler job needed.
- **Academic calendar note**: PDF files live in `academic_calendar/`. A `/v1/calendar/{filename}` route serves them as static files. No scraping, no caching needed.
- **iCal decision made here** (not deferred): either include `ics_url` in `Event` model or explicitly drop the endpoint with a note. Deferring this to PR 5 causes breaking changes.
- `tests/models/`: validation tests covering malformed data, missing optional fields, currency string → float conversion

**Contract tests:**
- `tests/contracts/`: serialize each model with `model_dump(by_alias=True)`, assert the **exact JSON key names** in the output match the iOS `Codable` property names from the mapping table
- These tests catch `response_model_by_alias=True` being accidentally omitted from a route — the most likely integration failure point
- These are the automated guarantee the Strangler Pattern holds — a drifted field name fails here, not in the running app
- **DateTime format assertions required**: for every model with a date or datetime field, explicitly assert the serialized format matches what iOS `JSONDecoder` accepts:
  ```python
  assert serialized["eventDate"].endswith("Z")        # not "+00:00"
  assert "." not in serialized["eventDate"]            # no microseconds
  assert serialized["publishedDate"] == "2024-01-15"  # date-only fields: plain ISO 8601 date
  ```

**Existing test migrated:** `modelsUnitTest.py` → `tests/models/`

**Exit condition:** `pytest tests/models/ tests/contracts/` passes with zero network calls. Mapping table is complete and committed.

---

### PR 3 — Scrapers
**Goal:** Parse university HTML into validated Pydantic models. Never hits live network in CI.

**What gets built:**
- Abstract `BaseScraper`: httpx + 3-attempt exponential backoff retry + proxy injected from `config.py`
- Encoding handling in `BaseScraper.fetch()`: always use `response.text` (decoded via HTTP headers). If the result looks garbled — a real risk for German university pages that serve ISO-8859-1 with missing charset headers — fall back by trying `iso-8859-1` then `cp1252` on `response.content`. Pass only decoded strings to `HTMLParser`, never raw bytes:
  ```python
  html = response.text
  if "â€" in html or "Ã" in html:  # garbled encoding indicators
      for enc in ("iso-8859-1", "cp1252"):
          try:
              candidate = response.content.decode(enc)
              if "â€" not in candidate and "Ã" not in candidate:
                  html = candidate
                  break
          except (UnicodeDecodeError, LookupError):
              pass
  tree = HTMLParser(html)
  ```
- Whitespace normalization utility in `BaseScraper` — used on every text extraction. `\xa0` (non-breaking space) is common in German university pages inside prices, names, and table cells; it silently breaks iOS string rendering:
  ```python
  @staticmethod
  def clean_text(node) -> str:
      return node.text(deep=True).strip().replace('\xa0', ' ')
  ```
  Use `BaseScraper.clean_text(node)` everywhere instead of `node.text()` directly.
- selectolax parsers:
  - News + Events: one scrape run per language (`de`, `en`, `fr`) → 3 runs per job
  - Mensa: one scrape run per location × language (`sb/de`, `sb/en`, `sb/fr`, `hom/de`, ...) → 12 runs per job. Fixture files committed for each combination.
- Staff: async pass-through proxy (real-time search — directory is too large to pre-scrape)
- `tests/fixtures/`: committed HTML snapshot files for each scraper — at minimum one fixture per language for News/Events, one per location for Mensa
- `respx` mocks for httpx transport — scrapers tested against fixtures, not live URLs
- Business logic extracted into `services/date_service.py`: Mensa time-offset rules (after 14:00 show tomorrow, weekend shows Monday), decoupled from scraper and testable independently

**Existing tests migrated:**
- `MensaParserUnitTest.py` → `tests/services/test_mensa_scraper.py`
- `NewsAndEventsParserUnitTest.py` → `tests/services/test_news_scraper.py`
- `DirectoryParserUnitTest.py` → `tests/services/test_directory_scraper.py`

**Exit condition:** All scraper tests pass offline. Scrapers return valid Pydantic models or raise typed exceptions.

---

### PR 4 — Storage + Scheduling
**Goal:** Cache is the source of truth. Scraping never happens on the request path.

**What gets built:**
- DiskCache storage layer: replaces `cached_events/*.cache` and `ReadWriteLock.py` (deleted)
- `src/storage/cache.py` exposes only async methods — all DiskCache reads and writes wrapped in `asyncio.to_thread()` to prevent blocking the event loop. Configured with an explicit timeout to reduce SQLite lock contention during concurrent access:
  ```python
  import diskcache

  cache = diskcache.Cache(directory=settings.CACHE_DIR, timeout=10)

  async def set_async(self, key: str, value: Any) -> None:
      await asyncio.to_thread(self._cache.set, key, value)

  async def get_async(self, key: str) -> Any:
      return await asyncio.to_thread(self._cache.get, key)
  ```
- `src/services/scheduler.py` is now a **standalone entry point** — not imported by `main.py`. The worker container runs it directly:
  ```python
  async def main() -> None:
      scheduler = AsyncIOScheduler()
      # register all jobs with their cron/interval triggers
      scheduler.start()
      # startup scrape attempt — non-fatal
      try:
          await run_all_jobs_once()
      except Exception as exc:
          logger.error(f"Startup scrape failed: {exc}")
          sentry_sdk.capture_exception(exc)
      # signal readiness regardless of startup scrape outcome
      await cache.set_async("scheduler:status", "ready")
      await asyncio.Event().wait()  # run forever

  if __name__ == "__main__":
      asyncio.run(main())
  ```
- After each scheduled job completes successfully, write a heartbeat key:
  ```python
  await cache.set_async(f"scheduler:last_run:{job_name}", datetime.utcnow().isoformat() + "Z")
  ```
- Job schedule (unchanged from original plan):
  - News: every 30 minutes — runs for `de`, `en`, `fr` (3 scrapes per cycle)
  - Mensa: daily at 06:00 — runs for all 4 locations × 3 languages (12 scrapes per cycle)
  - HelpfulNumbers: daily — runs for `de`, `en`, `fr`
  - Map: daily (language-independent, single scrape)
- `main.py` lifespan: scraping removed entirely — contains only `yield`. The web container's startup is instant; it does not wait for scrapers.
- Failure behavior: log error + Sentry alert, cache data unchanged — old data always preserved
- `CACHE_DIR` is env-configurable; must be a mounted volume in production (enforced in PR 7)

**What gets tested:**
- Assert `scheduler:status = "ready"` is written after `main()` initialization, even when startup scrape fails
- Assert heartbeat keys (`scheduler:last_run:{job_name}`) are written after each job fires
- Simulate scraper failure in `scheduler.py` startup → assert `scheduler:status = "ready"` still written, cache retains previous data
- Simulate scraper failure on scheduled job → assert cache retains previous data (never wiped)
- Mock scheduler clock → verify job fires, updates cache, writes heartbeat key
- Assert route returns structured "unavailable" response when cache key is missing (not 500)

**Exit condition:** Cold start with reachable university populates all cache keys and writes `scheduler:status = "ready"`. Simulated startup failure still writes the ready key and retains old data. `main.py` lifespan contains no scraping. `ReadWriteLock.py` deleted.

---

### PR 5 — FastAPI Routes (Cutover PR)
**Goal:** Replace `BaseHTTPRequestHandler`. The iOS app must not notice the engine changed.

**What gets built:**
- Each route registered on **two paths** — legacy (no prefix) and versioned (`/v1/`) — served by the same handler from the same cache key. No redirects, no iOS changes required.
  ```python
  @router.get("/getNews")
  @router.get("/v1/getNews")
  async def get_news(lang: str = "de"):
      return await cache.get_async(f"news:{lang}")
  ```
- Full route list (each registered on both paths):
  - `GET /getNews` + `/v1/getNews?lang=de`
  - `GET /getEvents` + `/v1/getEvents?lang=de`
  - `GET /getMensa` + `/v1/getMensa?location=sb&lang=de`
  - `GET /getMap` + `/v1/getMap`
  - `GET /getMore` + `/v1/getMore` — serves static files from `source/links_for_more_tab/`, no cache lookup
  - `GET /calendar/{filename}` + `/v1/calendar/{filename}` — serves PDFs from `academic_calendar/` as static files
  - `GET /v1/health` — new, no legacy equivalent needed. Reads `scheduler:status` and `scheduler:last_run:{job_name}` keys from DiskCache. Reports: uptime, per-endpoint cache freshness timestamps, volume mount status. Does **not** call APScheduler directly — the scheduler runs in a separate process.
- Routes are **cache readers only** — zero scraping on the request path
- Every route decorator must include `response_model_by_alias=True`
- Empty cache handling: missing cache key → `{"available": false, "reason": "data_pending"}` with HTTP 503
- Compatibility middleware: `Content-Type` and all response headers match the old server exactly
- iCal endpoint: keep or drop per PR 2 decision — if kept, register on both `/events/iCal` and `/v1/events/iCal`
- **No iOS changes in Phase 2.** Current iOS app continues hitting `/getNews` etc. and receives cache-backed responses from the new stack, unaware the engine changed.
- **Dual-path fallback logging middleware**: during the cutover period, log legacy path hits and add a `X-Route-Generation` response header so traffic distribution is visible in logs and in the iOS network inspector (Charles Proxy, Instruments):
  ```python
  @app.middleware("http")
  async def route_generation_middleware(request: Request, call_next):
      response = await call_next(request)
      path = request.url.path
      if not path.startswith("/v1/") and not path.startswith("/v2/"):
          logger.info(f"Legacy path hit: {path}")
          response.headers["X-Route-Generation"] = "legacy"
      else:
          response.headers["X-Route-Generation"] = path.split("/")[1]  # "v1" or "v2"
      return response
  ```
  Remove this middleware after the cutover is confirmed and the legacy paths are archived.
- `/v2/` routes are Phase 3 only — staff detail redesign and any other endpoints requiring new data fields and UI changes. Do not add `/v2/` routes in this PR.
- `tests/api/test_routes.py`: verifies both legacy and `/v1/` paths return 200 with correct content-type and cache behavior. When `/v2/` routes are added in Phase 3, new contract tests for the `/v2/` response shape are added in the same PR — existing `/v1/` and legacy contract tests keep running and catch any accidental drift.

**Existing tests migrated:**
- `RequestHandlerIntegrationTest.py` → `tests/api/test_routes.py`
- `ServerIntegrationTest.py` → `tests/api/test_integration.py`

**Cutover gate — all must pass before merging:**
- Current iOS app (unmodified) pointed at new server on test port
- All screens load correctly on legacy paths: no missing fields, no broken images, no 500 errors
- `/v1/` paths return identical responses to legacy paths
- Response time ≤ old server (cache-only routes should be faster)
- Contract tests still green

**Cutover procedure:**
1. New server running on alternate port alongside old one
2. Gate signed off → switch traffic (DNS or reverse proxy)
3. Old server stays running for 48 hours as fallback
4. Old code archived to `legacy/server-v1` branch — not deleted

**Exit condition:** Unmodified iOS app works against new server on legacy paths. `/v1/` paths verified identical. CI green. Cutover gate signed off.

---

### PR 6 — Staff Directory & Helpful Numbers
**Goal:** Async search with LRU cache. Fix the existing `KeyError` crash.

**What gets built:**
- Async search proxy registered on both `/staff/search` and `/v1/staff/search`
- `cachetools.TTLCache` (24h TTL): 50 students searching "Professor X" → university server hit once
- Input validation: queries shorter than 3 characters return HTTP 400 immediately — no proxy call made
- Rate limiting on both paths: `slowapi` decorator for per-IP limits in FastAPI; Nginx `limit_req` configured in PR 7 as the network-layer backstop
- **`/v2/staff/search` is Phase 3 only** — richer response fields (office, photo, full bio) will require a staff detail UI redesign. Do not implement in Phase 2. Current `StaffItem` model stays unchanged.
- HelpfulNumbers `KeyError` fix: missing keys log a warning and return partial data — server never crashes on malformed source data
- **Image URL HEAD validation — academic server risk**: University servers commonly block automated HEAD requests with 403 or drop them silently (causing a timeout). With a 2.5-second timeout window, a brief server blip during the staff scrape can set the entire batch of image URLs to `null` — they remain `null` until the next scheduled scrape (potentially 24 hours).

  Two mitigations, **choose one in PR 6**:

  **Option A — iOS-side graceful fallback (recommended):** Remove server-side HEAD validation entirely. Store every image URL as scraped. The iOS `UIImageView` already handles 404s gracefully — show a placeholder avatar on load failure. This is simpler, eliminates the risk window entirely, and is consistent with how modern mobile apps handle remote images. If chosen, remove the `validate_images` function and store `image_url` directly from the scraped HTML.

  **Option B — User-Agent injection:** Inject a realistic browser `User-Agent` header in the HEAD request. This works if the university blocks bot-detected requests but not browser-appearing ones. Less reliable than Option A — the server can change its detection at any time.

  If Option B is chosen, the reference implementation below applies. If Option A is chosen, delete it.

- Image URL HEAD validation (Option B only): bounded by `asyncio.Semaphore(5)` with a 2.5-second timeout per request
  - Confirmed non-200 response → store `null`
  - Timeout or network error → **keep the URL** (optimistic: transient failures must not silently discard valid images)

```python
async def validate_image(client: httpx.AsyncClient, url: str, sem: asyncio.Semaphore) -> str | None:
    async with sem:
        try:
            r = await asyncio.wait_for(client.head(url, follow_redirects=True), timeout=2.5)
            return url if r.status_code == 200 else None
        except (httpx.HTTPError, asyncio.TimeoutError):
            return url  # optimistic: keep on transient failure

async def validate_images(urls: list[str]) -> list[str | None]:
    sem = asyncio.Semaphore(5)
    async with httpx.AsyncClient() as client:
        return await asyncio.gather(*[validate_image(client, u, sem) for u in urls])
```

**What gets tested:**
- Assert TTLCache hit/miss behavior on repeated identical searches
- Assert query < 3 chars returns 400 without making any outbound request
- Assert rate limiter fires after threshold is exceeded
- Simulate `KeyError` in source HelpfulNumbers data → assert partial response returned, no exception raised
- HEAD validation: confirmed 404 → `null`; simulated timeout → URL preserved; semaphore limits concurrent requests to 5

**Exit condition:** Common staff searches cache correctly. Short queries and rate-limit violations return correct error codes. No crashes on malformed HelpfulNumbers data. Image validation never silently discards URLs due to transient timeouts.

---

### PR 7 — Production Readiness
**Goal:** Deployable on the university server. Operational from day one.

**What gets built:**
- Multi-stage `Dockerfile` (shared by both services): build stage + slim runtime stage. Both containers run under the same non-root UID/GID to avoid SQLite permission errors on the shared volume:
  ```dockerfile
  RUN groupadd -g 10001 appgroup && \
      useradd -u 10001 -g appgroup -m -s /bin/bash appuser
  USER 10001
  ```
  If `worker` creates the DiskCache files as root and `web` runs as a non-root user, SQLite will raise `OperationalError: attempt to write a readonly database` when `web` tries to acquire a WAL lock file. Explicit UID alignment prevents this.
- `nginx.conf`: SSL termination + 5-minute JSON response cache (Nginx absorbs repeat requests; Python is never touched) + `limit_req_zone` rate limiting on `/v1/staff/search`. Match Nginx `limit_req` thresholds to the `slowapi` limits set in PR 6 — if Nginx is too tight it blocks legitimate clients before `slowapi` can respond with a proper 429; if too loose, Uvicorn workers waste cycles on requests that should have been rejected at ingress.
- `docker-compose.yml` — two-service architecture sharing a named volume:
  ```yaml
  volumes:
    cache_data:

  services:
    worker:
      build: .
      command: python src/services/scheduler.py
      volumes:
        - cache_data:/app/.cache
      env_file:
        - .env
        - .secrets
      healthcheck:
        test: ["CMD", "python", "-c",
               "import diskcache; c = diskcache.Cache('/app/.cache'); assert c.get('scheduler:status') == 'ready'"]
        interval: 10s
        timeout: 5s
        retries: 12        # allows up to 2 minutes for startup scrape

    web:
      build: .
      command: uvicorn src.main:app --host 0.0.0.0 --port 3000 --workers 4
      volumes:
        - cache_data:/app/.cache
      env_file:
        - .env
        - .secrets
      ports:
        - "3000:3000"
      depends_on:
        worker:
          condition: service_healthy

    nginx:
      image: nginx:alpine
      volumes:
        - ./nginx.conf:/etc/nginx/nginx.conf:ro
      ports:
        - "80:80"
        - "443:443"
      depends_on:
        - web
  ```
  `web` blocks on `worker: service_healthy` — the cache is guaranteed to be populated before the first request is served. Cache data survives container recreations. DiskCache (SQLite WAL mode) is safe for one writer (`worker`) + multiple readers (`web` workers) across processes.
- Sentry DSN injected via `.secrets` — never hardcoded, never in `.env`
- `docker build` smoke test added to CI

**Exit condition:** `docker compose up` starts `worker` (scrapes, writes cache, sets `scheduler:status = "ready"`), then starts `web` (4 workers, reads cache only). `web` blocks until `worker` is healthy. Container recreations do not lose cache data. `/v1/health` reports all caches populated and all scheduler jobs have run. No `--workers 1` constraint.

---

## Build and Test Commands

```bash
# Install dependencies
poetry install

# Run (development, with auto-reload)
uvicorn src.main:app --reload

# Run tests (no live network)
pytest tests/ -v

# Lint
ruff check src/ tests/

# Type check
mypy src/

# Run pre-commit on all files
pre-commit run --all-files
```

---

## Key File Reference

| File | Purpose |
|---|---|
| `src/core/config.py` | All environment-aware config (proxy, ports, secrets) |
| `src/storage/cache.py` | DiskCache wrapper — single source of truth for cached data |
| `src/services/scheduler.py` | Standalone entry point (`python src/services/scheduler.py`). Runs `AsyncIOScheduler`, startup scrape, and heartbeat writes. Not imported by `main.py`. |
| `src/main.py` | FastAPI app + lifespan context. Cache reader only — no scraping, no scheduler. |
| `tests/contracts/` | JSON contract tests — must pass before any API route change merges |
| `tests/fixtures/` | Committed HTML snapshots — scrapers never need live network in CI |
