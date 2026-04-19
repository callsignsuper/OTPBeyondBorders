import Foundation
import Observation
import OTPKit

/// In-memory flight store backed by the App Group shared storage so the widget extension
/// sees the same flights the app does. Future: replace with a SwiftData + CloudKit pair.
@MainActor
@Observable
final class FlightStore {
    var flights: [Flight] = [] {
        didSet { sharedStorage.write(flights) }
    }
    var delayLogs: [String: DelayLog] = [:]
    private let sharedStorage: SharedFlightStorage

    /// Grace window after STD before a flight is considered "done" and the store moves on to
    /// the next one. Covers the turnaround case where a crew member forgot to tap doors-closed
    /// but has already boarded their next sector.
    var autoAdvanceGrace: TimeInterval = 30 * 60

    init(sharedStorage: SharedFlightStorage = SharedFlightStorage()) {
        self.sharedStorage = sharedStorage
        self.flights = sharedStorage.read()
    }

    /// First active flight:
    /// - STD in future, OR
    /// - STD in the past but within `autoAdvanceGrace` and doors_closed not marked.
    /// Flights past the grace window — regardless of whether doors_closed was ticked — are
    /// treated as departed and skipped.
    func activeFlight(now: Date = Date()) -> Flight? {
        flights
            .sorted { $0.stdUTC < $1.stdUTC }
            .first { isActive($0, now: now) }
    }

    private func isActive(_ flight: Flight, now: Date) -> Bool {
        if flight.stdUTC > now { return true }
        let overdue = now.timeIntervalSince(flight.stdUTC)
        return overdue < autoAdvanceGrace && !flight.completedMilestones.contains("doors_closed")
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
