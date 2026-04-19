# OTP Beyond Borders — Etihad OTP Countdown App

## What this is
A native iOS / iPadOS / watchOS app that shows a crew member exactly where they are in the turnaround "OTP" (On-Time Performance) timeline for their next Etihad flight. Primary surfaces:
- **iPhone lock-screen widget** (rectangular) with live countdown to the next OTP milestone.
- **Apple Watch complication** showing elapsed % of the OTP window with countdown to next milestone.
- **Main app** for importing flights from the device calendar (AIMS eCrew export), manual entry, and delay logging (IATA delay codes).

The countdown is driven by the **reporting time** written into the calendar event notes by the AIMS eCrew app, and by the aircraft category (A380 / Wide Body / Narrow Body) which maps to one of three milestone timelines.

## Primary user
An Etihad pilot based at **AUH (OMAA, Abu Dhabi)**. Rotations cover:
- **A380** (e.g., EY21 AUH–YYZ)
- **Wide Body**: A350, B777, B787
- **Narrow Body**: A320, A321

Secondary roles (cabin crew, engineer, ground staff) are also selectable. The user picks their role in onboarding and can switch at any time via a persistent dropdown; the UI highlights milestones that role owns.

## Source document
Etihad "OTP — Together For A Purpose" Target Guide, Revision 0, July 2025. Three posters: A380, Wide Body (except A380), Narrow Body.

Full deciphered content — milestone tables, role color codes, US-CBP offsets, LRV note — lives in [docs/otp-spec.md](docs/otp-spec.md).

## Calendar integration
AIMS eCrew exports flight events to the device calendar (typically Google Calendar feed on iOS). Event notes follow a fixed format from which we extract reporting time, flight number, STD, STA, destination IATA. Parse contract is in [docs/aims-ecrew-calendar-parse.md](docs/aims-ecrew-calendar-parse.md).

Onboarding instructs the user to enable AIMS eCrew → export-to-calendar so the app can read future flights automatically.

## Locked decisions

### Data & logic
- **Three timeline JSON files** ship with the app: [timelines/a380.json](timelines/a380.json), [timelines/widebody.json](timelines/widebody.json), [timelines/narrowbody.json](timelines/narrowbody.json). Milestones stored in minutes before STD.
- **US-CBP adjustment**: destinations in [data/us_cbp_airports.json](data/us_cbp_airports.json) (currently JFK, ORD, BOS, IAD, ATL, CLT — CLT from 4 May 2026) trigger a longer OTP window: +10 min for A380, +15 min for Wide Body, on CBC briefing and bus departure only. Narrow Body has no US routes.
- **LRV (Long Range Variation)**: Flight Time Limitation variation, not an OTP parameter.
  - *Variation A*: one sector outside prescriptive FTL, FDP up to 15h.
  - *Variation B*: all sectors outside prescriptive FTL, FDP up to 19h.
  - Both NON-LRV and LRV use the same 1:30 OTP window on Wide Body — captured in schema for completeness.
- **Aircraft type detection**: three layers — (1) bundled static fleet map keyed by flight number, (2) optional AeroDataBox API lookup (v1.1), (3) user override chip A380 / WB / NB. Defer to user choice on first import; remember per flight number.
- **One flight at a time** in the widget. Once STD passes without doors-closed, a *Log Delay* affordance appears (minutes + IATA delay code picker).
- **iCloud sync** via CloudKit private database.

### UX
- **Onboarding**: role carousel (Pilot / Cabin / Engineer / Ground) with per-role illustrations in the Etihad palette.
- **Persistent role dropdown** in the app (top-right chip, color-matched to swim lane).
- **Widget**: rectangular lock-screen only (v1). Inline/circular can be added later.
- **Notifications**: silent by default (widget-only); single haptic reminder at T−15 (eATL); per-milestone alerts toggle in settings.
- **Languages**: English, Arabic (RTL), Russian, Italian, Portuguese. Device-language auto-selection with manual override in settings. Strings translated once into `Localizable.xcstrings`; iOS selects at runtime.

## Palette (from the Etihad poster — approximate)
- Cream background — approx `#F7F2E9`
- Etihad gold / mustard — approx `#B8935A` (CABIN, primary accent)
- Dark teal / slate — approx `#2E4A57` (ENGINEER / PILOTS / headings)
- Terracotta coral — approx `#D56A4A` (GROUND)
- Navy — approx `#1F2E3D` (Pilot circle outlines)
- White circle fills with colored outlines for role attribution

Final hex values TBD after sampling the official poster pixels.

## Tech stack (proposed)
- SwiftUI (iOS 17+, watchOS 10+)
- WidgetKit — rectangular lock-screen widget
- WatchKit / ClockKit — circular complication
- EventKit — read calendar events
- CloudKit — iCloud sync
- Localization — Xcode String Catalog (`Localizable.xcstrings`)

## Non-goals for v1
- Android / web
- Non-Etihad airlines
- Flight-planning features (weather, NOTAMs, route briefing)
- Crew messaging or roster editing
- More than one flight at a time on the widget
- Inline / circular widget variants
- Audio notifications (silent default)

## File index
- [CLAUDE.md](CLAUDE.md) — this file
- [docs/otp-spec.md](docs/otp-spec.md) — full deciphered OTP target guide + app spec
- [docs/aims-ecrew-calendar-parse.md](docs/aims-ecrew-calendar-parse.md) — calendar note parsing contract
- [timelines/a380.json](timelines/a380.json)
- [timelines/widebody.json](timelines/widebody.json)
- [timelines/narrowbody.json](timelines/narrowbody.json)
- [data/us_cbp_airports.json](data/us_cbp_airports.json)

## How to resume with Claude Code
In a fresh Claude Code session started in this folder, prompt:
> Read CLAUDE.md and docs/otp-spec.md, then propose the v1 implementation plan.

The session will have all locked decisions as context and can proceed directly to scaffolding.
