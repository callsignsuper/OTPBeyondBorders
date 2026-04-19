import Foundation

public struct CBPAirportList: Sendable, Codable {
    public struct Airport: Sendable, Codable, Hashable {
        public let iata: String
        public let name: String
        public let cbpPreclearanceAtAUH: Bool
        public let launchDate: Date?

        enum CodingKeys: String, CodingKey {
            case iata, name
            case cbpPreclearanceAtAUH = "cbp_preclearance_at_auh"
            case launchDate           = "launch_date"
        }

        public init(from decoder: any Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            self.iata = try c.decode(String.self, forKey: .iata)
            self.name = try c.decode(String.self, forKey: .name)
            self.cbpPreclearanceAtAUH = try c.decode(Bool.self, forKey: .cbpPreclearanceAtAUH)
            if let dateStr = try c.decodeIfPresent(String.self, forKey: .launchDate) {
                self.launchDate = Self.dateFormatter.date(from: dateStr)
            } else {
                self.launchDate = nil
            }
        }

        public init(iata: String, name: String, cbpPreclearanceAtAUH: Bool, launchDate: Date? = nil) {
            self.iata = iata
            self.name = name
            self.cbpPreclearanceAtAUH = cbpPreclearanceAtAUH
            self.launchDate = launchDate
        }

        public func encode(to encoder: any Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(iata, forKey: .iata)
            try c.encode(name, forKey: .name)
            try c.encode(cbpPreclearanceAtAUH, forKey: .cbpPreclearanceAtAUH)
            if let d = launchDate {
                try c.encode(Self.dateFormatter.string(from: d), forKey: .launchDate)
            }
        }

        static let dateFormatter: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            f.timeZone = TimeZone(identifier: "UTC")
            f.locale = Locale(identifier: "en_US_POSIX")
            return f
        }()
    }

    public let lastUpdated: String
    public let source: String
    public let rule: String
    public let airports: [Airport]

    enum CodingKeys: String, CodingKey {
        case lastUpdated = "last_updated"
        case source, rule, airports
    }
}

public struct CBPAirportsLoader: Sendable {
    private let bundle: Bundle
    public init() { self.bundle = .module }
    public init(bundle: Bundle) { self.bundle = bundle }

    public func load() throws -> CBPAirportList {
        try TimelineLoader(bundle: bundle).loadJSON(
            CBPAirportList.self,
            named: "us_cbp_airports",
            subdirectory: "data"
        )
    }
}
