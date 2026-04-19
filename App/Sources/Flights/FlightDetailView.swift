import SwiftUI
import OTPKit

struct FlightDetailView: View {
    let flight: Flight
    @Environment(FlightStore.self) private var store
    @Environment(\.selectedRole) private var selectedRole
    @State private var timeline: Timeline?
    @State private var isCBP = false
    @State private var showDelaySheet = false
    @State private var now = Date()
    @State private var directory: AirportDirectory?

    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                AirportTimesPanel(flight: flight, directory: directory, now: now)
                if let timeline {
                    CountdownHeaderView(state: engineState(for: timeline), flight: flight)
                    TimelineStripView(
                        flight: flight, timeline: timeline,
                        isCBP: isCBP, now: now,
                        selectedRole: selectedRole,
                        onToggle: { milestoneID in
                            store.toggleMilestone(milestoneID, on: flight.id)
                        }
                    )
                }
                if isAfterSTDUndeparted {
                    Button("Log delay") { showDelaySheet = true }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                }
            }
            .padding()
        }
        .task { await load() }
        .onReceive(tick) { _ in now = Date() }
        .sheet(isPresented: $showDelaySheet) { LogDelaySheet(flightID: flight.id) }
        .navigationTitle(flight.flightNumber)
        .safeAreaInset(edge: .bottom) {
            UTCClock(now: now)
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            RouteLabel(origin: flight.origin, destination: flight.destination,
                       font: .title2.weight(.bold))
            Spacer()
            Text(flight.category.shortLabel)
                .font(.caption.bold())
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color.otpTeal.opacity(0.15), in: Capsule())
        }
    }

    private var isAfterSTDUndeparted: Bool {
        guard let t = timeline else { return false }
        return engineState(for: t).status == .afterStdUndeparted
    }

    private func engineState(for timeline: Timeline) -> CountdownState {
        CountdownEngine().state(flight: flight, timeline: timeline, isUSCBP: isCBP, now: now)
    }

    private func load() async {
        timeline = try? TimelineLoader().load(flight.category)
        isCBP = (try? CBPResolver().isUSCBP(
            destinationIATA: flight.destination,
            on: flight.stdUTC,
            override: flight.isUSCBPOverride
        )) ?? false
        directory = try? AirportDirectory()
    }
}

/// Origin + destination card with STD / STA + local time + GMT offset. Always shows UTC
/// alongside local — crew members work in UTC operationally.
private struct AirportTimesPanel: View {
    let flight: Flight
    let directory: AirportDirectory?
    let now: Date

    var body: some View {
        VStack(spacing: 12) {
            endpointRow(
                iata: flight.origin,
                title: "DEPART",
                utc: flight.stdUTC,
                utcLabel: "STD",
                role: .origin
            )
            Divider()
            endpointRow(
                iata: flight.destination,
                title: "ARRIVE",
                utc: flight.staUTC,
                utcLabel: "STA",
                role: .destination
            )
        }
        .padding(14)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    private enum Endpoint { case origin, destination }

    @ViewBuilder
    private func endpointRow(iata: String, title: String, utc: Date?, utcLabel: String, role: Endpoint) -> some View {
        let airport = directory?.lookup(iata)
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: role == .origin ? "airplane.departure" : "airplane.arrival")
                        .font(.caption)
                        .foregroundStyle(Color.otpTeal)
                    Text(title)
                        .font(.caption2.weight(.semibold))
                        .tracking(0.6)
                        .foregroundStyle(.secondary)
                }
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(iata)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                    if let name = airport?.name {
                        Text(name)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                if let country = airport?.country {
                    Text(country)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                if let utc {
                    Text("\(utcLabel) \(formatUTC(utc))")
                        .font(.footnote.monospacedDigit().weight(.semibold))
                    if let local = directory?.localTimeString(for: iata, utc: utc),
                       let offset = directory?.utcOffsetLabel(for: iata, at: utc) {
                        Text("\(local) \(offset)")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("—")
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func formatUTC(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeZone = TimeZone(identifier: "UTC")
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "HH:mm'Z'"
        return f.string(from: date)
    }
}

/// Persistent UTC clock. Pinned to the bottom safe area so it's always visible across
/// scrolled views — matches the operational "UTC always on" norm for crew.
private struct UTCClock: View {
    let now: Date

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "globe")
                .font(.caption)
            Text("UTC \(formatted)")
                .font(.footnote.monospacedDigit().weight(.semibold))
                .accessibilityLabel("Coordinated Universal Time \(formatted)")
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(Color.otpNavy, in: Capsule())
        .padding(.bottom, 8)
    }

    private var formatted: String {
        let f = DateFormatter()
        f.timeZone = TimeZone(identifier: "UTC")
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "HH:mm:ss"
        return f.string(from: now)
    }
}

private struct CountdownHeaderView: View {
    let state: CountdownState
    let flight: Flight

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(state.currentPhase?.displayName ?? "—")
                .font(.caption.uppercaseSmallCaps())
                .foregroundStyle(.secondary)
            Text(nextDisplay)
                .font(.system(size: 40, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(Color.otpNavy)
            if let next = state.nextMilestone {
                Text("\(next.milestone.displayName)")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            ProgressBar(pct: state.pctElapsed, color: ownerColor)
                .frame(height: 8)
        }
    }

    private var nextDisplay: String {
        guard let r = state.remainingToNext else { return "—" }
        let mins = Int(r) / 60
        let secs = Int(r) % 60
        if abs(mins) >= 60 {
            let h = mins / 60
            let m = abs(mins) % 60
            return String(format: "%d:%02d", h, m)
        }
        return String(format: "%02d:%02d", max(mins, 0), max(secs, 0))
    }

    private var ownerColor: Color {
        guard let role = state.ownerRoles.first else { return Color.otpTeal }
        return Color.role(role)
    }
}

private struct ProgressBar: View {
    let pct: Double
    let color: Color
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.gray.opacity(0.2))
                Capsule().fill(color).frame(width: geo.size.width * pct)
            }
        }
    }
}
