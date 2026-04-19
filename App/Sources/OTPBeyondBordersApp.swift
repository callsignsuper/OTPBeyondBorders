import SwiftUI
import OTPKit

@main
struct OTPBeyondBordersApp: App {
    @State private var store = FlightStore()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("selectedRole") private var roleRaw = Role.pilots.rawValue

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                FlightListView()
                    .environment(store)
                    .environment(\.selectedRole, Role(rawValue: roleRaw) ?? .pilots)
            } else {
                OnboardingFlow(onFinish: { hasCompletedOnboarding = true })
                    .environment(store)
            }
        }
    }
}

extension EnvironmentValues {
    @Entry var selectedRole: Role = .pilots
}
