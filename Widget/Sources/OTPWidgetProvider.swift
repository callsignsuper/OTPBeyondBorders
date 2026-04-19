import WidgetKit
import OTPKit
import Foundation

struct OTPWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: OTPWidgetSnapshot?
}

struct OTPWidgetProvider: TimelineProvider {
    private let storage = SharedFlightStorage()

    /// Widget gallery + transient loading state: render the empty-state view. We deliberately
    /// don't embed a fake sample flight here — users should never see a placeholder that looks
    /// like a real flight number they might act on.
    func placeholder(in context: Context) -> OTPWidgetEntry {
        OTPWidgetEntry(date: Date(), snapshot: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (OTPWidgetEntry) -> Void) {
        completion(OTPWidgetEntry(date: Date(), snapshot: currentSnapshot(at: Date())))
    }

    func getTimeline(in context: Context, completion: @escaping (WidgetKit.Timeline<OTPWidgetEntry>) -> Void) {
        let now = Date()
        // One entry per minute for the next 90 minutes. Ample granularity; WidgetKit will
        // request more when the window runs out.
        let entries: [OTPWidgetEntry] = (0..<90).map { offset in
            let t = now.addingTimeInterval(Double(offset) * 60)
            return OTPWidgetEntry(date: t, snapshot: currentSnapshot(at: t))
        }
        completion(WidgetKit.Timeline(entries: entries, policy: .atEnd))
    }

    /// Picks the first *active* flight from the App Group store. Active = STD in future OR
    /// STD within the grace window and doors_closed not marked. Returns nil when the store
    /// is empty or every flight is past the grace window — the widget view renders an empty
    /// state rather than inventing a demo flight.
    private func currentSnapshot(at date: Date) -> OTPWidgetSnapshot? {
        guard let flight = storage.activeFlight(now: date) else { return nil }
        return OTPWidgetSnapshot.build(for: flight, at: date)
    }
}
