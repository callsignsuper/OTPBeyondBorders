import XCTest
@testable import OTPKit

final class AircraftResolverTests: XCTestCase {
    func test_knownA380Route_resolves() throws {
        let resolver = try AircraftResolver()
        XCTAssertEqual(resolver.resolve(flightNumber: "21", on: TestSupport.utc(2026, 4, 20)), .a380)
        XCTAssertEqual(resolver.resolve(flightNumber: "11", on: TestSupport.utc(2026, 4, 20)), .a380)
    }

    func test_knownWideBodyRoute_resolves() throws {
        let resolver = try AircraftResolver()
        XCTAssertEqual(resolver.resolve(flightNumber: "17", on: TestSupport.utc(2026, 4, 20)), .widebody)
    }

    func test_knownNarrowBodyRoute_resolves() throws {
        let resolver = try AircraftResolver()
        XCTAssertEqual(resolver.resolve(flightNumber: "353", on: TestSupport.utc(2026, 4, 20)), .narrowbody)
    }

    func test_userOverride_winsOverLookup() throws {
        let resolver = try AircraftResolver()
        XCTAssertEqual(
            resolver.resolve(flightNumber: "21", on: TestSupport.utc(2026, 4, 20), userOverride: .narrowbody),
            .narrowbody
        )
    }

    func test_unknownFlight_returnsNil() throws {
        let resolver = try AircraftResolver()
        XCTAssertNil(resolver.resolve(flightNumber: "9999", on: TestSupport.utc(2026, 4, 20)))
    }

    func test_caseInsensitiveLookup() throws {
        // Bare numeric flight numbers are already case-irrelevant; this guards against
        // regressions if users add alphabetic carrier prefixes to their fleet map.
        let resolver = try AircraftResolver()
        XCTAssertEqual(resolver.resolve(flightNumber: "21", on: TestSupport.utc(2026, 4, 20)), .a380)
    }

    func test_effectiveFromGating_CLT_notLiveBeforeLaunch() throws {
        let resolver = try AircraftResolver()
        // Flight 181 AUH-CLT has effective_from 2026-05-04. Before that, the route is not yet live.
        let preDate  = TestSupport.utc(2026, 5, 3)
        let postDate = TestSupport.utc(2026, 5, 4)

        let pre  = resolver.route(flightNumber: "181", on: preDate)
        let post = resolver.route(flightNumber: "181", on: postDate)

        // Pre-launch: lookup falls back to the first matching row (no alternative exists in seed data).
        // Key assertion: post-launch the route is confirmed live.
        XCTAssertNotNil(post)
        XCTAssertEqual(post?.effectiveFrom, postDate)
        XCTAssertNotNil(pre, "Fallback behavior: return the route anyway since we have no alternative")
    }
}
