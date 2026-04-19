import XCTest
@testable import OTPKit

final class CBPResolverTests: XCTestCase {
    func test_knownCBPAirport_returnsTrue() throws {
        let resolver = try CBPResolver()
        XCTAssertTrue(resolver.isUSCBP(destinationIATA: "JFK", on: TestSupport.utc(2026, 4, 20)))
        XCTAssertTrue(resolver.isUSCBP(destinationIATA: "jfk", on: TestSupport.utc(2026, 4, 20)), "case-insensitive")
    }

    func test_canadaIsNotCBP() throws {
        let resolver = try CBPResolver()
        XCTAssertFalse(resolver.isUSCBP(destinationIATA: "YYZ", on: TestSupport.utc(2026, 4, 20)))
        XCTAssertFalse(resolver.isUSCBP(destinationIATA: "YYC", on: TestSupport.utc(2026, 4, 20)))
    }

    func test_CLT_beforeLaunchDate_isNotCBP() throws {
        let resolver = try CBPResolver()
        XCTAssertFalse(resolver.isUSCBP(
            destinationIATA: "CLT",
            on: TestSupport.utc(2026, 5, 3)
        ))
    }

    func test_CLT_onOrAfterLaunchDate_isCBP() throws {
        let resolver = try CBPResolver()
        XCTAssertTrue(resolver.isUSCBP(
            destinationIATA: "CLT",
            on: TestSupport.utc(2026, 5, 4)
        ))
        XCTAssertTrue(resolver.isUSCBP(
            destinationIATA: "CLT",
            on: TestSupport.utc(2026, 6, 1)
        ))
    }

    func test_override_winsOverLookup() throws {
        let resolver = try CBPResolver()
        XCTAssertTrue(resolver.isUSCBP(destinationIATA: "YYZ", on: TestSupport.utc(2026, 4, 20), override: true))
        XCTAssertFalse(resolver.isUSCBP(destinationIATA: "JFK", on: TestSupport.utc(2026, 4, 20), override: false))
    }

    func test_unknownAirport_isNotCBP() throws {
        let resolver = try CBPResolver()
        XCTAssertFalse(resolver.isUSCBP(destinationIATA: "ZZZ", on: TestSupport.utc(2026, 4, 20)))
    }
}
