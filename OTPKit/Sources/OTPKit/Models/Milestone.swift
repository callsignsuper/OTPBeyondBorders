import Foundation

public struct Milestone: Sendable, Hashable, Codable, Identifiable {
    public let id: String
    public let tMinus: Int
    public let cbpTMinus: Int?
    public let owners: [Role]
    public let phase: Phase

    public init(id: String, tMinus: Int, cbpTMinus: Int? = nil, owners: [Role], phase: Phase) {
        self.id = id
        self.tMinus = tMinus
        self.cbpTMinus = cbpTMinus
        self.owners = owners
        self.phase = phase
    }

    public func effectiveTMinus(isUSCBP: Bool) -> Int {
        if isUSCBP, let cbp = cbpTMinus { return cbp }
        return tMinus
    }

    public func targetTime(std: Date, isUSCBP: Bool) -> Date {
        std.addingTimeInterval(-Double(effectiveTMinus(isUSCBP: isUSCBP)) * 60)
    }

    public var displayName: String {
        Milestone.displayNames[id] ?? id
            .split(separator: "_")
            .map { $0.capitalized }
            .joined(separator: " ")
    }

    static let displayNames: [String: String] = [
        "cbc_briefing_completed":      "CBC Briefing Completed",
        "bus_departs_cbc":             "Bus Departs CBC",
        "board_aircraft":              "Board the Aircraft",
        "ground_equipment_connected":  "Ground Equipment Connected",
        "pre_flight_checks_completed": "Pre-Flight Checks Completed",
        "auto_boarding_initiated":     "Auto Boarding Initiated",
        "prel_loadsheet_passed":       "Prel-Loadsheet & Fuel Figures Passed",
        "eatl_signed_briefing_done":   "eATL Signed & Briefing Completed",
        "loadsheet_received":          "Loadsheet Received",
        "gpu_acu_disconnected":        "GPU/ACU Disconnected",
        "doors_closed":                "Doors Closed",
        "tow_truck_connected":         "Tow Truck Connected"
    ]

    enum CodingKeys: String, CodingKey {
        case id
        case tMinus    = "t_minus"
        case cbpTMinus = "cbp_t_minus"
        case owners
        case phase
    }
}
