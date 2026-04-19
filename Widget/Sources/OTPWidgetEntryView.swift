import WidgetKit
import SwiftUI
import OTPKit

struct OTPWidgetEntryView: View {
    let entry: OTPWidgetEntry

    var body: some View {
        OTPRectangularContent(snapshot: entry.snapshot)
            .widgetURL(URL(string: "otpbb://next"))
    }
}
