import Foundation

public enum Role: String, CaseIterable, Sendable, Codable, Hashable {
    case pilots
    case cabin
    case ground
    case engineer

    public var displayName: String {
        switch self {
        case .pilots:   return "Pilots"
        case .cabin:    return "Cabin"
        case .ground:   return "Ground"
        case .engineer: return "Engineer"
        }
    }
}
