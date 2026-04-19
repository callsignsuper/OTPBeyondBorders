import XCTest
@testable import OTPKit

final class AirportDirectoryTests: XCTestCase {
    func test_directoryLoadsAndContainsCommonAirports() throws {
        let dir = try AirportDirectory()
        XCTAssertGreaterThan(dir.all.count, 50, "Seed catalog should cover 50+ airports")
        XCTAssertNotNil(dir.lookup("AUH"))
        XCTAssertNotNil(dir.lookup("JFK"))
        XCTAssertNotNil(dir.lookup("YYZ"))
        XCTAssertNotNil(dir.lookup("SYD"))
    }

    func test_lookupIsCaseInsensitive() throws {
        let dir = try AirportDirectory()
        XCTAssertEqual(dir.lookup("auh")?.iata, "AUH")
        XCTAssertEqual(dir.lookup("Auh")?.iata, "AUH")
    }

    func test_unknownIATA_returnsNil() throws {
        let dir = try AirportDirectory()
        XCTAssertNil(dir.lookup("ZZZ"))
    }

    func test_airportsExposeIANATimeZone() throws {
        let dir = try AirportDirectory()
        let auh = dir.lookup("AUH")
        XCTAssertEqual(auh?.tz, "Asia/Dubai")
        XCTAssertNotNil(auh?.timeZone)
    }

    func test_utcOffsetLabel_formatsCommonZones() throws {
        let dir = try AirportDirectory()
        // Summer: Dubai is always +4 (no DST), Toronto EDT -4.
        let summer = TestSupport.utc(2026, 7, 15)
        XCTAssertEqual(dir.utcOffsetLabel(for: "AUH", at: summer), "UTC+4")
        XCTAssertEqual(dir.utcOffsetLabel(for: "YYZ", at: summer), "UTC-4")
        // Winter: Toronto EST -5.
        let winter = TestSupport.utc(2026, 1, 15)
        XCTAssertEqual(dir.utcOffsetLabel(for: "YYZ", at: winter), "UTC-5")
    }

    func test_localTimeString_convertsUTCToAirportTZ() throws {
        let dir = try AirportDirectory()
        // 2026-04-20 13:45 UTC → Toronto is UTC-4 in April (EDT) → 09:45 local.
        // Exact format depends on the test host's locale; assert the minute portion is correct.
        let utc = TestSupport.utc(2026, 4, 20, 13, 45)
        let label = try XCTUnwrap(dir.localTimeString(for: "YYZ", utc: utc))
        XCTAssertTrue(label.contains("45"), "Expected local time label to contain ':45', got \(label)")
        XCTAssertTrue(label.contains("9") || label.contains("09"),
                      "Expected 9 AM local, got \(label)")
    }

    func test_labels() throws {
        let dir = try AirportDirectory()
        let yyz = try XCTUnwrap(dir.lookup("YYZ"))
        XCTAssertEqual(yyz.compactLabel, "YYZ · Toronto Pearson")
        XCTAssertEqual(yyz.longLabel, "Toronto Pearson, Canada")
    }

    func test_uniqueIATA() throws {
        let dir = try AirportDirectory()
        let codes = dir.all.map(\.iata)
        XCTAssertEqual(codes.count, Set(codes).count, "IATA codes must be unique")
    }
}
