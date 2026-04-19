# TestFlight pre-upload checklist

This is the exact set of steps to get a clean TestFlight build after every `xcodegen generate`.

## One-time setup (do once per Apple Developer account)

1. **Team ID** — edit `project.yml`:
   ```yaml
   DEVELOPMENT_TEAM: "ABCDE12345"   # your 10-char ID
   ```
   Re-run `xcodegen generate`. Without this, signing fails in archive.

2. **App Group provisioning** — at [developer.apple.com](https://developer.apple.com):
   - Identifiers → `+` → **App Groups** → create `group.com.otpbb.shared`.
   - Identifiers → select each of `com.otpbb.ios`, `com.otpbb.ios.widget`, `com.otpbb.watch` → enable **App Groups** → check `group.com.otpbb.shared`.
   - Xcode → Signing & Capabilities → refresh profiles, or delete and re-download them.

3. **Bundle IDs** — register three app IDs:
   - `com.otpbb.ios` (iOS app)
   - `com.otpbb.ios.widget` (widget extension)
   - `com.otpbb.watch` (watchOS app)
   If your bundle prefix differs, change `bundleIdPrefix` and `PRODUCT_BUNDLE_IDENTIFIER` values in `project.yml` consistently.

## Before every archive

1. `xcodegen generate`.
2. Bump `CURRENT_PROJECT_VERSION` in `project.yml` if needed.
3. `swift test` in `OTPKit/` — must be green.
4. `xcodebuild -project OTPBeyondBorders.xcodeproj -scheme OTPBeyondBorders -configuration Release` — must succeed.
5. Open `OTPBeyondBorders.xcodeproj` in Xcode, **Product → Archive**.
6. Organizer → Distribute App → App Store Connect → Upload.

## What's stripped from Release (verified)

These ship only in Debug:
- `App/Sources/Debug/CalendarSeeder.swift` (writes test AIMS events to real calendar)
- `App/Sources/Debug/WidgetPreviewView.swift` (in-app widget gallery)
- Calendar-seed button on the Flight list toolbar
- Widget-preview button on the Flight list toolbar

Release verification command (sanity check after xcodebuild Release):
```bash
strings /path/to/Release/OTPBeyondBorders.app/OTPBeyondBorders | \
    grep -E "CalendarSeeder|WidgetPreviewView|seedTestFlight|seedDemoFlight"
# Expected: zero matches.
```

## Privacy manifest

Every target ships a `PrivacyInfo.xcprivacy` declaring:
- No tracking, no collected data types.
- UserDefaults usage reason `CA92.1` (app functionality — we read/write preferences).
- File-timestamp usage reason `C617.1` (we read/write `flights.json` in the App Group container).

If you add a library that uses any other required-reason API (system boot time, disk space, active keyboards, file timestamps outside the app group), extend the manifest.

## Export compliance

`ITSAppUsesNonExemptEncryption = false` is set in all three Info.plists. No encryption beyond HTTPS system APIs is used; TestFlight won't prompt.

## What to verify after the first TestFlight install

- [ ] App opens on a real device without crashing.
- [ ] Onboarding flow completes through all five steps.
- [ ] Calendar permission prompt uses the "your rostering app" wording.
- [ ] Without any flight data, flight list shows "No flights yet" empty state.
- [ ] Widget gallery preview shows the OTP widget with "No upcoming flight" (not a fake flight).
- [ ] After importing a roster-tagged calendar event, flight list populates and widget renders the countdown.
- [ ] Wake-up alarm fires at the configured lead time.
- [ ] UTC clock at the bottom of the Flight Detail screen is always visible and updates.
