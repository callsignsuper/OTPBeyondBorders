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

    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
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
