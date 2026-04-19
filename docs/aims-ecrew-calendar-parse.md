# AIMS eCrew Calendar Event — Parse Contract

## Source

Etihad crew roster is distributed via the **AIMS eCrew** app. The app has an *Export to Calendar* function that writes flight events into the user's device calendar (on iOS typically via a Google Calendar account sync). Each flight sector is one event.

## Sample event (Apr 2026)

| Field | Value |
|---|---|
| Title | `21A AUH-YYZ` |
| Location | `(2035Z-1415Z) AUH` |
| Start (local, AUH UTC+4) | 00:35 Mon 20 Apr 2026 |
| End (local, AUH UTC+4) | 18:15 Mon 20 Apr 2026 |
| Calendar | `contactvinayak@gmail.com` |
| Notes | (see below) |

### Notes body

```
21A

Reporting time : 2035
21  - AUH  (2220) - YYZ  (1345+1)
Debriefing time : 1415+1

* All times in UTC

--- Inserted by the AIMS eCrew app ---
```

## Extraction

Parse from the event **notes** field (the title and location alone are insufficient and sometimes abbreviated).

| Field | Regex pattern | Captures |
|---|---|---|
| Sector code | `^(\d+[A-Z]?)\b` (first non-empty line) | `21A` |
| Reporting UTC | `Reporting time\s*:\s*(\d{4})` | `2035` |
| Flight + origin/STD | `(\d+)\s*-\s*([A-Z]{3})\s*\((\d{4})\)` | `21`, `AUH`, `2220` |
| Destination/STA | `-\s*([A-Z]{3})\s*\((\d{4})(\+\d)?\)` | `YYZ`, `1345`, `+1` |
| Debriefing UTC | `Debriefing time\s*:\s*(\d{4})(\+\d)?` | `1415`, `+1` |
| Source marker | `--- Inserted by the AIMS eCrew app ---` | (boolean, used to filter events) |

## Date handling

- Calendar event has a `startDate` in local time (device TZ). Use this to anchor the date range.
- All times in the notes are **UTC**. Resolve each UTC time to an absolute moment by anchoring to `event.startDate` (the earliest reference point for the sector).
- A `+1` suffix on a UTC time means "next calendar day" relative to the event's origin date.
- Reporting UTC MUST be <= STD UTC. If not, add one day to STD until the relationship holds (covers reports that cross UTC midnight).

## Validation

After parse, verify:

```
std_minus_report = (std_utc - reporting_utc) in minutes
expected = total_window_for(aircraft_category, is_cbp)
abs(std_minus_report - expected) <= 5  // tolerance for rounding
```

If mismatch, surface a warning chip in the flight detail view and fall back to user override of aircraft category and/or CBP flag.

## iOS EventKit integration

- Request `EKEntityType.event` read access during onboarding (only).
- **Filtering strategy**:
  - First pass: scan events whose `notes` contains `--- Inserted by the AIMS eCrew app ---`.
  - Optional refinement: allow the user to pick a specific calendar in settings if they have multiple accounts synced.
- **Refresh triggers**:
  - On app foreground.
  - On `EKEventStoreChangedNotification` (real-time when the user edits or imports roster).
  - On a silent push from CloudKit when another device has updated the user's flight list.

## Edge cases to handle

- **Deadhead / positioning flights** may have a different sector-code letter suffix (e.g., `21P`). Treat identically; log aircraft as "positioning" if the sector code suffix signals it.
- **Standby / reserve days** have their own event shape. Not supported in v1 — collect samples and handle in v1.x.
- **Time zone changes mid-trip**: all times in notes are UTC, so no conversion error; widget display should show both UTC and AUH-local for mental-math convenience.
- **Multi-leg rotation**: each leg is its own event. The widget only shows the *next* leg whose STD is in the future.
- **Event deleted/moved in calendar**: via `EKEventStoreChangedNotification`, re-parse the corresponding flight record and update or remove.
- **Duplicate events**: if AIMS re-exports, the source marker is the same but the UID might differ. De-duplicate by `(flight_number, std_utc)`.

## Future: richer metadata

AIMS eCrew does NOT include aircraft type in the notes. Aircraft is determined by:

1. Bundled flight-number → aircraft static map (shipped as `data/fleet_routes.json`, maintained manually).
2. Optional AeroDataBox API lookup on import (v1.1).
3. User override chip in the UI (always wins).

If Etihad ever updates AIMS to include aircraft in the notes, add a new capture group here.
