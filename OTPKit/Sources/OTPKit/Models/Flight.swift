import Foundation

public struct Flight: Sendable, Hashable, Codable, Identifiable {
    public var id: String { "\(flightNumber)@\(ISO8601DateFormatter().string(from: stdUTC))" }

    public let flightNumber: String
    public let sectorCode: String?
    public let origin: String
    public let destination: String
    public let reportingUTC: Date
    public let stdUTC: Date
    public let staUTC: Date?
    public let debriefingUTC: Date?
    public var category: AircraftCategory
    public var isUSCBPOverride: Bool?
    public var completedMilestones: Set<String>
    public var delayLog: DelayLog?

    public init(
        flightNumber: String,
        sectorCode: String? = nil,
        origin: String,
        destination: String,
        reportingUTC: Date,
        stdUTC: Date,
        staUTC: Date? = nil,
        debriefingUTC: Date? = nil,
        category: AircraftCategory,
        isUSCBPOverride: Bool? = nil,
        completedMilestones: Set<String> = [],
        delayLog: DelayLog? = nil
    ) {
        self.flightNumber        = flightNumber
        self.sectorCode          = sectorCode
        self.origin              = origin
        self.destination         = destination
        self.reportingUTC        = reportingUTC
        self.stdUTC              = stdUTC
        self.staUTC              = staUTC
        self.debriefingUTC       = debriefingUTC
        self.category            = category
        self.isUSCBPOverride     = isUSCBPOverride
        self.completedMilestones = completedMilestones
        self.delayLog            = delayLog
    }
}

public struct DelayLog: Sendable, Hashable, Codable {
    public let minutesDelayed: Int
    public let iataCode: String
    public let freeText: String?
    public let loggedAt: Date

    public init(minutesDelayed: Int, iataCode: String, freeText: String? = nil, loggedAt: Date) {
        self.minutesDelayed = minutesDelayed
        self.iataCode       = iataCode
        self.freeText       = freeText
        self.loggedAt       = loggedAt
    }
}
