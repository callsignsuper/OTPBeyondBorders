import Foundation

public struct CountdownEngine: Sendable {
    public init() {}

    public func state(
        flight: Flight,
        timeline: Timeline,
        isUSCBP: Bool,
        now: Date
    ) -> CountdownState {
        let sorted = timeline.sortedMilestones(isUSCBP: isUSCBP)

        let resolved: [ResolvedMilestone] = sorted.map { m in
            ResolvedMilestone(
                milestone: m,
                targetTime: m.targetTime(std: flight.stdUTC, isUSCBP: isUSCBP),
                completed: flight.completedMilestones.contains(m.id)
            )
        }

        let doorsClosed = resolved.first { $0.milestone.id == "doors_closed" }
        let departed = doorsClosed?.completed ?? false

        let status: CountdownState.Status
        if departed {
            status = .departed
        } else if now < flight.reportingUTC {
            status = .beforeReporting
        } else if now < flight.stdUTC {
            status = .inWindow
        } else {
            status = .afterStdUndeparted
        }

        let upcoming = resolved.first { $0.targetTime > now && !$0.completed }
        let previous = resolved.last  { $0.targetTime <= now || $0.completed }

        let remainingToNext: TimeInterval? = upcoming.map { $0.targetTime.timeIntervalSince(now) }
        let remainingToStd = flight.stdUTC.timeIntervalSince(now)

        let totalWindow = flight.stdUTC.timeIntervalSince(flight.reportingUTC)
        let elapsed = now.timeIntervalSince(flight.reportingUTC)
        let pct = totalWindow > 0 ? min(max(elapsed / totalWindow, 0.0), 1.0) : 0.0

        let currentPhase: Phase? = {
            if let up = upcoming { return up.milestone.phase }
            if let prev = previous { return prev.milestone.phase }
            return nil
        }()

        let owners: [Role] = upcoming?.milestone.owners ?? previous?.milestone.owners ?? []

        return CountdownState(
            now: now,
            status: status,
            currentPhase: currentPhase,
            previousMilestone: previous,
            nextMilestone: upcoming,
            remainingToNext: remainingToNext,
            remainingToStd: remainingToStd,
            pctElapsed: pct,
            ownerRoles: owners
        )
    }
}
