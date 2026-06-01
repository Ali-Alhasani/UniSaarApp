# UniSaarApp — Project Roadmap

This document gives a high-level view of the full upgrade plan across all phases. For implementation details, see the phase-specific guides.

---

## Project Vision

UniSaarApp is a read-only information hub for students at Saarland University (Mensa menus, news, events, staff directory, campus map, helpful numbers). The upgrade goal is **reliability and data availability** — students should always see useful data, even when the university website is down, and the codebase should be maintainable long-term without heroics.

---

## Phase Overview

| Phase | Scope | Status | Branch |
|---|---|---|---|
| **Phase 1** — iOS Modernization | `iOSApp/` | ✅ Complete | `upgrade/modern-swift` |
| **Phase 2** — Server Refactor | `server/` | 🔄 In Progress | `upgrade/modern-python-server` |
| **Phase 3** — SwiftUI Migration | `iOSApp/` | ⏳ After Phase 2 | TBD |

---

## Phase 1 — iOS Modernization ✅

**What changed for students:** App is faster, more stable, and ready for future iOS versions without breaking changes.

**What changed for the codebase:**
- Swift 6 strict concurrency — eliminates a class of data-race crashes
- `async/await` throughout — readable, debuggable async code
- `@Observable` ViewModels — compatible with both UIKit and SwiftUI
- iOS 26 lifecycle (`updateProperties()`) — future-proof
- 135 automated tests — regressions are caught before they ship
- CI pipeline — every commit is validated automatically

**Detailed guide:** [`DEVELOPMENT_GUIDE.md`](DEVELOPMENT_GUIDE.md)

---

## Phase 2 — Server Refactor 🔄

**What changes for students:** The app loads faster on repeat visits, stays usable when the university website is slow or down, and never shows a broken image or a silent error screen.

**What changes for the codebase:**

| Before | After |
|---|---|
| `BaseHTTPRequestHandler` (legacy) | FastAPI (async, auto-docs) |
| Manual `while True` threads + watchdog | APScheduler `AsyncIOScheduler` |
| BeautifulSoup | selectolax (cleaner CSS selector API) |
| Crashes on `KeyError` | Pydantic validation + graceful fallbacks |
| Pickle cache files + custom `RWLock` | DiskCache (concurrent-safe, persistent) |
| Hardcoded server address / proxy | pydantic-settings + `.env` + `.secrets` |
| `print()` error reporting | loguru + Sentry |
| No CI | ruff → mypy → pytest → docker build |

**Execution strategy:** 7 pull requests using the Strangler Pattern. The old server stays running until PR 5's cutover gate is signed off. The iOS app must work against the new server at every PR boundary.

**Detailed guide:** [`server/SERVER_GUIDE.md`](server/SERVER_GUIDE.md)

### PR Sequence

| Status | PR | Title | Delivers |
|---|---|---|---|
| ✅ | PR 1 | Foundation + CI | Project skeleton, environment config, full CI pipeline |
| ✅ | PR 2 | Data Contracts | Pydantic models, JSON contract tests, iOS field alignment |
| ✅ | PR 3 | Scrapers | httpx RSS + JSON parsers, static file services, offline test fixtures |
| ⏳ | PR 4 | Storage + Scheduling | DiskCache, APScheduler, cold-start scrape, resilient failure handling |
| ⏳ | PR 5 | FastAPI Routes | All API endpoints, cutover gate, traffic switch to new server |
| ⏳ | PR 6 | Staff + Directory | LRU search cache, HelpfulNumbers KeyError fix, image validation |
| ⏳ | PR 7 | Production | Dockerfile, Nginx, docker-compose, Sentry, health endpoint |

### Completed PRs — Actual vs Planned

**PR 1 — Foundation + CI** ✅
- Python minimum set to **3.13** (planned 3.11+) — aligned across pyproject.toml, mypy.ini, ruff.toml, Dockerfile, and CI
- All third-party dependencies bumped to current versions at time of merge (fastapi 0.136, pytest-asyncio 1.4, mypy 2.1, ruff 0.15) — eliminated 8 136 deprecation warnings that would have required `filterwarnings` suppression
- CI split into two independent jobs: `lint` (ruff only, no Poetry) and `test` (mypy → pytest → docker build) — matching project-wide convention established in Phase 1 iOS CI
- Weekly live-scraper validation job (described in SERVER_GUIDE) **not yet implemented** — deferred to a later commit

