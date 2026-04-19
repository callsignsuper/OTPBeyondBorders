import WidgetKit
import SwiftUI
import OTPKit

struct OTPWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: OTPWidgetEntry

    var body: some View {
        Group {
            if let snapshot = entry.snapshot {
                switch family {
                case .accessoryRectangular:
                    OTPRectangularContent(snapshot: snapshot)
                case .systemSmall:
                    OTPSmallContent(snapshot: snapshot)
                case .systemMedium:
                    OTPMediumContent(snapshot: snapshot)
                default:
                    OTPRectangularContent(snapshot: snapshot)
                }
            } else {
                OTPEmptyContent(family: family)
            }
        }
        .widgetURL(URL(string: "otpbb://next"))
    }
}

/// Rendered when the App Group store has no active flight. Encourages the user to import
/// or add one; never invents a fake flight.
struct OTPEmptyContent: View {
    let family: WidgetFamily

    var body: some View {
        switch family {
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text("OTP Beyond Borders")
                    .font(.caption2.weight(.semibold))
                Text("No upcoming flight")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("Import from your rostering app")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        case .systemSmall:
            VStack(spacing: 8) {
                Image(systemName: "airplane.departure")
                    .font(.title)
                    .foregroundStyle(.secondary)
                Text("No upcoming flight")
                    .font(.caption.weight(.semibold))
                    .multilineTextAlignment(.center)
                Text("Import from your rostering app")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(14)
        default:
            HStack(spacing: 14) {
                Image(systemName: "airplane.departure")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 4) {
                    Text("No upcoming flight")
                        .font(.headline)
                    Text("Import your roster from Calendar to start the countdown.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(18)
        }
    }
}
