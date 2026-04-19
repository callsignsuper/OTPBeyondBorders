import Foundation

/// Parses AIMS eCrew calendar-event note bodies.
/// Contract: docs/aims-ecrew-calendar-parse.md
public struct AIMSNotesParser: Sendable {
    public static let sourceMarker = "--- Inserted by the AIMS eCrew app ---"

    public struct Result: Sendable, Hashable {
        public let sectorCode: String
        public let reportingUTC: Date
        public let flightNumber: String
        public let origin: String
        public let stdUTC: Date
        public let destination: String
        public let staUTC: Date
        public let debriefingUTC: Date?
        public let rawNotes: String
    }

    public init() {}

    public func hasAIMSMarker(_ notes: String) -> Bool {
        notes.contains(Self.sourceMarker)
    }

    /// Parses an AIMS eCrew note body anchored to the event's `startDate` (which is in device-local TZ).
    /// All HHMM tokens in the notes are UTC; `+1` suffix means "next calendar day".
    public func parse(notes: String, eventStart: Date) throws -> Result {
        guard hasAIMSMarker(notes) else {
            throw ParseError.missingSourceMarker
        }

        let lines = notes.split(whereSeparator: \.isNewline).map { String($0) }
        let firstNonEmpty = lines.first { !$0.trimmingCharacters(in: .whitespaces).isEmpty } ?? ""

        let sectorCode = try firstMatch(
            of: #"^(\d+[A-Z]?)\b"#,
            in: firstNonEmpty.trimmingCharacters(in: .whitespaces),
            captureIndex: 1
        ).orThrow(ParseError.sectorCodeNotFound)

        let reporting = try firstMatch(
            of: #"Reporting time\s*:\s*(\d{4})"#,
            in: notes,
            captureIndex: 1
        ).orThrow(ParseError.reportingTimeNotFound)

        let flightLine = try matchFlightLine(in: notes)

        let debriefing = firstDoubleMatch(
            of: #"Debriefing time\s*:\s*(\d{4})(\+\d)?"#,
            in: notes
        )

        let anchor = utcDayStart(forEventAt: eventStart)

        let reportingDate = try resolveUTC(hhmm: reporting, dayOffset: 0, anchor: anchor)
        var stdDate       = try resolveUTC(hhmm: flightLine.std, dayOffset: 0, anchor: anchor)
        while stdDate < reportingDate {
            stdDate = stdDate.addingTimeInterval(86_400)
        }

        let staOffset = flightLine.staDayOffset
        let staDate   = try resolveUTC(hhmm: flightLine.sta, dayOffset: staOffset, anchor: anchor)

        let debriefDate: Date? = try debriefing.map { match in
            let off = match.offset ?? 0
            return try resolveUTC(hhmm: match.hhmm, dayOffset: off, anchor: anchor)
        }

        return Result(
            sectorCode:    sectorCode,
            reportingUTC:  reportingDate,
            flightNumber:  flightLine.flight,
            origin:        flightLine.origin,
            stdUTC:        stdDate,
            destination:   flightLine.destination,
            staUTC:        staDate,
            debriefingUTC: debriefDate,
            rawNotes:      notes
        )
    }

    // MARK: - Helpers

    private struct FlightLine {
        let flight: String
        let origin: String
        let std: String
        let destination: String
        let sta: String
        let staDayOffset: Int
    }

    private func matchFlightLine(in notes: String) throws -> FlightLine {
        let pattern = #"(\d+)\s*-\s*([A-Z]{3})\s*\((\d{4})\)\s*-\s*([A-Z]{3})\s*\((\d{4})(\+\d)?\)"#
        let regex = try NSRegularExpression(pattern: pattern)
        let range = NSRange(notes.startIndex..., in: notes)
        guard let m = regex.firstMatch(in: notes, range: range) else {
            throw ParseError.flightLineNotFound
        }
        func group(_ i: Int) -> String? {
            let r = m.range(at: i)
            guard r.location != NSNotFound, let s = Range(r, in: notes) else { return nil }
            return String(notes[s])
        }
        guard
            let flight = group(1),
            let origin = group(2),
            let std    = group(3),
            let dest   = group(4),
            let sta    = group(5)
        else { throw ParseError.flightLineNotFound }
        let staOff: Int = {
            guard let suffix = group(6) else { return 0 }
            return Int(suffix.dropFirst()) ?? 0
        }()
        return FlightLine(
            flight: flight, origin: origin, std: std,
            destination: dest, sta: sta, staDayOffset: staOff
        )
    }

    private struct DoubleMatch { let hhmm: String; let offset: Int? }

    private func firstDoubleMatch(of pattern: String, in s: String) -> DoubleMatch? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(s.startIndex..., in: s)
        guard let m = regex.firstMatch(in: s, range: range) else { return nil }
        func group(_ i: Int) -> String? {
            let r = m.range(at: i)
            guard r.location != NSNotFound, let rr = Range(r, in: s) else { return nil }
            return String(s[rr])
        }
        guard let hhmm = group(1) else { return nil }
        let off: Int? = group(2).flatMap { Int($0.dropFirst()) }
        return DoubleMatch(hhmm: hhmm, offset: off)
    }

    private func firstMatch(of pattern: String, in s: String, captureIndex: Int) throws -> String? {
        let regex = try NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])
        let range = NSRange(s.startIndex..., in: s)
        guard let m = regex.firstMatch(in: s, range: range) else { return nil }
        let r = m.range(at: captureIndex)
        guard r.location != NSNotFound, let rr = Range(r, in: s) else { return nil }
        return String(s[rr])
    }

    private func utcDayStart(forEventAt eventStart: Date) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return cal.startOfDay(for: eventStart)
    }

    private func resolveUTC(hhmm: String, dayOffset: Int, anchor: Date) throws -> Date {
        guard hhmm.count == 4, let hh = Int(hhmm.prefix(2)), let mm = Int(hhmm.suffix(2)) else {
            throw ParseError.invalidTimeToken(hhmm)
        }
        let secs = TimeInterval(dayOffset * 86_400 + hh * 3_600 + mm * 60)
        return anchor.addingTimeInterval(secs)
    }

    public enum ParseError: Error, Equatable {
        case missingSourceMarker
        case sectorCodeNotFound
        case reportingTimeNotFound
        case flightLineNotFound
        case invalidTimeToken(String)
    }
}

private extension Optional {
    func orThrow(_ error: any Error) throws -> Wrapped {
        guard let self else { throw error }
        return self
    }
}
