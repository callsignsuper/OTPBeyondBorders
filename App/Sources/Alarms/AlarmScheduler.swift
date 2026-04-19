import Foundation
import Observation
import UserNotifications
import OTPKit

/// Schedules local "wake-up" notifications before each upcoming flight.
///
/// The lead time depends on whether the flight departs from the crew's home base (default AUH)
/// or from an outstation — outstations default to a longer pre-flight window.
@MainActor
@Observable
final class AlarmScheduler {
    private let center: UNUserNotificationCenter
    private let idPrefix = "otpbb.alarm."

    var enabled: Bool
    var homeBaseIATA: String
    var leadMinutesAtHomeBase: Int
    var leadMinutesAtOutstation: Int

    init(
        enabled: Bool = true,
        homeBaseIATA: String = "AUH",
        leadMinutesAtHomeBase: Int = 90,
        leadMinutesAtOutstation: Int = 120,
        center: UNUserNotificationCenter = .current()
    ) {
        self.enabled = enabled
        self.homeBaseIATA = homeBaseIATA
        self.leadMinutesAtHomeBase = leadMinutesAtHomeBase
        self.leadMinutesAtOutstation = leadMinutesAtOutstation
        self.center = center
    }

    /// Ask for permission. Call once during onboarding (or first enabling).
    @discardableResult
    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    /// Replace all previously scheduled OTP alarms with alarms for the given flights.
    /// Call after every flight import / mutation.
    func reschedule(from flights: [Flight], now: Date = Date()) async {
        await cancelAll()
        guard enabled else { return }

        for flight in flights {
            guard let fireDate = fireDate(for: flight, now: now) else { continue }
            schedule(flight: flight, fireDate: fireDate)
        }
    }

    func cancelAll() async {
        let pending = await center.pendingNotificationRequests()
        let mine = pending.map(\.identifier).filter { $0.hasPrefix(idPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: mine)
    }

    // MARK: - Internals

    private func fireDate(for flight: Flight, now: Date) -> Date? {
        let lead = leadMinutes(for: flight)
        let fire = flight.stdUTC.addingTimeInterval(TimeInterval(-lead * 60))
        guard fire > now else { return nil } // don't schedule past alarms
        return fire
    }

    private func leadMinutes(for flight: Flight) -> Int {
        // Crew at home base gets the shorter lead; away from home (outstation) gets the longer one.
        flight.origin.uppercased() == homeBaseIATA.uppercased()
            ? leadMinutesAtHomeBase
            : leadMinutesAtOutstation
    }

    private func schedule(flight: Flight, fireDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Wake up for flight \(flight.flightNumber)"
        content.body = "\(flight.origin) → \(flight.destination) · STD in \(prettyLead(flight: flight))"
        content.sound = .default
        content.categoryIdentifier = "OTPBB_ALARM"

        let comps = Calendar(identifier: .gregorian)
            .dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(
            identifier: identifier(for: flight),
            content: content,
            trigger: trigger
        )

        Task { try? await center.add(request) }
    }

    private func identifier(for flight: Flight) -> String {
        "\(idPrefix)\(flight.flightNumber)@\(Int(flight.stdUTC.timeIntervalSince1970))"
    }

    private func prettyLead(flight: Flight) -> String {
        let lead = leadMinutes(for: flight)
        if lead % 60 == 0 { return "\(lead / 60)h" }
        return "\(lead / 60)h\(lead % 60)m"
    }
}
