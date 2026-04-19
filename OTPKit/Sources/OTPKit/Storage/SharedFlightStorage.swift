import Foundation

/// File-backed storage in an App Group container, shared between the iOS app and the widget extension.
///
/// v1 uses a single JSON file (`flights.json`) — simple, atomic on the filesystem, and good enough for
/// the "next flight only" read path the widget needs. When SwiftData lands we'll replace this with a
/// shared store, but this seam stays the same from the widget's point of view.
public struct SharedFlightStorage: Sendable {
    public let appGroupID: String
    private let fileName = "flights.json"

    public init(appGroupID: String = "group.com.otpbb.shared") {
        self.appGroupID = appGroupID
    }

    public func write(_ flights: [Flight]) {
        guard let url = fileURL() else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        do {
            let data = try encoder.encode(flights)
            try data.write(to: url, options: .atomic)
        } catch {
            // Intentionally silent — write failures shouldn't crash the UI thread.
        }
    }

    public func read() -> [Flight] {
        guard let url = fileURL(), FileManager.default.fileExists(atPath: url.path) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([Flight].self, from: Data(contentsOf: url))) ?? []
    }

    /// First *active* flight — STD in future, or within `grace` seconds after STD with
    /// doors_closed not marked. Past-grace flights are treated as departed so a crew member
    /// on a turnaround rotation sees the next sector without having to open the app.
    public func activeFlight(
        now: Date = Date(),
        grace: TimeInterval = 30 * 60
    ) -> Flight? {
        read()
            .sorted { $0.stdUTC < $1.stdUTC }
            .first { flight in
                if flight.stdUTC > now { return true }
                let overdue = now.timeIntervalSince(flight.stdUTC)
                return overdue < grace && !flight.completedMilestones.contains("doors_closed")
            }
    }

    private func fileURL() -> URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent(fileName)
    }
}
