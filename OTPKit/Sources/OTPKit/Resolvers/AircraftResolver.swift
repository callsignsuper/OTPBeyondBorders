import Foundation

public struct AircraftResolver: Sendable {
    private let fleetMap: FleetRouteMap

    public init(fleetMap: FleetRouteMap) {
        self.fleetMap = fleetMap
    }

    public init() throws {
        self.fleetMap = try FleetRouteMapLoader().load()
    }

    public init(bundle: Bundle) throws {
        self.fleetMap = try FleetRouteMapLoader(bundle: bundle).load()
    }

    /// Resolves an aircraft category with clear precedence: user override > static fleet map > nil (caller must ask user).
    public func resolve(
        flightNumber: String,
        on date: Date,
        userOverride: AircraftCategory? = nil
    ) -> AircraftCategory? {
        if let userOverride { return userOverride }
        return fleetMap.route(forFlightNumber: flightNumber, on: date)?.category
    }

    public func route(flightNumber: String, on date: Date) -> FleetRouteMap.Route? {
        fleetMap.route(forFlightNumber: flightNumber, on: date)
    }
}
