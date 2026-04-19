# OTP Beyond Borders — Specification

## 1. Source document

Etihad Airways "OTP — Together For A Purpose" Target Guide, Revision 0, July 2025. Three poster variants — A380, Wide Body (except A380), Narrow Body — each showing milestone targets as negative minutes before STD (Scheduled Time of Departure).

Every poster shows four horizontal swim lanes (ENGINEER, GROUND, CABIN, PILOTS) converging on a vertical dashed line labeled STD on the right. Milestones appear as numbered circles above and below the swim lanes, with colored outlines indicating the responsible role.

## 2. Roles & color coding

| Role | Color (approx) | Typical milestones |
|---|---|---|
| **ENGINEER** | Dark teal | Shared circles on Wide Body / A380 posters |
| **GROUND** | Terracotta / coral | Equipment connect, auto-boarding, GPU/ACU off, tow truck |
| **CABIN** | Gold / mustard | Auto-boarding (shared), doors closed (shared) |
| **PILOTS** | Navy | Briefing, bus, board, pre-flight, loadsheet, eATL, doors closed (shared) |

Circles with multi-colored outlines = shared responsibility. Example: "Doors Closed" outline shows Cabin + Pilots + Ground.

## 3. Milestones by aircraft

All values are minutes before STD. "Owner" = which swim lane primarily executes.

### 3.1 A380

- **Total OTP window**: 1:45 (standard) / 1:55 (US-CBP) — reporting time = STD − 105 / 115 min
- **US-CBP adjustment**: +10 minutes to CBC briefing and bus departure only
- **Bus briefing note**: Remainder of briefing to be conducted in the bus

| T−min | T−min (CBP) | Milestone | Owner(s) |
|---|---|---|---|
| −98 | −108 | CBC Briefing Completed | Pilots / Cabin |
| −88 | −98 | Bus Departs CBC | Pilots / Cabin |
| −73 | — | Board the Aircraft | Pilots / Cabin |
| −60 | — | Ground Equipment Connected | Ground |
| −55 | — | Pre-Flight Checks Completed | Pilots |
| −45 | — | Auto Boarding Initiated | Ground / Cabin |
| −40 | — | Prel-Loadsheet & Fuel Figures Passed | Pilots |
| −15 | — | eATL Signed & Briefing Completed | Pilots |
| −10 | — | Loadsheet Received | Pilots |
| −10 | — | GPU/ACU Disconnected | Ground |
| −5 | — | Doors Closed | Cabin + Pilots + Ground |
| −5 | — | Tow Truck Connected | Ground |

### 3.2 Wide Body (A350, B777, B787)

- **Total OTP window**: 1:30 (standard) / 1:45 (US-CBP) — reporting time = STD − 90 / 105 min
- **US-CBP adjustment**: +15 minutes to CBC briefing and bus departure only
- **LRV**: no timeline change — same 1:30 window applies for both NON-LRV and LRV

| T−min | T−min (CBP) | Milestone | Owner(s) |
|---|---|---|---|
| −85 | −100 | CBC Briefing Completed | Pilots / Cabin |
| −75 | −90 | Bus Departs CBC | Pilots / Cabin |
| −60 | — | Ground Equipment Connected | Ground |
| −60 | — | Board the Aircraft | Pilots / Cabin |
| −45 | — | Pre-Flight Checks Completed | Pilots |
| −45 | — | Auto Boarding Initiated | Ground / Cabin |
| −40 | — | Prel-Loadsheet & Fuel Figures Passed | Pilots |
| −15 | — | eATL Signed & Briefing Completed | Pilots |
| −10 | — | Loadsheet Received | Pilots |
| −10 | — | GPU/ACU Disconnected | Ground |
| −5 | — | Doors Closed | Cabin + Pilots + Ground |
| −5 | — | Tow Truck Connected | Ground |

### 3.3 Narrow Body (A320, A321)

- **Total OTP window**: not explicitly stated on poster; reporting time at T−70 implies ~1:10 window
- **No US-CBP variant** (Etihad narrow body does not fly to the US)
- **Sequence note**: Pre-flight checks complete at T−35, AFTER prel-loadsheet at T−40. This is the confirmed sequence for narrow body — visually the poster shows −35 before −40 along the horizontal axis, but the times are authoritative.

