import XCTest
@testable import OTPKit

/// End-to-end: roster notes → parse → AircraftResolver → Flight → CountdownEngine.
final class ParseToFlightIntegrationTests: XCTestCase {
    func test_parseSampleNotesAndFeedEngine() throws {
        let notes = """
        21A

        Reporting time : 2035
        21  - AUH  (2220) - YYZ  (1345+1)
        Debriefing time : 1415+1

        --- Inserted by the AIMS eCrew app ---
        """
        let eventStart = TestSupport.utc(2026, 4, 19, 20, 35)
        let parsed = try RosterNoteParser().parse(notes: notes, eventStart: eventStart)

        // Roster notes emit the bare numeric flight number; the seed fleet map is keyed on
        // matching bare numbers. Users replace this seed with their own airline's data.
        let resolver = try AircraftResolver()
        let category = resolver.resolve(flightNumber: parsed.flightNumber, on: parsed.stdUTC)
        XCTAssertEqual(category, .a380, "Flight 21 must map to A380 in the seed fleet map")

        let flight = Flight(
            flightNumber: parsed.flightNumber,
            sectorCode:   parsed.sectorCode,
            origin:       parsed.origin,
            destination:  parsed.destination,
            reportingUTC: parsed.reportingUTC,
            stdUTC:       parsed.stdUTC,
            staUTC:       parsed.staUTC,
            debriefingUTC: parsed.debriefingUTC,
            category:     category ?? .widebody
        )

        let timeline = try TimelineLoader().load(flight.category)
        let cbp = try CBPResolver().isUSCBP(destinationIATA: flight.destination, on: flight.stdUTC)
        XCTAssertFalse(cbp, "YYZ (Toronto) is NOT a CBP destination")

        let state = CountdownEngine().state(
            flight: flight, timeline: timeline, isUSCBP: cbp, now: flight.reportingUTC
        )
        XCTAssertEqual(state.status, .inWindow)
        XCTAssertEqual(state.nextMilestone?.milestone.id, "cbc_briefing_completed")
    }
}
