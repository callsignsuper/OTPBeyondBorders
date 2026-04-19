import XCTest
@testable import OTPKit

final class DelayCodesTests: XCTestCase {
    func test_catalogLoadsAndHasMultipleGroups() throws {
        let catalog = try DelayCodeLoader().load()
        XCTAssertGreaterThan(catalog.groups.count, 5)
        XCTAssertGreaterThan(catalog.flat.count, 50, "IATA code list should have 50+ entries")
    }

    func test_knownCodesLookup() throws {
        let catalog = try DelayCodeLoader().load()
        XCTAssertEqual(catalog.code("11")?.name, "Late check-in")
        XCTAssertEqual(catalog.code("93")?.name, "Aircraft rotation")
        XCTAssertEqual(catalog.code("71")?.name, "Departure station")
    }

    func test_unknownCode_returnsNil() throws {
        let catalog = try DelayCodeLoader().load()
        XCTAssertNil(catalog.code("XX"))
    }

    func test_uniqueCodes() throws {
        let catalog = try DelayCodeLoader().load()
        let codes = catalog.flat.map(\.code)
        XCTAssertEqual(codes.count, Set(codes).count, "Codes must be unique")
    }
}
