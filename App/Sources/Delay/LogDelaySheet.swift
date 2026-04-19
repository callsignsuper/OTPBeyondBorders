import SwiftUI
import OTPKit

struct LogDelaySheet: View {
    let flightID: String
    @Environment(FlightStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var minutes: Int = 5
    @State private var selectedCode: DelayCodeCatalog.Code?
    @State private var freeText: String = ""
    @State private var catalog: DelayCodeCatalog?

    var body: some View {
        NavigationStack {
            Form {
                Section("Delay") {
                    Stepper("\(minutes) minutes", value: $minutes, in: 1...240, step: 5)
                }
                Section("IATA code") {
                    if let catalog {
                        ForEach(catalog.groups, id: \.range) { group in
                            DisclosureGroup(group.label) {
                                ForEach(group.codes) { code in
                                    Button {
                                        selectedCode = code
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text("\(code.code) — \(code.name)")
                                                if !code.description.isEmpty {
                                                    Text(code.description)
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                }
                                            }
                                            Spacer()
                                            if selectedCode?.code == code.code {
                                                Image(systemName: "checkmark")
                                                    .foregroundStyle(Color.otpTeal)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                if selectedCode?.code == "99" {
                    Section("Free text") {
                        TextField("Reason", text: $freeText, axis: .vertical)
                    }
                }
            }
            .navigationTitle("Log delay")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel", action: dismiss.callAsFunction) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).disabled(selectedCode == nil)
                }
            }
            .task {
                catalog = try? DelayCodeLoader().load()
            }
        }
    }

    private func save() {
        guard let code = selectedCode else { return }
        let log = DelayLog(
            minutesDelayed: minutes,
            iataCode: code.code,
            freeText: freeText.isEmpty ? nil : freeText,
            loggedAt: Date()
        )
        store.logDelay(log, on: flightID)
        dismiss()
    }
}
