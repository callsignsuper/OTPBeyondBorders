# Testing Protocol — OTP Beyond Borders

This document is the single source of truth for how we verify the app. Every change should land with the appropriate section of this protocol green before merge.

## 1. Test pyramid

```
         ┌───────────────────┐
         │ Manual device QA  │   Section 6   — slow, rare, expensive
         └────────┬──────────┘
                  │
         ┌────────┴──────────┐
         │ UI snapshot tests │   Section 5   — view rendering, widget/watch layouts
         └────────┬──────────┘
                  │
   ┌──────────────┴──────────────┐
   │ Integration (OTPKit + Apple │   Section 4   — calendar import, SwiftData/CloudKit
   │        frameworks)          │
   └──────────────┬──────────────┘
                  │
       ┌──────────┴──────────┐
       │ OTPKit unit tests   │   Section 3   — pure, fast, exhaustive
       └─────────────────────┘
```

## 2. Quick start

```bash
# Pure domain tests (fastest feedback, runs on any Mac)
cd OTPKit && swift test

# Full build of iOS app + widget
xcodebuild \
  -project OTPBeyondBorders.xcodeproj \
  -scheme OTPBeyondBorders \
  -destination "platform=iOS Simulator,name=iPhone 17" \
  -configuration Debug build CODE_SIGNING_ALLOWED=NO

# Full build of watchOS app
xcodebuild \
  -project OTPBeyondBorders.xcodeproj \
  -scheme OTPWatch \
  -destination "platform=watchOS Simulator,name=Apple Watch Series 11 (46mm)" \
  -configuration Debug build CODE_SIGNING_ALLOWED=NO
```

## 3. OTPKit unit tests (authoritative)

Location: [OTPKit/Tests/OTPKitTests/](../OTPKit/Tests/OTPKitTests/)

These are **pure** — no EventKit, no WidgetKit, no simulator — so they run anywhere Swift runs and finish in under a second.

| Test file | What it locks in |
|---|---|
| `TimelineLoaderTests` | All three bundled timeline JSONs decode; milestone counts, windows, and CBP offsets match the Etihad poster exactly; narrow-body T−35 comes after T−40 in wall-clock time. |
| `CountdownEngineTests` | Status transitions (before-reporting → in-window → after-STD → departed); pct-elapsed math; next-milestone skips completed; owner-role surfacing; CBP shift on first two milestones only. |
| `AIMSNotesParserTests` | Canonical sample from [aims-ecrew-calendar-parse.md](aims-ecrew-calendar-parse.md); missing-marker rejection; reporting > STD forces +1 day on STD; invalid time tokens rejected. |
| `CBPResolverTests` | JFK/ORD/BOS/IAD/ATL always CBP; CLT gated by `launch_date` (2026-05-04); YYZ/YYC never CBP; user override wins. |
| `AircraftResolverTests` | Fleet-map hits; case-insensitive; unknown flights return nil; user override wins; `effective_from` gating on CLT routes. |
| `DelayCodesTests` | 50+ IATA codes load; known codes resolve to expected names; unique codes. |
| `ParseToFlightIntegrationTests` | End-to-end: AIMS notes → parse → AircraftResolver → Flight → CountdownEngine. Proves the data layer is wired together correctly. |

### When to add a test here

- Anything provable from pure inputs (date, flight, timeline JSON) goes here, not above.
- Any bug fix should reproduce with a failing test first, then turn green with the fix.

### Adding a new timeline (if Etihad updates the poster)

1. Add/edit the JSON in `OTPKit/Sources/OTPKit/Resources/timelines/`.
2. Add a fixture test in `TimelineLoaderTests` asserting the new milestone count, windows, and CBP offsets.
3. If the new timeline introduces a phase or role, add corresponding engine tests.

## 4. Integration tests (planned, not yet implemented)

These need Apple-framework shims that aren't in v1-bootstrap:

| Area | Gate | How we'll test |
|---|---|---|
| **Calendar ingestion** | EventKit + parser | `CalendarImporter` with a mocked `EKEventStore` that returns fixture events; assert dedupe by `(flight_number, std_utc)` and handling of the source marker. |
| **Persistence** | SwiftData model | In-memory container (`ModelConfiguration(isStoredInMemoryOnly: true)`); round-trip Flight + DelayLog. |
| **CloudKit mirror** | remote-change propagation | XCTest suite using CloudKit sandbox environment; not run on CI by default (requires entitlements). |

Track these as they come online.

## 5. UI / widget preview harness

### 5.1 In-app widget preview (implemented)

The debug iOS app exposes a **Widget Preview** screen from the Flight list's top-right toolbar (rectangle-on-rectangle icon, DEBUG builds only). It renders `OTPRectangularContent` — the same SwiftUI view the lock-screen widget uses — against a mock lock-screen backdrop, at the widget's native rectangular size, and exposes a segmented picker to walk through four states:

| State | What to verify |
|---|---|
| **In window** | Active countdown to the next milestone; progress bar tinted by the owner role. |
| **T−5** | `00:30` countdown as Doors Closed approaches; progress bar nearly full; three owner-role colors showing. |
| **Delay prompt** | Red "Log delay" text replaces the countdown when `now > STD` and `doors_closed` is not marked complete. |
| **Placeholder** | Stable fallback content the widget shows while a timeline entry is being built. |

