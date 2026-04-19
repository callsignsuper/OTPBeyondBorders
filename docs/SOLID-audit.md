# SOLID audit — v1 bootstrap

Audit date: 2026-04-19. Scope: [OTPKit/](../OTPKit/) domain package and [App/](../App/) iOS target. Widget and watch targets are thin shells with no independent logic and are not audited separately.

Verdict summary: **broadly compliant**. Two minor violations flagged for follow-up, both in [FlightDetailView.swift](../App/Sources/Flights/FlightDetailView.swift). No structural rework needed for v1.

---

## S — Single Responsibility

**Compliant.** Each OTPKit type has one reason to change:

| Type | Responsibility |
|---|---|
| [CountdownEngine](../OTPKit/Sources/OTPKit/Engine/CountdownEngine.swift) | Compute countdown state from flight + timeline + clock. |
| [AIMSNotesParser](../OTPKit/Sources/OTPKit/Parsing/AIMSNotesParser.swift) | Parse AIMS eCrew note bodies into a typed result. |
| [TimelineLoader](../OTPKit/Sources/OTPKit/Loading/TimelineLoader.swift) | Decode a JSON timeline from a bundle. |
| [CBPResolver](../OTPKit/Sources/OTPKit/Resolvers/CBPResolver.swift) | Decide if a destination triggers CBP today. |
| [AircraftResolver](../OTPKit/Sources/OTPKit/Resolvers/AircraftResolver.swift) | Resolve a flight number to an aircraft category. |
| [Milestone](../OTPKit/Sources/OTPKit/Models/Milestone.swift), [Timeline](../OTPKit/Sources/OTPKit/Models/Timeline.swift), [Flight](../OTPKit/Sources/OTPKit/Models/Flight.swift) | Plain value types with validation helpers only. |

On the app side:

- [CalendarImporter](../App/Sources/Calendar/CalendarImporter.swift) composes EventKit + `AIMSNotesParser` + `AircraftResolver` — that's a legitimate use-case orchestration, not a responsibility violation.
- [FlightStore](../App/Sources/Store/FlightStore.swift) manages in-memory flight state and delay logs. For v1 with no persistence, fine. When SwiftData lands, split into `FlightRepository` (persistence) + `FlightListViewModel` (UI state).

### Violations noted

**[FlightDetailView.swift:54](../App/Sources/Flights/FlightDetailView.swift#L54)** instantiates `TimelineLoader()`, `CBPResolver()`, and `CountdownEngine()` inside the view. The view knows too much about how state is built. Fix when persistence lands: pass a `CountdownViewModel` into the view.

## O — Open/Closed

**Compliant for the dimensions that actually matter.** The extension surfaces are:

- **Adding a new aircraft category** requires editing the [AircraftCategory enum](../OTPKit/Sources/OTPKit/Models/AircraftCategory.swift), adding a JSON file, and mapping a case in `resourceBasename`. That's three edits, but they're all at the boundary and each one is independently reviewable. Acceptable.
- **Adding a new role** requires editing [Role.swift](../OTPKit/Sources/OTPKit/Models/Role.swift) and updating the Etihad JSON owners. The timeline JSONs are the source of truth for which roles exist per milestone — engine and UI consume this data without caring which roles exist. ✓
- **Adding a new CBP airport** is JSON-only. ✓
- **Adding a new IATA delay code** is JSON-only. ✓
- **Changing a milestone's time** is JSON-only. ✓

The engine itself treats milestones as opaque data. No switch statement inside the engine needs editing to add milestones. ✓

## L — Liskov Substitution

**N/A for most of the code** — value types, not subtyping. Where protocols exist:

- [OTPClock](../OTPKit/Sources/OTPKit/Engine/Clock.swift) has `SystemClock` and `FixedClock` conformances. Both honor the same contract (`now() -> Date`). No preconditions differ. ✓

## I — Interface Segregation

**Compliant.** Protocols are single-method (`OTPClock.now()`) or absent. Consumers don't depend on symbols they don't use.

One mild note: [FlightStore](../App/Sources/Store/FlightStore.swift) exposes `flights`, `delayLogs`, `nextFlight`, `upsert`, `toggleMilestone`, `logDelay`. A widget that only reads `nextFlight` is forced to depend on the whole store. For v1 we don't have that integration yet (App Groups not wired), so segregation can happen when the widget starts sharing state.

## D — Dependency Inversion

**Mostly compliant.**

- `CountdownEngine` and `AIMSNotesParser` take pure inputs — no globals, no hidden Bundle access. ✓
- Loaders accept an injectable `Bundle` via `init(bundle:)` for tests. ✓
- `CBPResolver` and `AircraftResolver` accept prebuilt data via `init(airports:)` / `init(fleetMap:)` for testing. ✓
- `SystemClock` / `FixedClock` invert clock access. ✓

### Violations noted

**[FlightDetailView.swift:85–91](../App/Sources/Flights/FlightDetailView.swift#L85)** constructs loaders directly (`TimelineLoader()`, `CBPResolver()`). The view imports and depends on concrete loader classes rather than a view-model that exposes the already-loaded data. Same fix as the SRP note: extract a `FlightDetailViewModel` that the view observes, and let the viewmodel hold the collaborators.

---

## Follow-up items (tracked, not v1 blockers)

1. Extract `FlightDetailViewModel` — addresses both SRP and DIP notes above. Estimated effort: ~1h including test.
2. When App Group + widget storage lands, split `FlightStore` into `FlightRepository` (persistence) and view-model(s) that consume it.
3. When SwiftData lands, the repository protocol is the seam to test against — unit tests shouldn't touch a real ModelContainer.

## How to verify these claims

- `swift test` in OTPKit (40 passing tests) proves engine/parser/resolver/loader are pure and driven purely by their inputs.
- The Swift 6 strict-concurrency flag in [OTPKit/Package.swift](../OTPKit/Package.swift) keeps types `Sendable` and catches accidental shared-state leaks at compile time.
- Value-type models are `struct` throughout — aliasing bugs are structurally impossible.
