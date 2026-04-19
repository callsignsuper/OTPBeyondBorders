import Foundation

public enum Role: String, CaseIterable, Sendable, Codable, Hashable {
    case pilots
    case cabin
    case ground
    case engineer

    /// Singular, human-facing label for an individual crew member's role.
    public var displayName: String {
        switch self {
        case .pilots:   return "Pilot"
        case .cabin:    return "Cabin Crew"
        case .ground:   return "Ground Staff"
        case .engineer: return "Engineer"
        }
    }

    /// Plural swim-lane label as it appears on the printed OTP poster.
    public var swimLaneLabel: String {
        switch self {
        case .pilots:   return "Pilots"
        case .cabin:    return "Cabin"
        case .ground:   return "Ground"
        case .engineer: return "Engineer"
        }
    }

    /// One-line description for the role picker and headers.
    public var roleSubtitle: String {
        switch self {
        case .pilots:   return "Captain or First Officer"
        case .cabin:    return "Senior or Flight Attendant"
        case .ground:   return "Turnaround coordinator or equipment operator"
        case .engineer: return "Line or base maintenance engineer"
        }
    }
}
