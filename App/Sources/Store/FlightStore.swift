import Foundation
import Observation
import OTPKit

/// In-memory flight store for v1 scaffold.
/// Future: SwiftData + CloudKit mirror per the plan in CLAUDE.md / TESTING.md.
@MainActor
@Observable
final class FlightStore {
    var flights: [Flight] = []
    var delayLogs: [String: DelayLog] = [:]

    var nextFlight: Flight? {
        flights
            .filter { $0.stdUTC > Date() }
            .sorted { $0.stdUTC < $1.stdUTC }
            .first
    }

    func upsert(_ flight: Flight) {
        if let idx = flights.firstIndex(where: { $0.id == flight.id }) {
            flights[idx] = flight
        } else {
            flights.append(flight)
        }
    }

    func toggleMilestone(_ id: String, on flightID: String) {
        guard let idx = flights.firstIndex(where: { $0.id == flightID }) else { return }
        if flights[idx].completedMilestones.contains(id) {
            flights[idx].completedMilestones.remove(id)
        } else {
            flights[idx].completedMilestones.insert(id)
        }
    }

    func logDelay(_ log: DelayLog, on flightID: String) {
        guard let idx = flights.firstIndex(where: { $0.id == flightID }) else { return }
        flights[idx].delayLog = log
        delayLogs[flightID] = log
    }
}
