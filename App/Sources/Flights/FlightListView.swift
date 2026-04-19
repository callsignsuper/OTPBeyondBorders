import SwiftUI
import OTPKit
#if canImport(WidgetKit)
import WidgetKit
#endif

struct FlightListView: View {
    @Environment(FlightStore.self) private var store
    @Environment(\.selectedRole) private var selectedRole
    @State private var isImporting = false
    @State private var showingWidgetPreview = false
    @State private var seedResult: String?
    @AppStorage("selectedRole") private var roleRaw = Role.pilots.rawValue

    var body: some View {
        NavigationStack {
            ZStack {
                Color.otpCream.ignoresSafeArea()
                List {
                    if store.flights.isEmpty {
                        EmptyFlightsHint()
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(store.flights.sorted(by: { $0.stdUTC < $1.stdUTC })) { flight in
                            NavigationLink(value: flight.id) {
                                FlightRow(flight: flight)
                            }
                            .listRowBackground(Color.white)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Flights")
            .navigationDestination(for: String.self) { id in
                if let flight = store.flights.first(where: { $0.id == id }) {
                    FlightDetailView(flight: flight)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    RoleChipDropdown(
                        selection: Binding(
                            get: { Role(rawValue: roleRaw) ?? .pilots },
                            set: { roleRaw = $0.rawValue }
                        )
                    )
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await importFlights() }
                    } label: {
                        if isImporting {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                    }
                }
                #if DEBUG
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingWidgetPreview = true
                    } label: {
                        Image(systemName: "rectangle.on.rectangle")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await seedTestFlight() }
                    } label: {
                        Image(systemName: "calendar.badge.plus")
                    }
                }
                #endif
            }
            #if DEBUG
            .sheet(isPresented: $showingWidgetPreview) {
                WidgetPreviewView()
            }
            .alert("Test flight", isPresented: Binding(
                get: { seedResult != nil },
                set: { if !$0 { seedResult = nil } }
            )) {
                Button("OK") { seedResult = nil }
            } message: {
                Text(seedResult ?? "")
            }
            #endif
        }
    }

    private func importFlights() async {
        isImporting = true
        defer { isImporting = false }
        let importer = CalendarImporter()
        guard (try? await importer.requestAccess()) == true else { return }
        let range = DateInterval(start: Date().addingTimeInterval(-86_400),
                                 end: Date().addingTimeInterval(45 * 86_400))
        for flight in importer.importFlights(in: range) {
            store.upsert(flight)
        }
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    #if DEBUG
    private func seedTestFlight() async {
        do {
            let std = try await CalendarSeeder().seed(hoursFromNow: 2)
            await importFlights()
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            seedResult = "Flight EY21 seeded — STD at \(formatter.string(from: std)) local. Widget timeline refreshed."
        } catch {
            seedResult = "Seed failed: \(error)"
        }
    }
    #endif
}

private struct FlightRow: View {
    let flight: Flight
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(flight.flightNumber).bold()
                    RouteLabel(origin: flight.origin, destination: flight.destination,
                               font: .headline)
                }
                Text(flight.stdUTC.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(flight.category.shortLabel)
                .font(.caption.bold())
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color.otpTeal.opacity(0.15), in: Capsule())
                .foregroundStyle(Color.otpTeal)
        }
    }
}

private struct EmptyFlightsHint: View {
    var body: some View {
        ContentUnavailableView(
            "No flights yet",
            systemImage: "calendar.badge.plus",
            description: Text("Tap the refresh icon to import from your rostering app via Calendar.")
        )
    }
}
