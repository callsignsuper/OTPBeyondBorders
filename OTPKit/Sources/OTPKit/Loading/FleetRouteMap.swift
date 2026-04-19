import Foundation

public struct FleetRouteMap: Sendable, Codable {
    public struct Route: Sendable, Codable, Hashable {
        public let flightNumber: String
        public let origin: String
        public let destination: String
        public let category: AircraftCategory
        public let aircraftType: String?
        public let effectiveFrom: Date?

        enum CodingKeys: String, CodingKey {
            case flightNumber  = "flight_number"
            case origin, destination, category
            case aircraftType  = "aircraft_type"
            case effectiveFrom = "effective_from"
        }

        public init(from decoder: any Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            self.flightNumber = try c.decode(String.self, forKey: .flightNumber)
            self.origin       = try c.decode(String.self, forKey: .origin)
            self.destination  = try c.decode(String.self, forKey: .destination)
            self.category     = try c.decode(AircraftCategory.self, forKey: .category)
            self.aircraftType = try c.decodeIfPresent(String.self, forKey: .aircraftType)
            if let s = try c.decodeIfPresent(String.self, forKey: .effectiveFrom) {
                self.effectiveFrom = CBPAirportList.Airport.dateFormatter.date(from: s)
            } else {
                self.effectiveFrom = nil
            }
        }

        public init(
            flightNumber: String,
            origin: String,
            destination: String,
            category: AircraftCategory,
            aircraftType: String? = nil,
            effectiveFrom: Date? = nil
        ) {
            self.flightNumber  = flightNumber
            self.origin        = origin
            self.destination   = destination
            self.category      = category
            self.aircraftType  = aircraftType
            self.effectiveFrom = effectiveFrom
        }

        public func encode(to encoder: any Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(flightNumber, forKey: .flightNumber)
            try c.encode(origin,       forKey: .origin)
            try c.encode(destination,  forKey: .destination)
            try c.encode(category,     forKey: .category)
            try c.encodeIfPresent(aircraftType, forKey: .aircraftType)
            if let d = effectiveFrom {
                try c.encode(CBPAirportList.Airport.dateFormatter.string(from: d), forKey: .effectiveFrom)
            }
        }
    }

    public let lastUpdated: String
    public let seedNote: String?
    public let source: String?
    public let routes: [Route]

    enum CodingKeys: String, CodingKey {
        case lastUpdated = "last_updated"
        case seedNote    = "seed_note"
        case source
        case routes
    }

    public func route(forFlightNumber number: String, on date: Date) -> Route? {
        let matches = routes.filter { $0.flightNumber.caseInsensitiveCompare(number) == .orderedSame }
        let live    = matches.filter { ($0.effectiveFrom ?? .distantPast) <= date }
        return live.first ?? matches.first
    }
}

public struct FleetRouteMapLoader: Sendable {
    private let bundle: Bundle
    public init() { self.bundle = .module }
    public init(bundle: Bundle) { self.bundle = bundle }

    public func load() throws -> FleetRouteMap {
        try TimelineLoader(bundle: bundle).loadJSON(
            FleetRouteMap.self,
            named: "fleet_routes",
            subdirectory: "data"
        )
    }
}
