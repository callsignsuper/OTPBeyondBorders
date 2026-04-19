import XCTest
@testable import OTPKit

final class TimelineLoaderTests: XCTestCase {
    func test_loadsAllThreeCategoriesAndCountsMatchSpec() throws {
        let all = try TimelineLoader().loadAll()
        XCTAssertEqual(all.count, 3)

        let a380       = try XCTUnwrap(all[.a380])
        let widebody   = try XCTUnwrap(all[.widebody])
        let narrowbody = try XCTUnwrap(all[.narrowbody])

        XCTAssertEqual(a380.milestones.count, 12,       "A380 poster has 12 milestones")
        XCTAssertEqual(widebody.milestones.count, 12,   "Wide Body poster has 12 milestones")
        XCTAssertEqual(narrowbody.milestones.count, 12, "Narrow Body poster has 12 milestones")
    }

    func test_totalWindowsMatchSpec() throws {
        let loader = TimelineLoader()
        XCTAssertEqual(try loader.load(.a380).window(isUSCBP: false),        105, "A380 standard = 1:45")
        XCTAssertEqual(try loader.load(.a380).window(isUSCBP: true),         115, "A380 CBP = 1:55")
        XCTAssertEqual(try loader.load(.widebody).window(isUSCBP: false),    90,  "WB standard = 1:30")
        XCTAssertEqual(try loader.load(.widebody).window(isUSCBP: true),     105, "WB CBP = 1:45")
        XCTAssertEqual(try loader.load(.narrowbody).window(isUSCBP: false),  70,  "NB = 1:10")
    }

    func test_narrowBodyDoesNotAdvertiseCBP() throws {
        let nb = try TimelineLoader().load(.narrowbody)
        XCTAssertFalse(nb.usCBPApplicable)
        XCTAssertNil(nb.totalOTPWindow.usCBP)
    }

    func test_a380_CBP_shiftsOnlyFirstTwoMilestones() throws {
        let a380 = try TimelineLoader().load(.a380)

        // CBC briefing and bus-departs get +10; every other milestone keeps the same time.
        let cbc = a380.milestones.first { $0.id == "cbc_briefing_completed" }!
        let bus = a380.milestones.first { $0.id == "bus_departs_cbc" }!
        XCTAssertEqual(cbc.cbpTMinus, 108)
        XCTAssertEqual(bus.cbpTMinus, 98)

        let others = a380.milestones.filter { !["cbc_briefing_completed", "bus_departs_cbc"].contains($0.id) }
        for m in others {
            XCTAssertNil(m.cbpTMinus, "\(m.id) should have no CBP offset")
        }
    }

    func test_widebody_CBP_offsetIs15() throws {
        let wb = try TimelineLoader().load(.widebody)
        let cbc = wb.milestones.first { $0.id == "cbc_briefing_completed" }!
        let bus = wb.milestones.first { $0.id == "bus_departs_cbc" }!
        XCTAssertEqual(cbc.cbpTMinus, 100) // 85 + 15
        XCTAssertEqual(bus.cbpTMinus, 90)  // 75 + 15
    }

    func test_narrowBody_preflightSequenceQuirk() throws {
        let nb = try TimelineLoader().load(.narrowbody)
        // Pre-flight checks (T-35) happens AFTER prel-loadsheet (T-40) in wall-clock time.
        let pre  = nb.milestones.first { $0.id == "pre_flight_checks_completed" }!
        let prel = nb.milestones.first { $0.id == "prel_loadsheet_passed" }!
        XCTAssertEqual(pre.tMinus,  35)
        XCTAssertEqual(prel.tMinus, 40)
        XCTAssertLessThan(pre.tMinus, prel.tMinus, "Pre-flight T-minus is smaller, meaning it occurs later")
    }

    func test_doorsClosedOwnedByAllThreeOperationalRoles() throws {
        for cat in AircraftCategory.allCases {
            let t = try TimelineLoader().load(cat)
            let dc = t.milestones.first { $0.id == "doors_closed" }!
            XCTAssertEqual(Set(dc.owners), [.cabin, .pilots, .ground], "\(cat) doors closed roles")
        }
    }

    func test_sortedMilestonesGoesEarlyToLate() throws {
        let a380 = try TimelineLoader().load(.a380)
        let sortedStd = a380.sortedMilestones(isUSCBP: false)
        XCTAssertEqual(sortedStd.first?.id, "cbc_briefing_completed")

        let sortedCBP = a380.sortedMilestones(isUSCBP: true)
        XCTAssertEqual(sortedCBP.first?.id, "cbc_briefing_completed")
        XCTAssertEqual(sortedCBP.first?.effectiveTMinus(isUSCBP: true), 108)
    }
}
