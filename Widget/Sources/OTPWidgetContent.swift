import SwiftUI
import OTPKit

/// Render-only snapshot for the rectangular lock-screen widget. Pure data — no WidgetKit.
/// Shared between the widget extension (via TimelineEntry) and the iOS app (via a debug preview).
public struct OTPWidgetSnapshot: Sendable, Hashable {
    public let flightNumber: String
    public let origin: String
    public let destination: String
    public let originCity: String?
    public let destinationCity: String?
    public let aircraftLabel: String
    public let phaseName: String
    public let countdownText: String
    public let progressPct: Double
    public let nextMilestoneLabel: String
    public let ownerRoles: [Role]
    public let isDelayPrompt: Bool
    /// STA in the destination's local time zone, pre-formatted (e.g. `"13:45"`). Nil if unknown.
    public let destinationArrivalLocal: String?
    public let destinationUTCOffset: String?
    /// UTC "now" label at the snapshot instant, e.g. `"13:45 UTC"`. Always present.
    public let utcNowLabel: String

    public var routeLabel: String { "\(origin) → \(destination)" }

    public init(
        flightNumber: String,
        origin: String,
        destination: String,
        originCity: String? = nil,
        destinationCity: String? = nil,
        aircraftLabel: String,
        phaseName: String,
        countdownText: String,
        progressPct: Double,
        nextMilestoneLabel: String,
        ownerRoles: [Role],
        isDelayPrompt: Bool,
        destinationArrivalLocal: String? = nil,
        destinationUTCOffset: String? = nil,
        utcNowLabel: String
    ) {
        self.flightNumber = flightNumber
        self.origin = origin
        self.destination = destination
        self.originCity = originCity
        self.destinationCity = destinationCity
        self.aircraftLabel = aircraftLabel
        self.phaseName = phaseName
        self.countdownText = countdownText
        self.progressPct = progressPct
        self.nextMilestoneLabel = nextMilestoneLabel
        self.ownerRoles = ownerRoles
        self.isDelayPrompt = isDelayPrompt
        self.destinationArrivalLocal = destinationArrivalLocal
        self.destinationUTCOffset = destinationUTCOffset
        self.utcNowLabel = utcNowLabel
    }

    /// Neutral loading-state snapshot. Used only as a transient render while WidgetKit builds
    /// a real timeline entry. Intentionally contains NO flight-number / route / city data so the
    /// shipped Release binary never embeds a fake flight a user might mistake for their own.
    public static let placeholder = OTPWidgetSnapshot(
        flightNumber: "—",
        origin: "—",
        destination: "—",
        originCity: nil,
        destinationCity: nil,
        aircraftLabel: "",
        phaseName: "",
        countdownText: "--:--",
        progressPct: 0,
        nextMilestoneLabel: "",
        ownerRoles: [],
        isDelayPrompt: false,
        destinationArrivalLocal: nil,
        destinationUTCOffset: nil,
        utcNowLabel: ""
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

        let directory = try? AirportDirectory()
        let originCity = directory?.lookup(flight.origin)?.city
        let destCity = directory?.lookup(flight.destination)?.city
        let destOffset = directory?.utcOffsetLabel(for: flight.destination, at: flight.staUTC ?? now)
        let destArrival: String? = {
            guard let sta = flight.staUTC else { return nil }
            return directory?.localTimeString(for: flight.destination, utc: sta)
        }()

        return OTPWidgetSnapshot(
            flightNumber: flight.flightNumber,
            origin: flight.origin,
            destination: flight.destination,
            originCity: originCity,
            destinationCity: destCity,
            aircraftLabel: flight.category.shortLabel,
            phaseName: state.currentPhase?.displayName ?? "—",
            countdownText: countdown,
            progressPct: state.pctElapsed,
            nextMilestoneLabel: nextLabel,
            ownerRoles: state.ownerRoles,
            isDelayPrompt: state.status == .afterStdUndeparted,
            destinationArrivalLocal: destArrival,
            destinationUTCOffset: destOffset,
            utcNowLabel: utcNowLabel(for: now)
        )
    }

    private static func utcNowLabel(for date: Date) -> String {
        let f = DateFormatter()
        f.timeZone = TimeZone(identifier: "UTC")
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "HH:mm"
        return "\(f.string(from: date))Z"
    }
}

/// Direction-aware route header: `ORIGIN → DEST` in LTR, automatically mirrored in RTL via
/// the `arrow.forward` SF Symbol (renders as ← in Arabic/Hebrew layouts).
public struct RouteLabel: View {
    let origin: String
    let destination: String
    var font: Font = .caption2.monospacedDigit()
    var symbolWeight: Font.Weight = .semibold

    public init(origin: String, destination: String, font: Font = .caption2.monospacedDigit(), symbolWeight: Font.Weight = .semibold) {
        self.origin = origin
        self.destination = destination
        self.font = font
        self.symbolWeight = symbolWeight
    }

    public var body: some View {
        HStack(spacing: 4) {
            Text(origin)
            Image(systemName: "arrow.forward")
                .font(font.weight(symbolWeight))
            Text(destination)
        }
        .font(font)
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
            HStack(spacing: 6) {
                Text(snapshot.flightNumber)
                    .font(.caption2.monospacedDigit().weight(.semibold))
                RouteLabel(origin: snapshot.origin, destination: snapshot.destination)
                Text(snapshot.aircraftLabel)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
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
                RouteLabel(origin: snapshot.origin, destination: snapshot.destination)
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
                RouteLabel(origin: snapshot.origin, destination: snapshot.destination,
                           font: .caption.monospacedDigit())
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

            // Right column: owner + arrival + progress.
            VStack(alignment: .leading, spacing: 6) {
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
                    Text(snapshot.utcNowLabel)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Text(snapshot.nextMilestoneLabel)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                if let arrival = snapshot.destinationArrivalLocal,
                   let city = snapshot.destinationCity,
                   let offset = snapshot.destinationUTCOffset {
                    Text("Arr \(arrival) \(city) · \(offset)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
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
