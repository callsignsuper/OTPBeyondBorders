import SwiftUI
import OTPKit

struct OnboardingFlow: View {
    let onFinish: () -> Void

    @State private var step: Step = .welcome
    @AppStorage("selectedRole") private var roleRaw = Role.pilots.rawValue

    enum Step: Int, CaseIterable {
        case welcome, role, calendar, notifications, done
    }

    private var selectedRole: Role { Role(rawValue: roleRaw) ?? .pilots }
    private var roleBinding: Binding<Role> {
        Binding(get: { selectedRole }, set: { roleRaw = $0.rawValue })
    }

    private var backdropAccent: Color {
        switch step {
        case .welcome:       return Color.otpGold
        case .role:          return Color.role(selectedRole)
        case .calendar:      return Color.otpTeal
        case .notifications: return Color.otpTerracotta
        case .done:          return Color.otpGold
        }
    }

    var body: some View {
        ZStack {
            OnboardingBackdrop(accent: backdropAccent)

            VStack(spacing: 16) {
                topBar
                paneContent
            }
        }
    }

    private var topBar: some View {
        HStack {
            StepIndicator(total: Step.allCases.count, current: step.rawValue, color: backdropAccent)
            Spacer()
            if step == .calendar || step == .notifications {
                Button("Skip") { advance() }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    @ViewBuilder
    private var paneContent: some View {
        Group {
            switch step {
            case .welcome:
                WelcomePane(advance: advance)
            case .role:
                RoleCarouselView(selection: roleBinding, advance: advance)
            case .calendar:
                CalendarPermissionPane(advance: advance)
            case .notifications:
                NotificationsPermissionPane(advance: advance)
            case .done:
                DonePane(finish: onFinish)
            }
        }
        .transition(
            .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        )
        .id(step)
    }

    private func advance() {
        let next = Step(rawValue: step.rawValue + 1) ?? .done
        withAnimation(.spring(duration: 0.45)) { step = next }
    }
}

// MARK: - Welcome

private struct WelcomePane: View {
    let advance: () -> Void
    @State private var logoPhase: CGFloat = 0

    var body: some View {
        OnboardingPane(
            title: "OTP Beyond Borders",
            subtitle: "For airline crew",
            hero: {
                HeroFrame(accent: Color.otpGold) {
                    ZStack {
                        Circle()
                            .strokeBorder(Color.otpGold.opacity(0.3), lineWidth: 2)
                            .frame(width: 220, height: 220)
                            .scaleEffect(1 + 0.04 * logoPhase)
                        Circle()
                            .strokeBorder(Color.otpTeal.opacity(0.5), lineWidth: 3)
                            .frame(width: 160, height: 160)
                        Image(systemName: "airplane")
                            .font(.system(size: 58, weight: .semibold))
                            .foregroundStyle(Color.otpNavy)
                            .rotationEffect(.degrees(-18))
                    }
                    .onAppear {
                        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                            logoPhase = 1
                        }
                    }
                }
            },
            bodyContent: {
                Text("Know exactly where you are in the turnaround — on your lock screen, on your wrist, at a glance.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            },
            footer: {
                PrimaryCTA(title: "Get Started", tint: Color.otpGold, action: advance)
            }
        )
    }
}

// MARK: - Calendar

private struct CalendarPermissionPane: View {
    let advance: () -> Void
    @State private var requesting = false

    var body: some View {
        OnboardingPane(
            title: "Connect your roster",
            subtitle: "We read flight events exported by your rostering app",
            hero: {
                HeroFrame(accent: Color.otpTeal) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.white)
                            .frame(width: 180, height: 180)
                            .overlay(
                                VStack(spacing: 6) {
                                    HStack(spacing: 4) {
                                        ForEach(0..<5, id: \.self) { _ in
                                            Circle().fill(Color.otpTeal.opacity(0.15)).frame(width: 18, height: 18)
                                        }
                                    }
                                    HStack(spacing: 4) {
                                        ForEach(0..<5, id: \.self) { i in
                                            Circle()
                                                .fill(i == 2 ? Color.otpTeal : Color.otpTeal.opacity(0.15))
                                                .frame(width: 18, height: 18)
                                        }
                                    }
                                    HStack(spacing: 4) {
                                        ForEach(0..<5, id: \.self) { _ in
                                            Circle().fill(Color.otpTeal.opacity(0.15)).frame(width: 18, height: 18)
                                        }
                                    }
                                }
                            )
                            .shadow(color: Color.otpTeal.opacity(0.15), radius: 20, y: 8)
                        Image(systemName: "airplane")
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(Color.otpGold)
                            .rotationEffect(.degrees(-18))
                            .offset(x: 78, y: -72)
                    }
                }
            },
            bodyContent: {
                VStack(alignment: .leading, spacing: 12) {
                    StepRow(number: "1", text: "In your rostering or crew-control app, enable Settings → Export to Calendar.")
                    StepRow(number: "2", text: "Grant calendar access here so we can read those events.")
                    StepRow(number: "3", text: "We only import events tagged by your rostering app — nothing else.")
                }
            },
            footer: {
                VStack(spacing: 8) {
                    PrimaryCTA(
                        title: requesting ? "Requesting…" : "Grant calendar access",
                        tint: Color.otpTeal,
                        action: grantAccess
                    )
                    SecondaryCTA(title: "I'll do this later", action: advance)
                }
            }
        )
    }

    private func grantAccess() {
        requesting = true
        Task {
            _ = try? await CalendarImporter().requestAccess()
            requesting = false
            advance()
        }
    }
}

private struct StepRow: View {
    let number: String
    let text: String
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(number)
                .font(.callout.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(Circle().fill(Color.otpTeal))
            Text(text)
                .font(.callout)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Notifications

private struct NotificationsPermissionPane: View {
    let advance: () -> Void
    @State private var requesting = false

    var body: some View {
        OnboardingPane(
            title: "Wake up on time",
            subtitle: "One alarm per flight, scheduled automatically",
            hero: {
                HeroFrame(accent: Color.otpTerracotta) {
                    ZStack {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .strokeBorder(Color.otpTerracotta.opacity(0.5 - Double(index) * 0.15), lineWidth: 2)
                                .frame(
                                    width: 120 + CGFloat(index) * 50,
                                    height: 120 + CGFloat(index) * 50
                                )
                        }
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 52, weight: .semibold))
                            .foregroundStyle(Color.otpTerracotta)
                    }
                }
            },
            bodyContent: {
                VStack(alignment: .leading, spacing: 10) {
                    BulletRow(icon: "alarm", text: "90 min before home-base departures, 2 h before outstation departures. Both adjustable.")
                    BulletRow(icon: "waveform", text: "Optional haptic at eATL (T−15).")
                    BulletRow(icon: "bell.slash", text: "Respects Focus / Do Not Disturb. Widgets always update silently.")
                }
            },
            footer: {
                VStack(spacing: 8) {
                    PrimaryCTA(
                        title: requesting ? "Requesting…" : "Allow notifications",
                        tint: Color.otpTerracotta
                    ) {
                        requesting = true
                        Task {
                            _ = await AlarmScheduler().requestAuthorization()
                            requesting = false
                            advance()
                        }
                    }
                    SecondaryCTA(title: "Skip", action: advance)
                }
            }
        )
    }
}

