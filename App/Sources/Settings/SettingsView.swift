import SwiftUI
import OTPKit

struct SettingsView: View {
    @AppStorage("notifyPerMilestone") private var notifyPerMilestone = false
    @AppStorage("hapticAtEATL") private var hapticAtEATL = true
    @AppStorage("languageOverride") private var languageOverride = ""

    var body: some View {
        Form {
            Section("Notifications") {
                Toggle("Haptic at T−15 (eATL)", isOn: $hapticAtEATL)
                Toggle("Alert on every milestone", isOn: $notifyPerMilestone)
            }
            Section("Language") {
                Picker("Display language", selection: $languageOverride) {
                    Text("System default").tag("")
                    Text("English").tag("en")
                    Text("العربية").tag("ar")
                    Text("Русский").tag("ru")
                    Text("Italiano").tag("it")
                    Text("Português").tag("pt")
                }
            }
        }
        .navigationTitle("Settings")
    }
}
