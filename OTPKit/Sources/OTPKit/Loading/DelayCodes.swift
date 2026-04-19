import Foundation

public struct DelayCodeCatalog: Sendable, Codable {
    public struct Code: Sendable, Codable, Hashable, Identifiable {
        public var id: String { code }
        public let code: String
        public let name: String
        public let description: String
    }

    public struct Group: Sendable, Codable, Hashable {
        public let range: String
        public let label: String
        public let codes: [Code]
    }

    public let source: String
    public let lastUpdated: String
    public let groups: [Group]

    public var flat: [Code] { groups.flatMap(\.codes) }

    public func code(_ value: String) -> Code? {
        flat.first { $0.code == value }
    }

    enum CodingKeys: String, CodingKey {
        case source
        case lastUpdated = "last_updated"
        case groups
    }
}

public struct DelayCodeLoader: Sendable {
    private let bundle: Bundle
    public init() { self.bundle = .module }
    public init(bundle: Bundle) { self.bundle = bundle }

    public func load() throws -> DelayCodeCatalog {
        try TimelineLoader(bundle: bundle).loadJSON(
            DelayCodeCatalog.self,
            named: "iata_delay_codes",
            subdirectory: "data"
        )
    }
}
