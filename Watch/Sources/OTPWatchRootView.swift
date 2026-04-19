import SwiftUI
import OTPKit

struct OTPWatchRootView: View {
    @State private var now = Date()
    @State private var state: CountdownState?
    private let storage = SharedFlightStorage()
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 8) {
            if let state {
                Text(state.currentPhase?.displayName ?? "—")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(countdown(from: state.remainingToNext))
                    .font(.title2.bold().monospacedDigit())
                CircularProgress(pct: state.pctElapsed, role: state.ownerRoles.first ?? .pilots)
                    .frame(width: 80, height: 80)
                Text(state.nextMilestone?.milestone.displayName ?? "—")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            } else {
                VStack(spacing: 4) {
                    Image(systemName: "airplane.departure")
                        .foregroundStyle(.secondary)
                    Text("No active flight")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .onAppear(perform: refresh)
        .onReceive(tick) { _ in
            now = Date()
            refresh()
        }
    }

    /// Recomputes the countdown state from the shared flight storage. Same "active flight"
    /// rule the widget and iOS app use — auto-advances past flights that are post-grace.
    private func refresh() {
        guard let flight = storage.activeFlight(now: now),
              let timeline = try? TimelineLoader().load(flight.category) else {
            state = nil
            return
        }
        let isCBP = (try? CBPResolver().isUSCBP(
            destinationIATA: flight.destination,
            on: flight.stdUTC,
            override: flight.isUSCBPOverride
        )) ?? false
        state = CountdownEngine().state(
            flight: flight, timeline: timeline, isUSCBP: isCBP, now: now
        )
    }

    private func countdown(from seconds: TimeInterval?) -> String {
        guard let s = seconds else { return "--:--" }
        let mins = Int(s) / 60
        let secs = Int(s) % 60
        return String(format: "%02d:%02d", max(mins, 0), max(secs, 0))
    }
}

private struct CircularProgress: View {
    let pct: Double
    let role: Role
    var body: some View {
        ZStack {
            Circle().stroke(.gray.opacity(0.2), lineWidth: 6)
            Circle()
                .trim(from: 0, to: pct)
                .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }

    private var color: Color {
        let rgb = Palette.approximate.color(for: role)
        return Color(red: rgb.red, green: rgb.green, blue: rgb.blue, opacity: rgb.alpha)
    }
}
