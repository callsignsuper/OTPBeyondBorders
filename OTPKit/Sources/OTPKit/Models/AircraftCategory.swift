import Foundation

public enum AircraftCategory: String, CaseIterable, Sendable, Codable, Hashable {
    case a380       = "A380"
    case widebody   = "widebody"
    case narrowbody = "narrowbody"

    public var resourceBasename: String {
        switch self {
        case .a380:       return "a380"
        case .widebody:   return "widebody"
        case .narrowbody: return "narrowbody"
        }
    }

    public var shortLabel: String {
        switch self {
        case .a380:       return "A380"
        case .widebody:   return "WB"
        case .narrowbody: return "NB"
        }
    }
}