| T−min | Milestone | Owner(s) |
|---|---|---|
| −70 | CBC Briefing Completed | Pilots / Cabin |
| −63 | Bus Departs CBC | Pilots / Cabin |
| −60 | Ground Equipment Connected | Ground |
| −48 | Board the Aircraft | Pilots / Cabin |
| −40 | Prel-Loadsheet & Fuel Figures Passed | Pilots |
| −35 | Pre-Flight Checks Completed | Pilots |
| −35 | Auto Boarding Initiated | Ground / Cabin |
| −15 | eATL Signed & Briefing Completed | Pilots |
| −10 | Loadsheet Received | Pilots |
| −10 | GPU/ACU Disconnected | Ground |
| −5 | Doors Closed | Cabin + Pilots + Ground |
| −5 | Tow Truck Connected | Ground |

## 4. US-CBP airports

Bundled list in [../data/us_cbp_airports.json](../data/us_cbp_airports.json). Current as of April 2026:

- JFK — New York John F. Kennedy
- ORD — Chicago O'Hare
- BOS — Boston Logan
- IAD — Washington Dulles
- ATL — Atlanta Hartsfield-Jackson
- CLT — Charlotte Douglas (from 4 May 2026)

Canadian destinations (YYZ Toronto, YYC Calgary from 2026) do NOT trigger CBP — they count as standard non-CBP North American flights.

The user can manually override CBP on/off per flight.

## 5. LRV (Long Range Variation)

Reference: Flight Time Limitation (FTL) variation for operations with sectors planned outside the prescriptive FTL regulation. Not an OTP parameter.

- **Variation A**: flights with one sector inside and one outside the prescriptive FTL scheme; Flight Duty Period up to 15 hours.
- **Variation B**: flights with all sectors outside the prescriptive scheme; FDP up to 19 hours.

OTP timeline is identical for NON-LRV and LRV on the Wide Body poster. The app accepts this metadata if available (for informational display) but does not use it for countdown computation.

## 6. Countdown logic (pseudocode)

```
inputs:
  reportingUTC   ← from calendar notes
  stdUTC         ← from calendar notes
  aircraftCategory ← detected or user-chosen (A380 / widebody / narrowbody)
  isUSCBP        ← derived from destination IATA, user-overridable

timeline = load("timelines/" + category + ".json")
now = current_time()

for m in timeline.milestones:
  t_minus = (m.cbp_t_minus if isUSCBP and m.cbp_t_minus else m.t_minus)
  m.target_time = stdUTC - t_minus * 60

next_milestone   = first m in timeline where m.target_time > now AND not m.user_marked_done
remaining_to_next = next_milestone.target_time - now
remaining_to_std  = stdUTC - now
elapsed_window   = now - reportingUTC
total_window     = stdUTC - reportingUTC
pct_elapsed      = clamp(elapsed_window / total_window, 0.0, 1.0)
```

## 7. Delay tracking

Once `now > stdUTC` AND `doors_closed` milestone not marked complete:

- Widget shows a "Log Delay" affordance (red badge).
- Main app opens a delay sheet on tap:
  - Minutes delayed (stepper)
  - IATA delay code picker (00–99), with code descriptions bundled as `data/iata_delay_codes.json` (TBD).
- Record persists per flight in iCloud for the user's own reference.

## 8. Widget (iPhone rectangular lock-screen)

Layout, top to bottom:

1. **Flight header** — `EY21  AUH → YYZ  A380` (flight, route, aircraft chip)
2. **Current phase name** — e.g., "Pre-Flight Checks"
3. **Countdown to next milestone** — large type, `MM:SS` or `H:MM`
4. **Thin progress bar** — elapsed of OTP window, with tick marks at each upcoming milestone
5. **Next milestone label** — e.g., "Prel-Loadsheet in 12m"

Progress-bar fill color = current owner's role color (pilots=navy, cabin=gold, ground=terracotta, engineer=teal). If shared ownership, use a two-tone gradient.

## 9. Apple Watch complication

- Circular progress around the watch face (elapsed % of OTP window)
- Center: countdown to next milestone
- Tap → open app

## 10. Onboarding flow

1. Welcome + brand
2. Role picker: Pilot / Cabin / Engineer / Ground (illustrated carousel — needs design)
3. Calendar access request + explainer: "AIMS eCrew → Settings → Enable calendar export"
4. Notification permission (silent default + explainer)
5. Language choice (default = device language)
6. Demo flight ("Tap to see how it works")

## 11. Non-goals for v1

See [../CLAUDE.md](../CLAUDE.md) for the authoritative list.
