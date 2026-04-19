import WidgetKit
import SwiftUI
import OTPKit

struct OTPWidgetEntryView: View {
    let entry: OTPWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.snapshot.flightHeader)
                .font(.caption2.monospacedDigit())
                .lineLimit(1)
            Text(entry.snapshot.phaseName)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            if entry.snapshot.isDelayPrompt {
                Text("Log delay")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.red)
            } else {
                Text(entry.snapshot.countdownText)
                    .font(.title3.bold().monospacedDigit())
            }
            ProgressView(value: entry.snapshot.progressPct)
                .tint(ownerColor)
            Text(entry.snapshot.nextMilestoneLabel)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .widgetURL(URL(string: "otpbb://next"))
    }

    private var ownerColor: Color {
        guard let role = entry.snapshot.ownerRoles.first else { return .accentColor }
        let rgb = Palette.approximate.color(for: role)
        return Color(red: rgb.red, green: rgb.green, blue: rgb.blue, opacity: rgb.alpha)
    }
}
