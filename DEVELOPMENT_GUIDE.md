# UniSaarApp — Development Guide

> For the server refactor plan, see [`server/SERVER_GUIDE.md`](server/SERVER_GUIDE.md).  
> For the full project roadmap, see [`ROADMAP.md`](ROADMAP.md).

---

## Phase 1 — iOS Modernization (COMPLETE)

### Project Boundaries
- Modify files inside `iOSApp/` only.
- Do not touch `server/` or `docs/` during iOS work.
- CocoaPods is permanently removed. Do not suggest it.

### What Was Done
- SPM migration (CocoaPods removed permanently)
- `async/await` throughout — no completion handlers remain
- `@Observable` ViewModels (`Bindable<T>` removed)
- iOS 26 `updateProperties()` lifecycle in all ViewControllers
- `@MainActor` isolation + `Sendable` models + `CacheClient`
- `currentAlert` mutations deferred via `Task { @MainActor [weak self] }` to prevent exclusivity crashes
- CI pipeline: swiftformat --lint → swiftlint --strict → build-for-testing → test-without-building
- 135 tests passing

These decisions are settled. Do not re-litigate Phase 1 architecture.

### Build and Test Commands
```bash
# Build
xcodebuild -project "iOSApp/Uni Saar.xcodeproj" -scheme "Uni Saar" \
  -destination "generic/platform=iOS" CODE_SIGNING_ALLOWED=NO build

# Test
xcodebuild -project "iOSApp/Uni Saar.xcodeproj" -scheme "Uni Saar" \
  -destination "platform=iOS Simulator,name=iPhone 17" \
  CODE_SIGNING_ALLOWED=NO test
```

### Test Style Rules
- Keep explicit per-test `let dataClient` / `let viewModel` setup in every test function.
- No factory helpers or shared setup unless the user explicitly requests them.
- Use the demo data fixtures listed below to seed model and ViewModel test scenarios.

### Demo Data Test TODOs (Phase 1 Debt)
These static fixtures exist in model files but have no test coverage yet. Write tests for them when adding new model or ViewModel test files.

| Model File | Untested Properties |
|---|---|
| `NewsFeedModel` / `NewsModel` | `deomJSON`, `newsDemoData` |
| `MensaMenuModel` | `deomJSON`, `menuDemoData`, `emptyMenuDemoData` |
| `MensaDayModel` | `menuDemoData` |
| `MensaMealsModel` | `mensaDemoData` |
| `MealDetailsModel` | `mealDemoData`, `emptyMealDemoData` |
| `MoreLinksModel` | `deomJSON` |
| `StaffModel` | `deomJSON` |
| `NumberModel` | `deomJSON` |

---

## Phase 3 — SwiftUI Migration (FUTURE, after Phase 2)

### Strategy: Decision Pending WWDC 2026
Do not begin Phase 3 planning until after WWDC 2026 (June 2026). The approach — incremental via `UIHostingController` or full SwiftUI rewrite — depends on NavigationStack improvements and new SwiftUI-only APIs announced at WWDC.

**Why a full rewrite is viable here (unlike most apps):**
- Only 5 main screens
- `@Observable` ViewModels are already SwiftUI-compatible — zero ViewModel refactoring needed either way
- iOS 26 target — SwiftUI on iOS 26 is mature

**What stays true regardless of chosen strategy:**
- The app must remain shippable after every screen migration
- Start with simple read-only screens (Mensa, Helpful Numbers) before complex interactive screens (Staff search, News feed)
- No new `UIViewController` subclasses for migrated screens
- `/v2/` server routes (richer staff data, UI redesign) are part of Phase 3 scope

### Hard Constraint
Do not begin Phase 3 until Phase 2 is merged and the updated `Codable` models are in place. Building new SwiftUI views against drifted API contracts creates rework.
