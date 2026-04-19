import SwiftUI
import OTPKit

/// Render-only snapshot for the rectangular lock-screen widget. Pure data — no WidgetKit.
/// Shared between the widget extension (via TimelineEntry) and the iOS app (via a debug preview).
public struct OTPWidgetSnapshot: Sendable, Hashable {
    public let flightHeader: String
    public let phaseName: String
    public let countdownText: String
    public let progressPct: Double
    public let nextMilestoneLabel: String
    public let ownerRoles: [Role]
    public let isDelayPrompt: Bool

    public init(
        flightHeader: String,
        phaseName: String,
        countdownText: String,
        progressPct: Double,
        nextMilestoneLabel: String,
        ownerRoles: [Role],
        isDelayPrompt: Bool
    ) {
        self.flightHeader = flightHeader
        self.phaseName = phaseName
        self.countdownText = countdownText
        self.progressPct = progressPct
        self.nextMilestoneLabel = nextMilestoneLabel
        self.ownerRoles = ownerRoles
        self.isDelayPrompt = isDelayPrompt
    }

    public static let placeholder = OTPWidgetSnapshot(
        flightHeader: "EY21  AUH → YYZ  A380",
        phaseName: "Pre-Flight Checks",
        countdownText: "12:34",
        progressPct: 0.42,
        nextMilestoneLabel: "Prel-Loadsheet in 12m",
        ownerRoles: [.pilots],
        isDelayPrompt: false
    )

    /// Build a snapshot by running the CountdownEngine for the given flight + `now`.
    public static func build(for flight: Flight, at now: Date) -> OTPWidgetSnapshot {
        guard let timeline = try? TimelineLoader().load(flight.category) else {
            return .placeholder
        }
        let isCBP = (try? CBPResolver().isUSCBP(
            destinationIATA: flight.destination,
            on: flight.stdUTC,
            override: flight.isUSCBPOverride
        )) ?? false
        let state = CountdownEngine().state(
            flight: flight, timeline: timeline, isUSCBP: isCBP, now: now
        )

        let countdown: String = {
            guard let r = state.remainingToNext else { return "--:--" }
            let mins = Int(r) / 60
            let secs = Int(r) % 60
            if abs(mins) >= 60 {
                return String(format: "%d:%02d", mins / 60, abs(mins) % 60)
            }
            return String(format: "%02d:%02d", max(mins, 0), max(secs, 0))
        }()

        let nextLabel: String = state.nextMilestone.map { resolved in
            let mins = Int(max(resolved.targetTime.timeIntervalSince(now), 0)) / 60
            return "\(resolved.milestone.displayName) in \(mins)m"
        } ?? "Post-STD"

        return OTPWidgetSnapshot(
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

/// Pure-SwiftUI rendering of the widget's rectangular content.
/// The widget extension wraps this with WidgetKit-specific modifiers (`.widgetURL`, container background).
public struct OTPRectangularContent: View {
    let snapshot: OTPWidgetSnapshot

    public init(snapshot: OTPWidgetSnapshot) {
        self.snapshot = snapshot
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(snapshot.flightHeader)
                .font(.caption2.monospacedDigit())
                .lineLimit(1)
            Text(snapshot.phaseName)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            if snapshot.isDelayPrompt {
                Text("Log delay")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.red)
            } else {
                Text(snapshot.countdownText)
                    .font(.title3.bold().monospacedDigit())
            }
            ProgressView(value: snapshot.progressPct)
                .tint(ownerColor)
            Text(snapshot.nextMilestoneLabel)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private var ownerColor: Color {
        guard let role = snapshot.ownerRoles.first else { return .accentColor }
        let rgb = Palette.approximate.color(for: role)
        return Color(red: rgb.red, green: rgb.green, blue: rgb.blue, opacity: rgb.alpha)
    }
}
