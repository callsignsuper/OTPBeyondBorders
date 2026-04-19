import SwiftUI
import OTPKit

// MARK: - Step indicator

struct StepIndicator: View {
    let total: Int
    let current: Int
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index == current ? color : color.opacity(0.2))
                    .frame(width: index == current ? 22 : 6, height: 6)
                    .animation(.spring(duration: 0.35), value: current)
            }
        }
    }
}

// MARK: - Hero frame

struct HeroFrame<Content: View>: View {
    let accent: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [accent.opacity(0.18), accent.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            content()
        }
        .aspectRatio(1.1, contentMode: .fit)
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .strokeBorder(accent.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Primary CTA

struct PrimaryCTA: View {
    let title: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 52)
                .foregroundStyle(.white)
                .background(
                    LinearGradient(
                        colors: [tint, tint.opacity(0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .shadow(color: tint.opacity(0.3), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: title)
    }
}

// MARK: - Secondary CTA

struct SecondaryCTA: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Pane scaffold

struct OnboardingPane<Hero: View, Body: View, Footer: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder let hero: () -> Hero
    @ViewBuilder let bodyContent: () -> Body
    @ViewBuilder let footer: () -> Footer

    var body: some View {
        VStack(spacing: 24) {
            hero()
                .padding(.horizontal, 24)

            VStack(spacing: 10) {
                Text(title)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.otpNavy)
                    .multilineTextAlignment(.center)
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 32)

            bodyContent()
                .padding(.horizontal, 32)

            Spacer(minLength: 0)

            footer()
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
        }
    }
}

// MARK: - Animated backdrop

struct OnboardingBackdrop: View {
    let accent: Color

    var body: some View {
        ZStack {
            Color.otpCream
            RadialGradient(
                colors: [accent.opacity(0.22), .clear],
                center: .topLeading,
                startRadius: 20,
                endRadius: 400
            )
            RadialGradient(
                colors: [accent.opacity(0.12), .clear],
                center: .bottomTrailing,
                startRadius: 40,
                endRadius: 500
            )
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.6), value: accent)
    }
}