**PR 2 — Data Contracts** ✅
- Delivered as planned — all 9 Pydantic v2 models, contract tests asserting exact iOS `Codable` field names, datetime format assertions (`Z`-suffix, no microseconds)
- No deviations from SERVER_GUIDE spec

**PR 3 — Scrapers** ✅
- **News and events URL replaced entirely**: university migrated from TYPO3 legacy `?type=9818` query param to TYPO3 EXT:news `/feed.rss` path convention. `LANG_TO_CODE` dict and the old `NEWS_URL`/`EVENTS_URL` format strings removed; replaced with `NEWS_URLS` and `EVENTS_URLS` dicts keyed by language
  - DE news: `.../universitaet/aktuell/news/feed.rss`
  - EN news: `.../en/university/news/news/feed.rss`
  - FR news: `.../fr/universite/actualite/actualites/feed.rss`
  - (events follow the same pattern per language)
- **BaseScraper encoding fallback corrected**: SERVER_GUIDE referenced `apparent_encoding` which does not exist on httpx `Response`; corrected to explicit `iso-8859-1` / `cp1252` decode loop on `response.content`
- **Map and HelpfulNumbers implemented as static file services** (not HTTP scrapers) — reads from `source/` directory; no scheduler job needed for either
- **Old legacy test files not yet deleted** (`tests/DirectoryParserUnitTest.py`, `MensaParserUnitTest.py`, `NewsAndEventsParserUnitTest.py`, `RequestHandlerIntegrationTest.py`, `ServerIntegrationTest.py`, `modelsUnitTest.py`) — deferred to a dedicated cleanup commit
- Code quality improvements applied during review: `Self` return type on `__aenter__`, proper `TracebackType` annotation on `__aexit__`, `datetime.fromisoformat` Z-suffix workaround removed (Python 3.11+), `next_item_id` fallback counter scoped correctly

---

## Phase 3 — SwiftUI Migration ⏳

**Depends on:** Phase 2 complete. Updated `Codable` models must be in place before new SwiftUI views are built.

**What changes for students:** Modern, native iOS UI with smooth animations and better accessibility support.

**Strategy: Decision pending WWDC 2026 (June 2026).** Two options under consideration:

| | Incremental (UIHostingController) | Full SwiftUI Rewrite |
|---|---|---|
| Risk | Low — always shippable | Higher — all-or-nothing until done |
| Code quality | Hybrid UIKit/SwiftUI long-term | Clean, consistent codebase |
| Navigation | Awkward at UIKit/SwiftUI boundaries | Native `NavigationStack` throughout |
| Timeline | Faster to start | Cleaner at the end |

The decision hinges on WWDC 2026 announcements — specifically `NavigationStack` improvements and any new SwiftUI-only APIs. The app is small (5 screens) and `@Observable` ViewModels from Phase 1 are already SwiftUI-compatible, making a full rewrite more viable here than in most apps.

**Regardless of strategy:**
- `/v2/` routes on the server (staff detail redesign) are part of Phase 3
- `@Observable` ViewModels need zero refactoring — they work in both UIKit and SwiftUI
- The app must remain shippable after every screen migration

**Detailed guide:** [`DEVELOPMENT_GUIDE.md`](DEVELOPMENT_GUIDE.md) (Phase 3 section)

---

## Phase Dependencies

```
Phase 1 (iOS)
    └── Phase 2 (Server)
            └── Phase 3 (SwiftUI)
```

Phase 3 cannot begin until Phase 2 API contracts are stable. Starting Phase 3 before that creates rework when the `Codable` models change.

---

## Key Principle Across All Phases

**Incremental and always shippable.** No phase involves a big-bang rewrite. Every PR delivers something working. The app is never broken between phases.