private struct BulletRow: View {
    let icon: String
    let text: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundStyle(Color.otpTerracotta)
                .frame(width: 28)
            Text(text).font(.callout)
            Spacer()
        }
    }
}

// MARK: - Done

private struct DonePane: View {
    let finish: () -> Void
    @State private var checkScale: CGFloat = 0.6

    var body: some View {
        OnboardingPane(
            title: "You're ready",
            subtitle: "Add the widget and complication so the countdown follows you",
            hero: {
                HeroFrame(accent: Color.otpGold) {
                    ZStack {
                        Circle()
                            .fill(Color.otpGold.opacity(0.18))
                            .frame(width: 180, height: 180)
                        Circle()
                            .fill(Color.otpGold)
                            .frame(width: 120, height: 120)
                        Image(systemName: "checkmark")
                            .font(.system(size: 56, weight: .heavy))
                            .foregroundStyle(.white)
                            .scaleEffect(checkScale)
                            .onAppear {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) {
                                    checkScale = 1.0
                                }
                            }
                    }
                }
            },
            bodyContent: {
                VStack(alignment: .leading, spacing: 10) {
                    BulletRow(icon: "rectangle.on.rectangle", text: "Long-press your lock screen → Customize → add OTP Countdown.")
                    BulletRow(icon: "applewatch", text: "On Apple Watch, edit a face → add the OTP Countdown complication.")
                }
            },
            footer: {
                PrimaryCTA(title: "Start", tint: Color.otpGold, action: finish)
            }
        )
    }
}
