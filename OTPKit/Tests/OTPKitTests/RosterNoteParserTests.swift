import XCTest
@testable import OTPKit

final class RosterNoteParserTests: XCTestCase {
    private let parser = RosterNoteParser()

    func test_canonicalSampleFromDocs_parsesCorrectly() throws {
        let notes = """
        21A

        Reporting time : 2035
        21  - AUH  (2220) - YYZ  (1345+1)
        Debriefing time : 1415+1

        * All times in UTC

        --- Inserted by the AIMS eCrew app ---
        """

        // Event start in local AUH time (UTC+4) = 00:35 Mon Apr 20 2026 → UTC midnight Apr 19.
        let eventStart = TestSupport.utc(2026, 4, 19, 20, 35)
        let result = try parser.parse(notes: notes, eventStart: eventStart)

        XCTAssertEqual(result.sectorCode,   "21A")
        XCTAssertEqual(result.flightNumber, "21")
        XCTAssertEqual(result.origin,       "AUH")
        XCTAssertEqual(result.destination,  "YYZ")
        XCTAssertEqual(result.reportingUTC, TestSupport.utc(2026, 4, 19, 20, 35))
        XCTAssertEqual(result.stdUTC,       TestSupport.utc(2026, 4, 19, 22, 20))
        XCTAssertEqual(result.staUTC,       TestSupport.utc(2026, 4, 20, 13, 45))
        XCTAssertEqual(result.debriefingUTC, TestSupport.utc(2026, 4, 20, 14, 15))
    }

    func test_missingMarker_throws() {
        let notes = "21A\nReporting time : 2035\n21 - AUH (2220) - YYZ (1345+1)"
        XCTAssertThrowsError(try parser.parse(notes: notes, eventStart: Date())) { err in
            XCTAssertEqual(err as? RosterNoteParser.ParseError, .missingSourceMarker)
        }
    }

    func test_reportingAfterMidnightRollsSTDForward() throws {
        // Realistic roster shape: STD is written as bare HHMM on the origin-local day.
        // If that value lands earlier than reporting (i.e. next UTC day), the parser rolls STD forward.
        let notes = """
        99A

        Reporting time : 2350
        99  - AUH  (0115) - DEL  (0545+1)
        Debriefing time : 0645+1

        --- Inserted by the AIMS eCrew app ---
        """
        let eventStart = TestSupport.utc(2026, 4, 20, 23, 50)
        let r = try parser.parse(notes: notes, eventStart: eventStart)
        XCTAssertEqual(r.reportingUTC, TestSupport.utc(2026, 4, 20, 23, 50))
        XCTAssertEqual(r.stdUTC,       TestSupport.utc(2026, 4, 21,  1, 15),
                       "STD rolled forward one day so reporting <= STD holds")
        XCTAssertEqual(r.staUTC,       TestSupport.utc(2026, 4, 21,  5, 45))
        XCTAssertTrue(r.reportingUTC <= r.stdUTC, "reporting <= STD invariant")
    }

    func test_reportingAtEndOfDayWithNoPlusSuffix_shiftsSTDForward() throws {
        let notes = """
        7A

        Reporting time : 2200
        7  - AUH  (0030) - LHR  (0415)
        Debriefing time : 0515

        --- Inserted by the AIMS eCrew app ---
        """
        let eventStart = TestSupport.utc(2026, 4, 20, 22, 0)
        let r = try parser.parse(notes: notes, eventStart: eventStart)
        XCTAssertEqual(r.reportingUTC, TestSupport.utc(2026, 4, 20, 22, 0))
        XCTAssertGreaterThanOrEqual(r.stdUTC, r.reportingUTC)
    }

    func test_hasSourceMarker() {
        XCTAssertTrue(parser.hasSourceMarker("foo\n--- Inserted by the AIMS eCrew app ---\nbar"))
        XCTAssertFalse(parser.hasSourceMarker("random calendar event"))
    }

    func test_invalidTimeToken_throws() {
        let notes = """
        1A

        Reporting time : 99
        1 - AUH (2220) - YYZ (1345+1)

        --- Inserted by the AIMS eCrew app ---
        """
        XCTAssertThrowsError(try parser.parse(notes: notes, eventStart: Date()))
    }
}
