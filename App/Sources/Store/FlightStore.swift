import Foundation
import Observation
import OTPKit

/// In-memory flight store for v1 scaffold.
/// Future: SwiftData + CloudKit mirror per the plan in CLAUDE.md / TESTING.md.
@MainActor
@Observable
final class FlightStore {
    var flights: [Flight] = [] {
        didSet { sharedStorage.write(flights) }
    }
    var delayLogs: [String: DelayLog] = [:]
    private let sharedStorage: SharedFlightStorage

    init(sharedStorage: SharedFlightStorage = SharedFlightStorage()) {
        self.sharedStorage = sharedStorage
        // Prefer real flights from shared storage; fall back to demo in DEBUG.
        let existing = sharedStorage.read()
        if !existing.isEmpty {
            self.flights = existing
        } else {
            #if DEBUG
            if ProcessInfo.processInfo.environment["OTPBB_SEED_DEMO_FLIGHT"] != "0" {
                seedDemoFlight()
            }
            #endif
        }
    }

    var nextFlight: Flight? {
        flights
            .filter { $0.stdUTC > Date() }
            .sorted { $0.stdUTC < $1.stdUTC }
            .first
    }

    #if DEBUG
    private func seedDemoFlight() {
        // Synthetic flight for previews and simulator runs.
        let now = Date()
        flights = [
            Flight(
                flightNumber: "EY21",
                sectorCode:   "21A",
                origin:       "AUH",
                destination:  "YYZ",
                reportingUTC: now.addingTimeInterval(-20 * 60),
                stdUTC:       now.addingTimeInterval(85 * 60),
                staUTC:       now.addingTimeInterval(13 * 3600),
                category:     .a380
            ),
            Flight(
                flightNumber: "EY11",
                sectorCode:   "11A",
                origin:       "AUH",
                destination:  "JFK",
                reportingUTC: now.addingTimeInterval(28 * 3600),
                stdUTC:       now.addingTimeInterval(29 * 3600 + 55 * 60),
                staUTC:       now.addingTimeInterval(42 * 3600),
                category:     .a380
            )
        ]
    }
    #endif

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
