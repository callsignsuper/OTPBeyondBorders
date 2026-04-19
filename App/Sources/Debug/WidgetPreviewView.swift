#if DEBUG
import SwiftUI
import OTPKit

/// Debug-only screen that renders the rectangular lock-screen widget at its native size,
/// against a dark backdrop that approximates a lock-screen context.
///
/// Lock-screen widget customization on a running Simulator is gated behind Face ID auth and
/// is unreliable to drive via automation — this preview gives the team a deterministic way
/// to inspect the widget's rendering in key states without touching the device chrome.
struct WidgetPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selected: PreviewState = .active

    enum PreviewState: String, CaseIterable, Identifiable {
        case active     = "In window"
        case approach   = "T−5"
        case delayed    = "Delay prompt"
        case placeholder = "Placeholder"
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Picker("State", selection: $selected) {
                        ForEach(PreviewState.allCases) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)

                    LockScreenFrame {
                        OTPRectangularContent(snapshot: snapshot)
                            .padding(.horizontal, 14).padding(.vertical, 10)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Render metadata")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                        DetailRow(label: "Family",  value: ".accessoryRectangular")
                        DetailRow(label: "Phase",   value: snapshot.phaseName)
                        DetailRow(label: "Owner",   value: snapshot.ownerRoles.map(\.displayName).joined(separator: ", "))
                        DetailRow(label: "Deep link", value: "otpbb://next")
                    }
                    .padding(14)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                }
                .padding()
            }
            .navigationTitle("Widget Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: dismiss.callAsFunction)
                }
            }
        }
    }

    private var snapshot: OTPWidgetSnapshot {
        let now = Date()
        switch selected {
        case .active:
            let flight = Flight(
                flightNumber: "EY21", sectorCode: "21A",
                origin: "AUH", destination: "YYZ",
                reportingUTC: now.addingTimeInterval(-30 * 60),
                stdUTC: now.addingTimeInterval(75 * 60),
                category: .a380
            )
            return .build(for: flight, at: now)
        case .approach:
            // At T-5:30: doors_closed target is 30s away, tow_truck same.
            let flight = Flight(
                flightNumber: "EY21", sectorCode: "21A",
                origin: "AUH", destination: "YYZ",
                reportingUTC: now.addingTimeInterval(-100 * 60),
                stdUTC: now.addingTimeInterval(5 * 60 + 30),
                category: .a380
            )
            return .build(for: flight, at: now)
        case .delayed:
            let flight = Flight(
                flightNumber: "EY21", sectorCode: "21A",
                origin: "AUH", destination: "YYZ",
                reportingUTC: now.addingTimeInterval(-110 * 60),
                stdUTC: now.addingTimeInterval(-5 * 60),
                category: .a380
            )
            return .build(for: flight, at: now)
        case .placeholder:
            return .placeholder
        }
    }
}

/// Visual approximation of a lock-screen: dark gradient with a white-tinted widget container
/// at accessoryRectangular dimensions (~172×76pt on @3x; we use 320×76pt scaled up so it is
/// readable on the phone sim without pretending to be a real lock screen).
private struct LockScreenFrame<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.otpNavy, Color.black, Color.otpNavy.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 24) {
                VStack(spacing: 2) {
                    Text(Date().formatted(.dateTime.weekday(.wide).day().month(.wide)))
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.75))
                    Text(Date().formatted(.dateTime.hour().minute()))
                        .font(.system(size: 64, weight: .thin))
                        .foregroundStyle(.white)
                }

                content()
                    .frame(width: 320, height: 76)
                    .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18).strokeBorder(.white.opacity(0.12))
                    )
                    .foregroundStyle(.white)
                    .preferredColorScheme(.dark)
            }
            .padding(.vertical, 28)
        }
        .frame(height: 320)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(.gray.opacity(0.3))
        )
    }
}

private struct DetailRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.footnote.monospaced())
        }
        .font(.footnote)
    }
}
#endif
