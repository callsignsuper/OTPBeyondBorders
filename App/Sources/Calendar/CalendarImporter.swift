import Foundation
import EventKit
import OTPKit

/// Thin EventKit wrapper. Scans calendar events for the AIMS source marker and converts matches into Flight values.
@MainActor
final class CalendarImporter {
    private let store = EKEventStore()
    private let parser = AIMSNotesParser()
    private let aircraftResolver: AircraftResolver?

    init() {
        self.aircraftResolver = try? AircraftResolver()
    }

    func requestAccess() async throws -> Bool {
        try await store.requestFullAccessToEvents()
    }

    func importFlights(in dateRange: DateInterval) -> [Flight] {
        let calendars = store.calendars(for: .event)
        let predicate = store.predicateForEvents(
            withStart: dateRange.start, end: dateRange.end, calendars: calendars
        )
        let events = store.events(matching: predicate)

        var seen: Set<String> = []
        var result: [Flight] = []

        for event in events {
            guard let notes = event.notes, parser.hasAIMSMarker(notes) else { continue }
            guard let parsed = try? parser.parse(notes: notes, eventStart: event.startDate) else { continue }
            let carrierFlight = "EY" + parsed.flightNumber
            let dedupeKey = "\(carrierFlight)@\(parsed.stdUTC.timeIntervalSince1970)"
            guard !seen.contains(dedupeKey) else { continue }
            seen.insert(dedupeKey)

            let category = aircraftResolver?.resolve(
                flightNumber: carrierFlight, on: parsed.stdUTC
            ) ?? .widebody

            result.append(Flight(
                flightNumber:  carrierFlight,
                sectorCode:    parsed.sectorCode,
                origin:        parsed.origin,
                destination:   parsed.destination,
                reportingUTC:  parsed.reportingUTC,
                stdUTC:        parsed.stdUTC,
                staUTC:        parsed.staUTC,
                debriefingUTC: parsed.debriefingUTC,
                category:      category
            ))
        }
        return result
    }
}