Render metadata (family, phase, owner, deep-link URL) is shown below the widget so regressions in the engine's phase/owner resolution are catchable without running the app.

This preview is the **fastest** feedback loop for widget layout and content decisions — no re-install, no lock-screen auth, no waiting on WidgetKit timeline refresh.

### 5.2 Lock-screen customization (manual step)

Putting the widget on an actual lock screen requires Face ID auth on the Simulator and the following flow:

1. Lock the simulator (`Cmd+L`).
2. Swipe up on the lock screen to trigger Face ID.
3. Simulator → Features → Face ID → Matching Face (`Cmd+⌥+M`).
4. **Before dismissing the lock screen**, long-press the clock area.
5. Tap Customize → Lock Screen → add rectangular widget → OTP Beyond Borders → OTP Countdown.

This flow is Face-ID-gated and unreliable via UI automation. Treat as a manual step in §6.5.

### 5.3 Planned snapshot tests (not yet wired)

- Widget: snapshot `OTPRectangularContent` in each of the four states above.
- iOS flight-detail view: snapshot the timeline strip in each of four role tints.
- Watch root view: snapshot at three pct-elapsed values (0.0 / 0.5 / 1.0).

Suggested library: [pointfreeco/swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing). The shared `OTPRectangularContent` view + `OTPWidgetSnapshot` data type make this trivial to adopt — one import and four assertions per family.

## 6. Manual device QA checklist

This is the list that must pass before a TestFlight drop. Print it and tick it off.

### 6.1 First-run onboarding
- [ ] Role carousel cycles all four roles.
- [ ] Selected role persists after app restart.
- [ ] Calendar permission prompt shows our custom string.
- [ ] "Skip for now" in calendar pane still allows reaching Done.

### 6.2 Calendar import
- [ ] AIMS-tagged event → flight appears in list within 5 s of tapping refresh.
- [ ] Non-AIMS events are not imported.
- [ ] Editing the source event in Calendar and re-importing updates the flight (no duplicates).
- [ ] Flight with destination JFK auto-toggles CBP badge on.
- [ ] Flight with destination YYZ does not toggle CBP.
- [ ] CLT destination on 2026-05-03 does NOT trigger CBP; 2026-05-04 does.

### 6.3 Countdown correctness
Pick any upcoming flight:
- [ ] Phase label matches the spec for the current T−offset.
- [ ] Countdown counts down by 1 s per wall-second (observe for 60 s).
- [ ] Progress bar fill advances smoothly.
- [ ] At each milestone target, the "next" milestone changes to the subsequent one.
- [ ] Tapping a milestone checkbox toggles it; the engine skips completed milestones.

### 6.4 Delay logging
- [ ] After STD with doors NOT closed, a red "Log delay" button appears.
- [ ] Log delay sheet opens; stepper works; IATA picker is scrollable.
- [ ] Selecting code 99 reveals the free-text field.
- [ ] Save persists the delay log and attaches it to the flight.

### 6.5 Widget (lock screen)
- [ ] Add `OTP Countdown` widget to lock screen.
- [ ] Renders the next flight's phase, countdown, progress, next label.
- [ ] Progress bar fill = current owner role color.
- [ ] Widget refreshes at least once per minute.
- [ ] Tapping the widget opens the app (via `otpbb://next`).

### 6.6 Watch
- [ ] Watch app launches and shows countdown within 2 s.
- [ ] Circular progress ring visible and colored by owner role.
- [ ] Countdown updates once per second while the app is foregrounded.

### 6.7 Role & palette
- [ ] Persistent role chip (top-leading) shows current role with matching color.
- [ ] Switching role tints the ownership indicators on the timeline strip.
- [ ] No legibility issues with any role color on the cream background.

### 6.8 Localization smoke
- [ ] Switch device to العربية — layout mirrors (RTL) without clipping.
- [ ] Switch to Русский — no truncation on list rows.
- [ ] Non-translated keys fall back to English gracefully.

### 6.9 Edge cases
- [ ] Flight deleted from Calendar → disappears from list.
- [ ] Airplane mode → CloudKit sync gracefully queues, app still renders.
- [ ] Lock phone during countdown → widget continues to tick.
- [ ] Two flights on the same day — next-flight selector picks the earliest future STD.
- [ ] User overrides aircraft category — widget and timeline reflect the new category without restart.

## 7. CI (target setup)

Minimum pipeline:

1. `swift test` on OTPKit — 100% must pass.
2. `xcodebuild build` for both `OTPBeyondBorders` (iOS Simulator) and `OTPWatch` (watchOS Simulator) — 100% must pass.
3. (When UI snapshots exist) `xcodebuild test` with the snapshot suite on a fixed simulator.

No credentials or signing secrets — use `CODE_SIGNING_ALLOWED=NO` throughout CI.

## 8. Known gaps

These are deliberately not covered by automated tests in v1-bootstrap. They're tracked here so reviewers can weigh the risk consciously:

- **Fleet map correctness** — `data/fleet_routes.json` is seed data and not guaranteed to match Etihad's operational schedule. The user-override chip is the safety net; audit periodically.
- **Palette hex values** — `Palette.approximate` is sampled from the public poster PDF, not the brand-authoritative sRGB values.
- **Role illustrations** — onboarding uses SF Symbols as placeholders. Replace before GA.
- **CloudKit sync** — schema and conflict rules are not yet exercised by a test.
