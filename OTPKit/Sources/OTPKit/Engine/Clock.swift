import Foundation

public protocol OTPClock: Sendable {
    func now() -> Date
}

public struct SystemClock: OTPClock {
    public init() {}
    public func now() -> Date { Date() }
}

public struct FixedClock: OTPClock {
    private let fixed: Date
    public init(_ fixed: Date) { self.fixed = fixed }
    public func now() -> Date { fixed }
}
