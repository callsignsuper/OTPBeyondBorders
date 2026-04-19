import WidgetKit
import SwiftUI
import OTPKit

struct OTPWidget: Widget {
    let kind: String = "OTPWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: OTPWidgetProvider()) { entry in
            OTPWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("OTP Countdown")
        .description("Next OTP milestone on your lock screen.")
        .supportedFamilies([.accessoryRectangular])
    }
}
