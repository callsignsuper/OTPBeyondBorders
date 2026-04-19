import SwiftUI
import OTPKit

struct SettingsView: View {
    @Environment(AlarmScheduler.self) private var alarms
    @AppStorage("notifyPerMilestone") private var notifyPerMilestone = false
    @AppStorage("hapticAtEATL") private var hapticAtEATL = true
    @AppStorage("languageOverride") private var languageOverride = ""
    @AppStorage("alarmsEnabled") private var alarmsEnabled = true
    @AppStorage("alarmLeadHome") private var alarmLeadHome = 90
    @AppStorage("alarmLeadOutstation") private var alarmLeadOutstation = 120
    @AppStorage("homeBaseIATA") private var homeBaseIATA = "AUH"

    var body: some View {
        Form {
            Section("Wake-up alarm") {
                Toggle("Enable wake-up alarms", isOn: $alarmsEnabled)
                if alarmsEnabled {
                    HStack {
                        Text("Home base")
                        Spacer()
                        TextField("IATA", text: $homeBaseIATA)
                            .multilineTextAlignment(.trailing)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.characters)
                            .frame(width: 80)
                    }
                    Stepper("\(alarmLeadHome) min before home-base departure",
                            value: $alarmLeadHome, in: 30...300, step: 15)
                    Stepper("\(alarmLeadOutstation) min before outstation departure",
                            value: $alarmLeadOutstation, in: 60...360, step: 15)
                    Text("We schedule one silent-friendly notification per upcoming flight. It respects your Focus / Do Not Disturb settings unless you allow critical alerts in iOS Settings.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Request notification permission again") {
                        Task { _ = await alarms.requestAuthorization() }
                    }
                }
            }

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
