import Foundation

public struct CBPResolver: Sendable {
    private let airports: [CBPAirportList.Airport]

    public init(airports: [CBPAirportList.Airport]) {
        self.airports = airports
    }

    public init() throws {
        self.airports = try CBPAirportsLoader().load().airports
    }

    public init(bundle: Bundle) throws {
        self.airports = try CBPAirportsLoader(bundle: bundle).load().airports
    }

    public func isUSCBP(destinationIATA: String, on date: Date, override: Bool? = nil) -> Bool {
        if let override { return override }
        let code = destinationIATA.uppercased()
        guard let airport = airports.first(where: { $0.iata == code }) else { return false }
        guard airport.cbpPreclearanceAtAUH else { return false }
        if let launch = airport.launchDate, date < launch { return false }
        return true
    }
}
