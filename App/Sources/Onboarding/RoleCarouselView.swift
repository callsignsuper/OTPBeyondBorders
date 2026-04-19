import SwiftUI
import OTPKit

struct RoleCarouselView: View {
    @Binding var selection: Role
    let advance: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("What's your role?")
                .font(.title2).bold()
                .foregroundStyle(Color.otpTeal)
            Text("Timeline milestones owned by your role are highlighted. You can change this later.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            TabView(selection: $selection) {
                ForEach(Role.allCases, id: \.self) { role in
                    RoleCard(role: role).tag(role)
                }
            }
            .tabViewStyle(.page)
            .frame(height: 280)

            Button("Continue as \(selection.displayName)", action: advance)
                .buttonStyle(.borderedProminent)
                .tint(Color.role(selection))
        }
    }
}

private struct RoleCard: View {
    let role: Role
    var body: some View {
        VStack(spacing: 12) {
            Circle()
                .strokeBorder(Color.role(role), lineWidth: 6)
                .background(Circle().fill(.white))
                .frame(width: 120, height: 120)
                .overlay(
                    Image(systemName: symbolName)
                        .font(.system(size: 48))
                        .foregroundStyle(Color.role(role))
                )
            Text(role.displayName)
                .font(.title3).bold()
                .foregroundStyle(Color.role(role))
        }
    }

    private var symbolName: String {
        switch role {
        case .pilots:   return "airplane"
        case .cabin:    return "person.fill"
        case .ground:   return "wrench.and.screwdriver.fill"
        case .engineer: return "gearshape.2.fill"
        }
    }
}
