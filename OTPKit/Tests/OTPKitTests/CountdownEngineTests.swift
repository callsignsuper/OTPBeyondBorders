import XCTest
@testable import OTPKit

final class CountdownEngineTests: XCTestCase {
    private let engine = CountdownEngine()

    func test_beforeReporting_statusIsBeforeReporting_andFirstMilestoneIsNext() throws {
        let flight = TestSupport.sampleA380Flight()
        let timeline = try TimelineLoader().load(.a380)
        // 5 minutes before reporting.
        let now = flight.reportingUTC.addingTimeInterval(-5 * 60)

        let state = engine.state(flight: flight, timeline: timeline, isUSCBP: false, now: now)

        XCTAssertEqual(state.status, .beforeReporting)
        XCTAssertEqual(state.nextMilestone?.milestone.id, "cbc_briefing_completed")
        XCTAssertEqual(state.pctElapsed, 0.0)
        XCTAssertNil(state.previousMilestone)
        // A380 reporting at STD-105, CBC briefing at STD-98 → 7 min after reporting.
        XCTAssertEqual(state.remainingToNext ?? 0, 12 * 60, accuracy: 0.1)
    }

    func test_inWindow_atExactlyReporting_currentPhaseIsPreAircraft_pctZero() throws {
        let flight = TestSupport.sampleA380Flight()
        let timeline = try TimelineLoader().load(.a380)

        let state = engine.state(
            flight: flight, timeline: timeline, isUSCBP: false, now: flight.reportingUTC
        )

        XCTAssertEqual(state.status, .inWindow)
        XCTAssertEqual(state.currentPhase, .preAircraft)
        XCTAssertEqual(state.pctElapsed, 0.0, accuracy: 0.001)
    }

    func test_inWindow_halfway_pctIsHalf() throws {
        let flight = TestSupport.sampleA380Flight()
        let timeline = try TimelineLoader().load(.a380)
        let mid = flight.reportingUTC.addingTimeInterval(flight.stdUTC.timeIntervalSince(flight.reportingUTC) / 2)

        let state = engine.state(flight: flight, timeline: timeline, isUSCBP: false, now: mid)

        XCTAssertEqual(state.status, .inWindow)
        XCTAssertEqual(state.pctElapsed, 0.5, accuracy: 0.01)
    }

    func test_afterSTD_undeparted_statusIsAfterStdUndeparted() throws {
        let flight = TestSupport.sampleA380Flight()
        let timeline = try TimelineLoader().load(.a380)
        let now = flight.stdUTC.addingTimeInterval(10 * 60)

        let state = engine.state(flight: flight, timeline: timeline, isUSCBP: false, now: now)

        XCTAssertEqual(state.status, .afterStdUndeparted)
        XCTAssertEqual(state.pctElapsed, 1.0)
        XCTAssertLessThan(state.remainingToStd, 0)
    }

    func test_departed_whenDoorsClosedCompleted_statusIsDeparted() throws {
        var flight = TestSupport.sampleA380Flight()
        flight.completedMilestones = ["doors_closed"]
        let timeline = try TimelineLoader().load(.a380)
        let now = flight.stdUTC.addingTimeInterval(-6 * 60) // before doors_closed target

        let state = engine.state(flight: flight, timeline: timeline, isUSCBP: false, now: now)

        XCTAssertEqual(state.status, .departed)
    }

    func test_nextMilestoneSkipsCompleted() throws {
        var flight = TestSupport.sampleA380Flight()
        flight.completedMilestones = ["cbc_briefing_completed"]
        let timeline = try TimelineLoader().load(.a380)
        // Sit just after the CBC briefing target time (STD-98m → -97m = 1 min after).
        let now = flight.stdUTC.addingTimeInterval(-97 * 60)

        let state = engine.state(flight: flight, timeline: timeline, isUSCBP: false, now: now)

        XCTAssertEqual(state.nextMilestone?.milestone.id, "bus_departs_cbc")
    }

    func test_ownerRolesReflectNextMilestone() throws {
        let flight = TestSupport.sampleA380Flight()
        let timeline = try TimelineLoader().load(.a380)
        // Between pre-flight checks (STD-55) and auto-boarding (STD-45): next = auto_boarding, owners = ground, cabin.
        let now = flight.stdUTC.addingTimeInterval(-50 * 60)

        let state = engine.state(flight: flight, timeline: timeline, isUSCBP: false, now: now)

        XCTAssertEqual(state.nextMilestone?.milestone.id, "auto_boarding_initiated")
        XCTAssertEqual(Set(state.ownerRoles), [.ground, .cabin])
    }

    func test_CBP_shiftsFirstTwoMilestonesButNotOthers() throws {
        let cbpFlight = Flight(
            flightNumber: "EY11",
            origin: "AUH",
            destination: "JFK",
            reportingUTC: TestSupport.utc(2026, 5, 1, 10, 5),   // STD-115
            stdUTC:       TestSupport.utc(2026, 5, 1, 12, 0),
            category:     .a380
        )
        let timeline = try TimelineLoader().load(.a380)

        // Sit 1s before CBC briefing's CBP target (STD-108).
        let cbcTargetCBP = cbpFlight.stdUTC.addingTimeInterval(-108 * 60)
        let state = engine.state(
            flight: cbpFlight, timeline: timeline, isUSCBP: true,
            now: cbcTargetCBP.addingTimeInterval(-1)
        )
        let next = try XCTUnwrap(state.nextMilestone)
        XCTAssertEqual(next.milestone.id, "cbc_briefing_completed")
        XCTAssertEqual(next.targetTime.timeIntervalSince1970,
                       cbcTargetCBP.timeIntervalSince1970, accuracy: 0.1)

        // Doors closed is unchanged at STD-5 regardless of CBP.
        let doors = try XCTUnwrap(timeline.milestones.first { $0.id == "doors_closed" })
        XCTAssertEqual(doors.targetTime(std: cbpFlight.stdUTC, isUSCBP: true),
                       cbpFlight.stdUTC.addingTimeInterval(-5 * 60))
        XCTAssertEqual(doors.targetTime(std: cbpFlight.stdUTC, isUSCBP: false),
                       cbpFlight.stdUTC.addingTimeInterval(-5 * 60))
    }
}
