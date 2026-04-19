import WidgetKit
import OTPKit
import Foundation

struct OTPWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: Snapshot
}

/// Self-contained snapshot so the widget view never reaches back into storage.
struct Snapshot {
    let flightHeader: String
    let phaseName: String
    let countdownText: String
    let progressPct: Double
    let nextMilestoneLabel: String
    let ownerRoles: [Role]
    let isDelayPrompt: Bool

    static let placeholder = Snapshot(
        flightHeader: "EY21  AUH → YYZ  A380",
        phaseName: "Pre-Flight Checks",
        countdownText: "12:34",
        progressPct: 0.42,
        nextMilestoneLabel: "Prel-Loadsheet in 12m",
        ownerRoles: [.pilots],
        isDelayPrompt: false
    )
}

struct OTPWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> OTPWidgetEntry {
        OTPWidgetEntry(date: Date(), snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (OTPWidgetEntry) -> Void) {
        completion(OTPWidgetEntry(date: Date(), snapshot: demoFlightSnapshot(at: Date())))
    }

    func getTimeline(in context: Context, completion: @escaping (WidgetKit.Timeline<OTPWidgetEntry>) -> Void) {
        let now = Date()
        // One entry per minute for the next 90 minutes.
        let entries: [OTPWidgetEntry] = (0..<90).map { offset in
            let t = now.addingTimeInterval(Double(offset) * 60)
            return OTPWidgetEntry(date: t, snapshot: demoFlightSnapshot(at: t))
        }
        completion(WidgetKit.Timeline(entries: entries, policy: .atEnd))
    }

    private func demoFlightSnapshot(at date: Date) -> Snapshot {
        // Until FlightStore sharing via App Groups is wired up, the widget renders a stable
        // demo flight so the lock-screen preview is meaningful. Replace with real store lookup
        // once the App Group entitlement lands.
        let flight = Flight(
            flightNumber: "EY21",
            sectorCode: "21A",
            origin: "AUH",
            destination: "YYZ",
            reportingUTC: date.addingTimeInterval(-30 * 60),
            stdUTC:       date.addingTimeInterval(75 * 60),
            category: .a380
        )
        guard let timeline = try? TimelineLoader().load(flight.category) else {
            return .placeholder
        }
        let cbp = (try? CBPResolver().isUSCBP(destinationIATA: flight.destination, on: flight.stdUTC)) ?? false
        let state = CountdownEngine().state(flight: flight, timeline: timeline, isUSCBP: cbp, now: date)

        let countdown: String = {
            guard let r = state.remainingToNext else { return "--:--" }
            let mins = Int(r) / 60
            let secs = Int(r) % 60
            return String(format: "%02d:%02d", max(mins, 0), max(secs, 0))
        }()

        let nextLabel = state.nextMilestone.map {
            "\($0.milestone.displayName) in \(Int(max($0.targetTime.timeIntervalSince(date), 0)) / 60)m"
        } ?? "Post-STD"

        return Snapshot(
            flightHeader: "\(flight.flightNumber)  \(flight.origin) → \(flight.destination)  \(flight.category.shortLabel)",
            phaseName: state.currentPhase?.displayName ?? "—",
            countdownText: countdown,
            progressPct: state.pctElapsed,
            nextMilestoneLabel: nextLabel,
            ownerRoles: state.ownerRoles,
            isDelayPrompt: state.status == .afterStdUndeparted
        )
    }
}
