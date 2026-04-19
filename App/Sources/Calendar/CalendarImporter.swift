import Foundation
import EventKit
import OTPKit

/// Thin EventKit wrapper. Scans calendar events for the roster source marker and converts matches into Flight values.
@MainActor
final class CalendarImporter {
    private let store = EKEventStore()
    private let parser = RosterNoteParser()
    private let aircraftResolver: AircraftResolver?
    /// Optional airline IATA prefix (e.g. "AA", "BA"). Roster notes typically emit the bare numeric
    /// flight number; fleet maps usually key on the prefixed form. Leave empty for carrier-agnostic use.
    private let carrierPrefix: String

    init(carrierPrefix: String = "") {
        self.aircraftResolver = try? AircraftResolver()
        self.carrierPrefix = carrierPrefix
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
            guard let notes = event.notes, parser.hasSourceMarker(notes) else { continue }
            guard let parsed = try? parser.parse(notes: notes, eventStart: event.startDate) else { continue }
            let displayFlight = carrierPrefix + parsed.flightNumber
            let dedupeKey = "\(displayFlight)@\(parsed.stdUTC.timeIntervalSince1970)"
            guard !seen.contains(dedupeKey) else { continue }
            seen.insert(dedupeKey)

            let category = aircraftResolver?.resolve(
                flightNumber: displayFlight, on: parsed.stdUTC
            ) ?? .widebody

            result.append(Flight(
                flightNumber:  displayFlight,
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
