import Foundation

public struct CountdownState: Sendable, Hashable {
    public let now: Date
    public let status: Status
    public let currentPhase: Phase?
    public let previousMilestone: ResolvedMilestone?
    public let nextMilestone: ResolvedMilestone?
    public let remainingToNext: TimeInterval?
    public let remainingToStd: TimeInterval
    public let pctElapsed: Double
    public let ownerRoles: [Role]

    public enum Status: Sendable, Hashable {
        case beforeReporting
        case inWindow
        case afterStdUndeparted
        case departed
    }
}

public struct ResolvedMilestone: Sendable, Hashable, Identifiable {
    public var id: String { milestone.id }
    public let milestone: Milestone
    public let targetTime: Date
    public let completed: Bool
}
