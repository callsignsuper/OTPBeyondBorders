import Foundation
@testable import OTPKit

enum TestSupport {
    static let utcCal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return c
    }()

    static func utc(_ y: Int, _ mo: Int, _ d: Int, _ h: Int = 0, _ mi: Int = 0) -> Date {
        let components = DateComponents(
            calendar: utcCal, timeZone: TimeZone(identifier: "UTC"),
            year: y, month: mo, day: d, hour: h, minute: mi, second: 0
        )
        guard let date = components.date else {
            fatalError("Failed to build UTC date \(y)-\(mo)-\(d) \(h):\(mi)")
        }
        return date
    }

    /// Sample flight — EY21 AUH→YYZ A380 on 2026-04-20; STD 22:20Z, report 20:35Z.
    /// Matches the canonical example in docs/aims-ecrew-calendar-parse.md.
    static func sampleA380Flight() -> Flight {
        Flight(
            flightNumber: "EY21",
            sectorCode:   "21A",
            origin:       "AUH",
            destination:  "YYZ",
            reportingUTC: utc(2026, 4, 20, 20, 35),
            stdUTC:       utc(2026, 4, 20, 22, 20),
            staUTC:       utc(2026, 4, 21, 13, 45),
            category:     .a380
        )
    }
}
