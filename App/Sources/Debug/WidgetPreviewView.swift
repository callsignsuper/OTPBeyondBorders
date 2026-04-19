#if DEBUG
import SwiftUI
import OTPKit

/// Debug-only screen that renders every supported widget family at its native size, against
/// a mock home-screen or lock-screen backdrop, using either synthetic or real shared-storage data.
///
/// The iOS simulator's widget gallery is historically flaky to drive via automation — this
/// preview gives the team a deterministic way to inspect the widget's rendering in every
/// supported family and state without touching the device chrome.
struct WidgetPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedState: PreviewState = .sharedStorage
    @State private var selectedFamily: Family = .systemMedium

    enum PreviewState: String, CaseIterable, Identifiable {
        case sharedStorage = "Real flight"
        case inWindow      = "In window"
        case approach      = "T−5"
        case delayed       = "Delay prompt"
        case placeholder   = "Placeholder"
        var id: String { rawValue }
    }

    enum Family: String, CaseIterable, Identifiable {
        case accessoryRectangular = "Lock"
        case systemSmall          = "Small"
        case systemMedium         = "Medium"
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Picker("Data", selection: $selectedState) {
                        ForEach(PreviewState.allCases) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("Family", selection: $selectedFamily) {
                        ForEach(Family.allCases) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)

                    widgetFrame

                    metadataPanel
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

    @ViewBuilder
    private var widgetFrame: some View {
        switch selectedFamily {
        case .accessoryRectangular:
            LockScreenFrame {
                OTPRectangularContent(snapshot: snapshot)
                    .padding(.horizontal, 14).padding(.vertical, 10)
            }
        case .systemSmall:
            HomeScreenFrame(size: CGSize(width: 170, height: 170)) {
                OTPSmallContent(snapshot: snapshot)
            }
        case .systemMedium:
            HomeScreenFrame(size: CGSize(width: 360, height: 170)) {
                OTPMediumContent(snapshot: snapshot)
            }
        }
    }

    private var metadataPanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Render metadata")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            DetailRow(label: "Family",      value: familyIdentifier)
            DetailRow(label: "Flight",      value: "\(snapshot.flightNumber) \(snapshot.routeLabel)")
            DetailRow(label: "Aircraft",    value: snapshot.aircraftLabel)
            DetailRow(label: "Phase",       value: snapshot.phaseName)
            DetailRow(label: "Next",        value: snapshot.nextMilestoneLabel)
            DetailRow(label: "Owner",       value: snapshot.ownerRoles.map(\.displayName).joined(separator: ", "))
            DetailRow(label: "Progress",    value: "\(Int(snapshot.progressPct * 100))%")
            DetailRow(label: "Deep link",   value: "otpbb://next")
            DetailRow(label: "Source",      value: snapshotSource)
        }
        .padding(14)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private var familyIdentifier: String {
        switch selectedFamily {
        case .accessoryRectangular: return ".accessoryRectangular"
        case .systemSmall:          return ".systemSmall"
        case .systemMedium:         return ".systemMedium"
        }
    }

    private var snapshotSource: String {
        switch selectedState {
        case .sharedStorage: return "App Group / SharedFlightStorage"
        default:             return "synthetic fixture"
        }
    }

    private var snapshot: OTPWidgetSnapshot {
        let now = Date()
        switch selectedState {
        case .sharedStorage:
            if let flight = SharedFlightStorage().activeFlight(now: now) {
                return .build(for: flight, at: now)
            }
            return .placeholder
        case .inWindow:
            let flight = Flight(
                flightNumber: "EY21", sectorCode: "21A",
                origin: "AUH", destination: "YYZ",
                reportingUTC: now.addingTimeInterval(-30 * 60),
                stdUTC: now.addingTimeInterval(75 * 60),
                category: .a380
            )
            return .build(for: flight, at: now)
        case .approach:
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

/// Visual approximation of a lock-screen with a rectangular-accessory-sized slot.
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

/// Home-screen-style widget container at a given size. Matches the iOS home screen widget
/// corner radius + subtle shadow so the debug preview reads like a real home-screen tile.
private struct HomeScreenFrame<Content: View>: View {
    let size: CGSize
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            // Mock wallpaper
            LinearGradient(
                colors: [
                    Color(red: 0.36, green: 0.52, blue: 0.78),
                    Color(red: 0.21, green: 0.28, blue: 0.42)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            content()
                .frame(width: size.width, height: size.height)
                .background(
                    LinearGradient(
                        colors: [Color.otpCream, Color.otpCream.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                )
                .shadow(color: .black.opacity(0.2), radius: 14, y: 6)
        }
        .frame(height: 260)
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
            Text(value).font(.footnote.monospaced()).multilineTextAlignment(.trailing)
        }
        .font(.footnote)
    }
}
#endif
