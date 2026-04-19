import Foundation

public struct Airport: Sendable, Codable, Hashable, Identifiable {
    public var id: String { iata }
    public let iata: String
    public let name: String
    public let city: String
    public let country: String
    /// IANA time-zone identifier (e.g. `"America/New_York"`).
    public let tz: String

    public var timeZone: TimeZone? { TimeZone(identifier: tz) }

    /// "YYZ · Toronto Pearson"
    public var compactLabel: String { "\(iata) · \(name)" }

    /// "Toronto Pearson, Canada"
    public var longLabel: String { "\(name), \(country)" }
}

public struct AirportList: Sendable, Codable {
    public let lastUpdated: String
    public let source: String
    public let airports: [Airport]

    enum CodingKeys: String, CodingKey {
        case lastUpdated = "last_updated"
        case source, airports
    }
}

/// Lookup helper for the bundled airport catalog. O(1) lookup by IATA code.
public struct AirportDirectory: Sendable {
    private let byIATA: [String: Airport]
    public let all: [Airport]

    public init(airports: [Airport]) {
        self.all = airports
        var map: [String: Airport] = [:]
        for a in airports { map[a.iata.uppercased()] = a }
        self.byIATA = map
    }

    public init() throws {
        let list = try TimelineLoader().loadJSON(
            AirportList.self, named: "airports", subdirectory: "data"
        )
        self.init(airports: list.airports)
    }

    public init(bundle: Bundle) throws {
        let list = try TimelineLoader(bundle: bundle).loadJSON(
            AirportList.self, named: "airports", subdirectory: "data"
        )
        self.init(airports: list.airports)
    }

    public func lookup(_ iata: String) -> Airport? {
        byIATA[iata.uppercased()]
    }

    /// Formats a UTC date in the given airport's local time zone, e.g. `"Mon 20 Apr, 13:45"`.
    public func localTimeString(
        for iata: String,
        utc: Date,
        style: DateFormatter.Style = .short
    ) -> String? {
        guard let airport = lookup(iata), let tz = airport.timeZone else { return nil }
        let f = DateFormatter()
        f.timeZone = tz
        f.locale = Locale.current
        f.dateStyle = .none
        f.timeStyle = style
        return f.string(from: utc)
    }

    /// GMT offset label for an airport, e.g. `"UTC+4"` or `"UTC-4"` or `"UTC"`.
    public func utcOffsetLabel(for iata: String, at instant: Date = Date()) -> String? {
        guard let airport = lookup(iata), let tz = airport.timeZone else { return nil }
        let offset = tz.secondsFromGMT(for: instant)
        if offset == 0 { return "UTC" }
        let hours = Double(offset) / 3600.0
        if hours.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "UTC%+d", Int(hours))
        }
        let h = Int(offset / 3600)
        let m = abs((offset % 3600) / 60)
        return String(format: "UTC%+d:%02d", h, m)
    }
}
