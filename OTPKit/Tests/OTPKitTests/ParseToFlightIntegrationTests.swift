import XCTest
@testable import OTPKit

/// End-to-end: AIMS notes → parse → AircraftResolver → Flight → CountdownEngine.
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
        let parsed = try AIMSNotesParser().parse(notes: notes, eventStart: eventStart)

        // Flight number from AIMS is bare "21"; the fleet map is keyed on carrier-prefixed codes.
        // Production AircraftResolver is called with `EY` + parsed.flightNumber for Etihad events.
        let resolver = try AircraftResolver()
        let carrierFlight = "EY" + parsed.flightNumber
        let category = resolver.resolve(flightNumber: carrierFlight, on: parsed.stdUTC)
        XCTAssertEqual(category, .a380, "EY21 must map to A380")

        let flight = Flight(
            flightNumber: carrierFlight,
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
