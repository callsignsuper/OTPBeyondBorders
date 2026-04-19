# OTP Beyond Borders — OTP Countdown App

## What this is
A native iOS / iPadOS / watchOS app that shows a crew member exactly where they are in the turnaround "OTP" (On-Time Performance) timeline for their next flight. Primary surfaces:
- **iPhone widget** (lock-screen rectangular + home-screen small/medium) with live countdown to the next OTP milestone.
- **Apple Watch complication** showing elapsed % of the OTP window with countdown to next milestone.
- **Main app** for importing flights from the device calendar (from the user's rostering or crew-control app), manual entry, and delay logging (IATA delay codes).

The countdown is driven by the **reporting time** written into the calendar event notes by the crew's rostering app, and by the aircraft category (A380 / Wide Body / Narrow Body) which maps to one of three milestone timelines.

## Primary user
An airline crew member based at **AUH (OMAA, Abu Dhabi)**. Rotations cover:
- **A380**
- **Wide Body**: A350, B777, B787
- **Narrow Body**: A320, A321

Selectable roles: Pilot, Cabin Crew, Ground Staff, Engineer. The user picks their role in onboarding and can switch at any time via a persistent dropdown; the UI highlights milestones that role owns.

## Source document
An airline OTP target guide (A380, Wide Body, Narrow Body posters) provides the milestone targets. The timings bundled with the app are a seed — replace them with your operator's current revision before shipping.

Full deciphered content — milestone tables, role color codes, US-CBP offsets, LRV note — lives in [docs/otp-spec.md](docs/otp-spec.md).

## Calendar integration
The user's rostering / crew-control app exports flight events to the device calendar (typically via a Google Calendar feed on iOS). Event notes follow a fixed format from which we extract reporting time, flight number, STD, STA, destination IATA. Parse contract is in [docs/roster-calendar-parse.md](docs/roster-calendar-parse.md).

Onboarding instructs the user to enable their rostering app's calendar export so we can read future flights automatically.

## Locked decisions

### Data & logic
- **Three timeline JSON files** ship with the app: [timelines/a380.json](timelines/a380.json), [timelines/widebody.json](timelines/widebody.json), [timelines/narrowbody.json](timelines/narrowbody.json). Milestones stored in minutes before STD.
- **US-CBP adjustment**: destinations in [data/us_cbp_airports.json](data/us_cbp_airports.json) (currently JFK, ORD, BOS, IAD, ATL, CLT — CLT from 4 May 2026) trigger a longer OTP window: +10 min for A380, +15 min for Wide Body, on CBC briefing and bus departure only. Narrow Body has no US routes.
- **LRV (Long Range Variation)**: Flight Time Limitation variation, not an OTP parameter.
  - *Variation A*: one sector outside prescriptive FTL, FDP up to 15h.
  - *Variation B*: all sectors outside prescriptive FTL, FDP up to 19h.
  - Both NON-LRV and LRV use the same 1:30 OTP window on Wide Body — captured in schema for completeness.
- **Aircraft type detection**: three layers — (1) bundled static fleet map keyed by flight number, (2) optional external API lookup (v1.1), (3) user override chip A380 / WB / NB. Defer to user choice on first import; remember per flight number.
- **One flight at a time** in the widget. Once STD passes without doors-closed, a *Log Delay* affordance appears (minutes + IATA delay code picker).
- **iCloud sync** via CloudKit private database (planned; not in v1 bootstrap).

### UX
- **Onboarding**: role carousel (Pilot / Cabin Crew / Ground Staff / Engineer) with per-role illustrations.
- **Persistent role dropdown** in the app (top-right chip, color-matched to swim lane).
- **Widget**: lock-screen rectangular + home-screen systemSmall and systemMedium families.
- **Notifications**: silent by default (widget-only); single haptic reminder at T−15 (eATL); per-milestone alerts toggle in settings.
- **Languages**: English, Arabic (RTL), Russian, Italian, Portuguese. Device-language auto-selection with manual override in settings. Strings translated once into `Localizable.xcstrings`; iOS selects at runtime.

## Palette (generic, approximate — sample your operator's poster for final values)
- Cream background — approx `#F7F2E9`
- Gold / mustard — approx `#B8935A` (Cabin Crew, primary accent)
- Dark teal / slate — approx `#2E4A57` (Engineer / Pilots / headings)
- Terracotta coral — approx `#D56A4A` (Ground Staff)
- Navy — approx `#1F2E3D` (Pilot circle outlines)
- White circle fills with colored outlines for role attribution

## Tech stack
- SwiftUI (iOS 17+, watchOS 10+)
- WidgetKit — lock-screen + home-screen widgets
- WatchKit / ClockKit — circular complication
- EventKit — read calendar events
- App Group (`group.com.otpbb.shared`) + file-backed `SharedFlightStorage` for app↔widget data sharing
- CloudKit — iCloud sync (planned)
- Localization — Xcode String Catalog (`Localizable.xcstrings`)

## Non-goals for v1
- Android / web
- Flight-planning features (weather, NOTAMs, route briefing)
- Crew messaging or roster editing
- More than one flight at a time on the widget
- Audio notifications (silent default)

## File index
- [CLAUDE.md](CLAUDE.md) — this file
- [docs/otp-spec.md](docs/otp-spec.md) — full deciphered OTP target guide + app spec
- [docs/roster-calendar-parse.md](docs/roster-calendar-parse.md) — calendar note parsing contract
- [docs/TESTING.md](docs/TESTING.md) — testing protocol
- [docs/SOLID-audit.md](docs/SOLID-audit.md) — architecture audit
- [timelines/a380.json](timelines/a380.json)
- [timelines/widebody.json](timelines/widebody.json)
- [timelines/narrowbody.json](timelines/narrowbody.json)
- [data/us_cbp_airports.json](data/us_cbp_airports.json)
- [data/fleet_routes.json](data/fleet_routes.json)
- [data/iata_delay_codes.json](data/iata_delay_codes.json)

## How to resume with Claude Code
In a fresh Claude Code session started in this folder, prompt:
> Read CLAUDE.md and docs/otp-spec.md, then propose the v1 implementation plan.

The session will have all locked decisions as context and can proceed directly to scaffolding.
