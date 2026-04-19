import SwiftUI
import OTPKit

@main
struct OTPBeyondBordersApp: App {
    @State private var store = FlightStore()
    @State private var alarms = AlarmScheduler()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("selectedRole") private var roleRaw = Role.pilots.rawValue
    @AppStorage("alarmsEnabled") private var alarmsEnabled = true
    @AppStorage("alarmLeadHome") private var alarmLeadHome = 90
    @AppStorage("alarmLeadOutstation") private var alarmLeadOutstation = 120
    @AppStorage("homeBaseIATA") private var homeBaseIATA = "AUH"

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    FlightListView()
                        .environment(store)
                        .environment(alarms)
                        .environment(\.selectedRole, Role(rawValue: roleRaw) ?? .pilots)
                } else {
                    OnboardingFlow(onFinish: { hasCompletedOnboarding = true })
                        .environment(store)
                }
            }
            .onAppear(perform: applyAlarmSettings)
            .onChange(of: store.flights) { _, newValue in
                Task { await alarms.reschedule(from: newValue) }
            }
            .onChange(of: alarmsEnabled) { _, _ in applyAlarmSettings() }
            .onChange(of: alarmLeadHome) { _, _ in applyAlarmSettings() }
            .onChange(of: alarmLeadOutstation) { _, _ in applyAlarmSettings() }
            .onChange(of: homeBaseIATA) { _, _ in applyAlarmSettings() }
        }
    }

    private func applyAlarmSettings() {
        alarms.enabled = alarmsEnabled
        alarms.homeBaseIATA = homeBaseIATA
        alarms.leadMinutesAtHomeBase = alarmLeadHome
        alarms.leadMinutesAtOutstation = alarmLeadOutstation
        Task { await alarms.reschedule(from: store.flights) }
    }
}

extension EnvironmentValues {
    @Entry var selectedRole: Role = .pilots
}
