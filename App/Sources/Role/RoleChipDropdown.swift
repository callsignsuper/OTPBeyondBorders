import SwiftUI
import OTPKit

struct RoleChipDropdown: View {
    @Binding var selection: Role

    var body: some View {
        Menu {
            ForEach(Role.allCases, id: \.self) { role in
                Button {
                    selection = role
                } label: {
                    Label(role.displayName, systemImage: selection == role ? "checkmark" : "")
                }
            }
        } label: {
            HStack(spacing: 6) {
                Circle().fill(Color.role(selection)).frame(width: 10, height: 10)
                Text(selection.displayName).font(.caption.bold())
                Image(systemName: "chevron.down").font(.caption2)
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(Color.role(selection).opacity(0.12), in: Capsule())
            .foregroundStyle(Color.role(selection))
        }
    }
}
