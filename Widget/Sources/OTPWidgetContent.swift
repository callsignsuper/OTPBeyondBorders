import SwiftUI
import OTPKit

/// Render-only snapshot for the rectangular lock-screen widget. Pure data — no WidgetKit.
/// Shared between the widget extension (via TimelineEntry) and the iOS app (via a debug preview).
public struct OTPWidgetSnapshot: Sendable, Hashable {
    public let flightNumber: String
    public let routeLabel: String
    public let aircraftLabel: String
    public let phaseName: String
    public let countdownText: String
    public let progressPct: Double
    public let nextMilestoneLabel: String
    public let ownerRoles: [Role]
    public let isDelayPrompt: Bool

    public var flightHeader: String {
        "\(flightNumber)  \(routeLabel)  \(aircraftLabel)"
    }

    public init(
        flightNumber: String,
        routeLabel: String,
        aircraftLabel: String,
        phaseName: String,
        countdownText: String,
        progressPct: Double,
        nextMilestoneLabel: String,
        ownerRoles: [Role],
        isDelayPrompt: Bool
    ) {
        self.flightNumber = flightNumber
        self.routeLabel = routeLabel
        self.aircraftLabel = aircraftLabel
        self.phaseName = phaseName
        self.countdownText = countdownText
        self.progressPct = progressPct
        self.nextMilestoneLabel = nextMilestoneLabel
        self.ownerRoles = ownerRoles
        self.isDelayPrompt = isDelayPrompt
    }

    public static let placeholder = OTPWidgetSnapshot(
        flightNumber: "EY21",
        routeLabel: "AUH → YYZ",
        aircraftLabel: "A380",
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
            flightNumber: flight.flightNumber,
            routeLabel: "\(flight.origin) → \(flight.destination)",
            aircraftLabel: flight.category.shortLabel,
            phaseName: state.currentPhase?.displayName ?? "—",
            countdownText: countdown,
            progressPct: state.pctElapsed,
            nextMilestoneLabel: nextLabel,
            ownerRoles: state.ownerRoles,
            isDelayPrompt: state.status == .afterStdUndeparted
        )
    }
}

/// Pure-SwiftUI rendering of the widget's rectangular (lock-screen accessory) content.
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
                .tint(ownerColorRectangular)
            Text(snapshot.nextMilestoneLabel)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private var ownerColorRectangular: Color {
        guard let role = snapshot.ownerRoles.first else { return .accentColor }
        let rgb = Palette.approximate.color(for: role)
        return Color(red: rgb.red, green: rgb.green, blue: rgb.blue, opacity: rgb.alpha)
    }
}

// MARK: - systemSmall

public struct OTPSmallContent: View {
    let snapshot: OTPWidgetSnapshot
    public init(snapshot: OTPWidgetSnapshot) { self.snapshot = snapshot }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text(snapshot.flightNumber)
                    .font(.caption.weight(.semibold))
                Spacer()
                Text(snapshot.routeLabel)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Text(snapshot.phaseName.uppercased())
                .font(.caption2)
                .tracking(0.6)
                .foregroundStyle(ownerColor)
            Spacer(minLength: 0)
            if snapshot.isDelayPrompt {
                Text("DELAY")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.red)
                Text("Log now")
                    .font(.title.bold().monospacedDigit())
                    .foregroundStyle(.red)
            } else {
                Text(snapshot.countdownText)
                    .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.7)
            }
            ProgressView(value: snapshot.progressPct)
                .tint(ownerColor)
            Text(snapshot.nextMilestoneLabel)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(14)
    }

    private var ownerColor: Color {
        guard let role = snapshot.ownerRoles.first else { return .accentColor }
        let rgb = Palette.approximate.color(for: role)
        return Color(red: rgb.red, green: rgb.green, blue: rgb.blue, opacity: rgb.alpha)
    }
}

// MARK: - systemMedium

public struct OTPMediumContent: View {
    let snapshot: OTPWidgetSnapshot
    public init(snapshot: OTPWidgetSnapshot) { self.snapshot = snapshot }

    public var body: some View {
        HStack(alignment: .top, spacing: 18) {
            // Left column: countdown + phase.
            VStack(alignment: .leading, spacing: 6) {
                Text(snapshot.flightNumber)
                    .font(.headline.weight(.bold))
                Text(snapshot.routeLabel)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Spacer(minLength: 4)
                Text(snapshot.phaseName.uppercased())
                    .font(.caption2)
                    .tracking(0.6)
                    .foregroundStyle(ownerColor)
                if snapshot.isDelayPrompt {
                    Text("DELAY")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.red)
                    Text("Log delay")
                        .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(.red)
                } else {
                    Text(snapshot.countdownText)
                        .font(.system(size: 40, weight: .bold, design: .rounded).monospacedDigit())
                        .minimumScaleFactor(0.7)
                }
            }

            // Right column: owner chips + next milestone.
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    ForEach(snapshot.ownerRoles, id: \.self) { role in
                        Circle()
                            .fill(colorFor(role))
                            .frame(width: 10, height: 10)
                        Text(role.displayName)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(colorFor(role))
                    }
                    Spacer()
                }
                Text(snapshot.nextMilestoneLabel)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                Spacer(minLength: 0)
                ProgressView(value: snapshot.progressPct)
                    .tint(ownerColor)
                    .scaleEffect(y: 1.4, anchor: .center)
                Text("\(Int(snapshot.progressPct * 100))% of OTP window elapsed")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
    }

    private var ownerColor: Color {
        guard let role = snapshot.ownerRoles.first else { return .accentColor }
        return colorFor(role)
    }

    private func colorFor(_ role: Role) -> Color {
        let rgb = Palette.approximate.color(for: role)
        return Color(red: rgb.red, green: rgb.green, blue: rgb.blue, opacity: rgb.alpha)
    }
}
