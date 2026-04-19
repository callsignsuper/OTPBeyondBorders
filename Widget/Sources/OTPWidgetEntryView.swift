import WidgetKit
import SwiftUI
import OTPKit

struct OTPWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: OTPWidgetEntry

    var body: some View {
        Group {
            switch family {
            case .accessoryRectangular:
                OTPRectangularContent(snapshot: entry.snapshot)
            case .systemSmall:
                OTPSmallContent(snapshot: entry.snapshot)
            case .systemMedium:
                OTPMediumContent(snapshot: entry.snapshot)
            default:
                OTPRectangularContent(snapshot: entry.snapshot)
            }
        }
        .widgetURL(URL(string: "otpbb://next"))
    }
}
