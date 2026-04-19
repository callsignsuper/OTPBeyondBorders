import WidgetKit
import OTPKit
import Foundation

struct OTPWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: OTPWidgetSnapshot
}

struct OTPWidgetProvider: TimelineProvider {
    private let storage = SharedFlightStorage()

    func placeholder(in context: Context) -> OTPWidgetEntry {
        OTPWidgetEntry(date: Date(), snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (OTPWidgetEntry) -> Void) {
        completion(OTPWidgetEntry(date: Date(), snapshot: snapshot(at: Date())))
    }

    func getTimeline(in context: Context, completion: @escaping (WidgetKit.Timeline<OTPWidgetEntry>) -> Void) {
        let now = Date()
        // One entry per minute for the next 90 minutes. Ample granularity; WidgetKit will request
        // more when the window runs out.
        let entries: [OTPWidgetEntry] = (0..<90).map { offset in
            let t = now.addingTimeInterval(Double(offset) * 60)
            return OTPWidgetEntry(date: t, snapshot: snapshot(at: t))
        }
        completion(WidgetKit.Timeline(entries: entries, policy: .atEnd))
    }

    /// Prefer the real next flight from the App Group store. Falls back to a stable demo snapshot
    /// whenever no flight is available (first run, missing entitlement, etc.) so the widget always
    /// has something legible to render.
    private func snapshot(at date: Date) -> OTPWidgetSnapshot {
        if let flight = storage.nextFlight(now: date) {
            return OTPWidgetSnapshot.build(for: flight, at: date)
        }
        let demo = Flight(
            flightNumber: "EY21",
            sectorCode: "21A",
            origin: "AUH",
            destination: "YYZ",
            reportingUTC: date.addingTimeInterval(-30 * 60),
            stdUTC: date.addingTimeInterval(75 * 60),
            category: .a380
        )
        return OTPWidgetSnapshot.build(for: demo, at: date)
    }
}
