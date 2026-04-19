import Foundation

public enum Phase: String, CaseIterable, Sendable, Codable, Hashable {
    case preAircraft  = "pre_aircraft"
    case onboardPrep  = "onboard_prep"
    case boarding
    case closeOut     = "close_out"
    case departure

    public var displayName: String {
        switch self {
        case .preAircraft: return "Pre-Aircraft"
        case .onboardPrep: return "Onboard Prep"
        case .boarding:    return "Boarding"
        case .closeOut:    return "Close Out"
        case .departure:   return "Departure"
        }
    }
}
