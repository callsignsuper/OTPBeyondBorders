import SwiftUI
import OTPKit

struct RoleCarouselView: View {
    @Binding var selection: Role
    let advance: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Text("What's your role?")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.otpNavy)
                Text("Swipe to choose. We highlight the milestones your role owns.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            TabView(selection: $selection) {
                ForEach(Role.allCases, id: \.self) { role in
                    RoleCard(role: role).tag(role)
                        .padding(.horizontal, 24)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(maxHeight: 380)

            HStack(spacing: 8) {
                ForEach(Role.allCases, id: \.self) { role in
                    Capsule()
                        .fill(role == selection ? Color.role(role) : Color.gray.opacity(0.25))
                        .frame(width: role == selection ? 26 : 8, height: 8)
                        .animation(.spring(duration: 0.3), value: selection)
                }
            }

            Spacer(minLength: 0)

            PrimaryCTA(
                title: "Continue as \(selection.displayName)",
                tint: Color.role(selection),
                action: advance
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
        .sensoryFeedback(.selection, trigger: selection)
    }
}

private struct RoleCard: View {
    let role: Role

    var body: some View {
        VStack(spacing: 20) {
            RoleEmblem(role: role)
            VStack(spacing: 6) {
                Text(role.displayName)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.otpNavy)
                Text(role.roleSubtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            MilestoneTagCloud(role: role)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.role(role).opacity(0.16), Color.role(role).opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.role(role).opacity(0.25), lineWidth: 1)
        )
        .shadow(color: Color.role(role).opacity(0.12), radius: 14, y: 6)
    }
}

private struct RoleEmblem: View {
    let role: Role

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.role(role).opacity(0.12))
                .frame(width: 130, height: 130)
            Circle()
                .strokeBorder(Color.role(role), lineWidth: 3)
                .frame(width: 110, height: 110)
            Image(systemName: symbolName)
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(Color.role(role))
                .symbolRenderingMode(.hierarchical)
        }
    }

    private var symbolName: String {
        switch role {
        case .pilots:   return "airplane"
        case .cabin:    return "person.2.wave.2.fill"
        case .ground:   return "wrench.adjustable.fill"
        case .engineer: return "gearshape.2.fill"
        }
    }
}

private struct MilestoneTagCloud: View {
    let role: Role
    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(examples.prefix(3).enumerated()), id: \.offset) { _, tag in
                Text(tag)
                    .font(.caption2.weight(.medium))
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(
                        Capsule().fill(Color.role(role).opacity(0.15))
                    )
                    .foregroundStyle(Color.role(role))
            }
        }
    }

    private var examples: [String] {
        switch role {
        case .pilots:   return ["CBC briefing", "eATL", "Loadsheet"]
        case .cabin:    return ["Auto boarding", "Doors closed", "Briefing"]
        case .ground:   return ["Equipment", "GPU/ACU", "Tow truck"]
        case .engineer: return ["Pre-flight", "Release", "Handover"]
        }
    }
}
