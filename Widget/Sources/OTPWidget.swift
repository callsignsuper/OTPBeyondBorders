import WidgetKit
import SwiftUI
import OTPKit

struct OTPWidget: Widget {
    let kind: String = "OTPWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: OTPWidgetProvider()) { entry in
            OTPWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    BackgroundForFamily()
                }
        }
        .configurationDisplayName("OTP Countdown")
        .description("Next OTP milestone for your upcoming Etihad flight.")
        .supportedFamilies([
            .accessoryRectangular,  // lock screen
            .systemSmall,           // home screen 2×2
            .systemMedium           // home screen 4×2
        ])
    }
}

private struct BackgroundForFamily: View {
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryRectangular:
            // Lock screen uses iOS's system tint; keep the background minimal.
            Color.clear
        default:
            LinearGradient(
                colors: [Color(red: 0.97, green: 0.95, blue: 0.91),
                         Color(red: 0.90, green: 0.86, blue: 0.78)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
