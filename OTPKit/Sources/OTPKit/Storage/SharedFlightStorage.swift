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

    /// First flight whose STD is still in the future.
    public func nextFlight(now: Date = Date()) -> Flight? {
        read()
            .filter { $0.stdUTC > now }
            .sorted { $0.stdUTC < $1.stdUTC }
            .first
    }

    private func fileURL() -> URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent(fileName)
    }
}
