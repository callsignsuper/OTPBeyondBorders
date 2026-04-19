import SwiftUI
import OTPKit

struct OnboardingFlow: View {
    let onFinish: () -> Void

    @State private var step: Step = .welcome
    @AppStorage("selectedRole") private var roleRaw = Role.pilots.rawValue

    enum Step: Int, CaseIterable { case welcome, role, calendar, notifications, done }

    var body: some View {
        ZStack {
            Color.otpCream.ignoresSafeArea()
            VStack {
                switch step {
                case .welcome:       WelcomePane(advance: advance)
                case .role:          RoleCarouselView(selection: Binding(
                                        get: { Role(rawValue: roleRaw) ?? .pilots },
                                        set: { roleRaw = $0.rawValue }
                                     ), advance: advance)
                case .calendar:      CalendarPermissionPane(advance: advance)
                case .notifications: NotificationsPermissionPane(advance: advance)
                case .done:          DonePane(finish: onFinish)
                }
            }
            .padding()
        }
    }

    private func advance() {
        let next = Step(rawValue: step.rawValue + 1) ?? .done
        withAnimation { step = next }
    }
}

private struct WelcomePane: View {
    let advance: () -> Void
    var body: some View {
        VStack(spacing: 24) {
            Text("OTP Beyond Borders")
                .font(.largeTitle).bold()
                .foregroundStyle(Color.otpTeal)
            Text("Know exactly where you are in the turnaround — on your lock screen, on your wrist, at a glance.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Get Started", action: advance)
                .buttonStyle(.borderedProminent)
                .tint(Color.otpGold)
        }
    }
}

private struct CalendarPermissionPane: View {
    let advance: () -> Void
    var body: some View {
        VStack(spacing: 16) {
            Text("Connect your roster").font(.title2).bold()
            Text("Enable AIMS eCrew → Settings → Export to Calendar, then grant calendar access here. We only read events tagged by AIMS.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Grant calendar access") {
                Task {
                    _ = try? await CalendarImporter().requestAccess()
                    advance()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.otpTeal)
            Button("Skip for now", action: advance).buttonStyle(.plain)
        }
    }
}

private struct NotificationsPermissionPane: View {
    let advance: () -> Void
    var body: some View {
        VStack(spacing: 16) {
            Text("Quiet by default").font(.title2).bold()
            Text("Silent widget updates only. One optional haptic at eATL (T−15). Toggle per-milestone alerts later in Settings.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Continue", action: advance)
                .buttonStyle(.borderedProminent)
                .tint(Color.otpTeal)
        }
    }
}

private struct DonePane: View {
    let finish: () -> Void
    var body: some View {
        VStack(spacing: 16) {
            Text("You're ready").font(.title2).bold()
            Text("Add the rectangular widget to your lock screen and the complication to your watch face.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Done", action: finish)
                .buttonStyle(.borderedProminent)
                .tint(Color.otpGold)
        }
    }
}
