import WidgetKit
import OTPKit
import Foundation

struct OTPWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: OTPWidgetSnapshot
}

struct OTPWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> OTPWidgetEntry {
        OTPWidgetEntry(date: Date(), snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (OTPWidgetEntry) -> Void) {
        completion(OTPWidgetEntry(date: Date(), snapshot: demoFlightSnapshot(at: Date())))
    }

    func getTimeline(in context: Context, completion: @escaping (WidgetKit.Timeline<OTPWidgetEntry>) -> Void) {
        let now = Date()
        // One entry per minute for the next 90 minutes.
        let entries: [OTPWidgetEntry] = (0..<90).map { offset in
            let t = now.addingTimeInterval(Double(offset) * 60)
            return OTPWidgetEntry(date: t, snapshot: demoFlightSnapshot(at: t))
        }
        completion(WidgetKit.Timeline(entries: entries, policy: .atEnd))
    }

    private func demoFlightSnapshot(at date: Date) -> OTPWidgetSnapshot {
        // Until FlightStore sharing via App Groups is wired up, the widget renders a stable
        // demo flight so the lock-screen preview is meaningful. Replace with real store lookup
        // once the App Group entitlement lands.
        let flight = Flight(
            flightNumber: "EY21",
            sectorCode:   "21A",
            origin:       "AUH",
            destination:  "YYZ",
            reportingUTC: date.addingTimeInterval(-30 * 60),
            stdUTC:       date.addingTimeInterval(75 * 60),
            category:     .a380
        )
        return OTPWidgetSnapshot.build(for: flight, at: date)
    }
}
