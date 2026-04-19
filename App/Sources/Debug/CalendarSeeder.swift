#if DEBUG
import Foundation
import EventKit
import OTPKit

/// Writes a roster-app-shaped calendar event into the device's default calendar so the
/// full import pipeline (EventKit → RosterNoteParser → AircraftResolver → Flight → widget)
/// can be exercised in the simulator without waiting on a real roster export.
@MainActor
struct CalendarSeeder {
    enum SeedError: Error { case noAccess, noDefaultCalendar, saveFailed(Error) }

    /// Seeds a flight scheduled `hoursFromNow` hours from now, reporting ~1:45 earlier.
    /// Returns the STD in UTC on success.
    func seed(hoursFromNow: Double = 2, flightNumber: Int = 21, origin: String = "AUH",
              destination: String = "YYZ", aircraftCategory: AircraftCategory = .a380) async throws -> Date {
        let store = EKEventStore()
        guard (try? await store.requestFullAccessToEvents()) == true else {
            throw SeedError.noAccess
        }
        guard let calendar = store.defaultCalendarForNewEvents else {
            throw SeedError.noDefaultCalendar
        }

        let now = Date()
        // OTP window per aircraft category (standard, non-CBP).
        let windowMinutes: Int = {
            switch aircraftCategory {
            case .a380:       return 105
            case .widebody:   return 90
            case .narrowbody: return 70
            }
        }()

        let stdUTC = now.addingTimeInterval(hoursFromNow * 3600)
        let reportingUTC = stdUTC.addingTimeInterval(Double(-windowMinutes * 60))
        let staUTC = stdUTC.addingTimeInterval(13.5 * 3600) // rough long-haul
        let debriefUTC = staUTC.addingTimeInterval(30 * 60)

        let sectorCode = "\(flightNumber)A"
        let notes = """
        \(sectorCode)

        Reporting time : \(hhmmUTC(reportingUTC))
        \(flightNumber)  - \(origin)  (\(hhmmUTC(stdUTC))) - \(destination)  (\(hhmmUTC(staUTC))\(dayOffsetSuffix(from: reportingUTC, to: staUTC)))
        Debriefing time : \(hhmmUTC(debriefUTC))\(dayOffsetSuffix(from: reportingUTC, to: debriefUTC))

        * All times in UTC

        --- Inserted by the AIMS eCrew app ---
        """

        // Remove prior seeds pointing at the same STD so the seeder stays idempotent across taps.
        let predicate = store.predicateForEvents(
            withStart: reportingUTC.addingTimeInterval(-3600),
            end: staUTC.addingTimeInterval(3600),
            calendars: [calendar]
        )
        for existing in store.events(matching: predicate)
        where existing.notes?.contains(RosterNoteParser.sourceMarker) == true
            && existing.title == "\(sectorCode) \(origin)-\(destination)" {
            try? store.remove(existing, span: .thisEvent)
        }

        let event = EKEvent(eventStore: store)
        event.calendar = calendar
        event.startDate = reportingUTC
        event.endDate = staUTC
        event.title = "\(sectorCode) \(origin)-\(destination)"
        event.location = "(\(hhmmUTC(reportingUTC))Z-\(hhmmUTC(staUTC))Z) \(origin)"
        event.notes = notes

        do {
            try store.save(event, span: .thisEvent)
            return stdUTC
        } catch {
            throw SeedError.saveFailed(error)
        }
    }

    private func hhmmUTC(_ date: Date) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        let comps = cal.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d%02d", comps.hour ?? 0, comps.minute ?? 0)
    }

    /// Returns `+1`, `+2`, etc. when the UTC day of `to` is after the UTC day of `from`.
    private func dayOffsetSuffix(from: Date, to: Date) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        let fromDay = cal.startOfDay(for: from)
        let toDay = cal.startOfDay(for: to)
        let days = cal.dateComponents([.day], from: fromDay, to: toDay).day ?? 0
        return days > 0 ? "+\(days)" : ""
    }
}
#endif
