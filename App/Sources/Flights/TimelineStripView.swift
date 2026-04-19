import SwiftUI
import OTPKit

struct TimelineStripView: View {
    let flight: Flight
    let timeline: Timeline
    let isCBP: Bool
    let now: Date
    let selectedRole: Role
    let onToggle: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Milestones")
                .font(.caption.uppercaseSmallCaps())
                .foregroundStyle(.secondary)
            ForEach(timeline.sortedMilestones(isUSCBP: isCBP)) { m in
                MilestoneRow(
                    milestone: m,
                    targetTime: m.targetTime(std: flight.stdUTC, isUSCBP: isCBP),
                    completed: flight.completedMilestones.contains(m.id),
                    isMine: m.owners.contains(selectedRole),
                    now: now,
                    onToggle: { onToggle(m.id) }
                )
            }
        }
    }
}

private struct MilestoneRow: View {
    let milestone: Milestone
    let targetTime: Date
    let completed: Bool
    let isMine: Bool
    let now: Date
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: completed ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(completed ? Color.otpTeal : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(milestone.displayName)
                    .font(.subheadline)
                    .strikethrough(completed)
                    .foregroundStyle(isMine ? Color.otpTeal : .primary)
                HStack(spacing: 6) {
                    ForEach(milestone.owners, id: \.self) { role in
                        Circle().fill(Color.role(role)).frame(width: 8, height: 8)
                    }
                    Text(targetTime.formatted(.dateTime.hour().minute()))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if !completed, targetTime > now {
                Text(relative(to: targetTime))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func relative(to date: Date) -> String {
        let remaining = Int(date.timeIntervalSince(now))
        guard remaining > 0 else { return "now" }
        let m = remaining / 60
        let s = remaining % 60
        if m >= 60 { return "\(m / 60)h \(m % 60)m" }
        return String(format: "%dm %02ds", m, s)
    }
}
