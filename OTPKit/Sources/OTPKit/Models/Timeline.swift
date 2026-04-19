import Foundation

public struct Timeline: Sendable, Hashable, Codable {
    public let aircraftCategory: String
    public let aircraftTypes: [String]
    public let totalOTPWindow: TotalWindow
    public let cbpFirstTwoStepsOffsetMin: Int?
    public let usCBPApplicable: Bool
    public let milestones: [Milestone]
    public let notes: Notes?
    public let lrv: LRV?

    public struct TotalWindow: Sendable, Hashable, Codable {
        public let standard: Int
        public let usCBP: Int?

        enum CodingKeys: String, CodingKey {
            case standard
            case usCBP = "us_cbp"
        }
    }

    public struct Notes: Sendable, Hashable, Codable {
        public let busBriefing: String?
        public let sequence: String?
        public let source: String?

        enum CodingKeys: String, CodingKey {
            case busBriefing = "bus_briefing"
            case sequence
            case source
        }
    }

    public struct LRV: Sendable, Hashable, Codable {
        public let comment: String
        public let variations: [String: String]
    }

    public func window(isUSCBP: Bool) -> Int {
        if isUSCBP, let cbp = totalOTPWindow.usCBP { return cbp }
        return totalOTPWindow.standard
    }

    /// Milestones sorted most-negative-tMinus first (furthest before STD, i.e. earliest in wall-clock time).
    /// Matches the document's reading order: CBC briefing first, doors closed last.
    public func sortedMilestones(isUSCBP: Bool) -> [Milestone] {
        milestones.sorted { a, b in
            a.effectiveTMinus(isUSCBP: isUSCBP) > b.effectiveTMinus(isUSCBP: isUSCBP)
        }
    }

    enum CodingKeys: String, CodingKey {
        case aircraftCategory          = "aircraft_category"
        case aircraftTypes             = "aircraft_types"
        case totalOTPWindow            = "total_otp_window_min"
        case cbpFirstTwoStepsOffsetMin = "cbp_first_two_steps_offset_min"
        case usCBPApplicable           = "us_cbp_applicable"
        case milestones
        case notes
        case lrv
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.aircraftCategory          = try c.decode(String.self, forKey: .aircraftCategory)
        self.aircraftTypes             = try c.decodeIfPresent([String].self, forKey: .aircraftTypes) ?? []
        self.totalOTPWindow            = try c.decode(TotalWindow.self, forKey: .totalOTPWindow)
        self.cbpFirstTwoStepsOffsetMin = try c.decodeIfPresent(Int.self, forKey: .cbpFirstTwoStepsOffsetMin)
        self.usCBPApplicable           = try c.decodeIfPresent(Bool.self, forKey: .usCBPApplicable) ?? true
        self.milestones                = try c.decode([Milestone].self, forKey: .milestones)
        self.notes                     = try c.decodeIfPresent(Notes.self, forKey: .notes)
        self.lrv                       = try c.decodeIfPresent(LRV.self, forKey: .lrv)
    }

    public init(
        aircraftCategory: String,
        aircraftTypes: [String],
        totalOTPWindow: TotalWindow,
        cbpFirstTwoStepsOffsetMin: Int?,
        usCBPApplicable: Bool,
        milestones: [Milestone],
        notes: Notes? = nil,
        lrv: LRV? = nil
    ) {
        self.aircraftCategory          = aircraftCategory
        self.aircraftTypes             = aircraftTypes
        self.totalOTPWindow            = totalOTPWindow
        self.cbpFirstTwoStepsOffsetMin = cbpFirstTwoStepsOffsetMin
        self.usCBPApplicable           = usCBPApplicable
        self.milestones                = milestones
        self.notes                     = notes
        self.lrv                       = lrv
    }
}
