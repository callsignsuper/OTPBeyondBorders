import Foundation

public enum OTPKitError: Error, Equatable {
    case resourceNotFound(String)
    case decodeFailed(String, String)
    case unknownFlight(String)
}

public struct TimelineLoader: Sendable {
    private let bundle: Bundle

    public init() {
        self.bundle = .module
    }

    public init(bundle: Bundle) {
        self.bundle = bundle
    }

    public func load(_ category: AircraftCategory) throws -> Timeline {
        try loadJSON(Timeline.self, named: category.resourceBasename, subdirectory: "timelines")
    }

    public func loadAll() throws -> [AircraftCategory: Timeline] {
        var out: [AircraftCategory: Timeline] = [:]
        for category in AircraftCategory.allCases {
            out[category] = try load(category)
        }
        return out
    }

    func loadJSON<T: Decodable>(_ type: T.Type, named name: String, subdirectory: String) throws -> T {
        guard let url = bundle.url(forResource: name, withExtension: "json", subdirectory: subdirectory) else {
            throw OTPKitError.resourceNotFound("\(subdirectory)/\(name).json")
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(T.self, from: data)
        } catch let decoding as DecodingError {
            throw OTPKitError.decodeFailed("\(subdirectory)/\(name).json", String(describing: decoding))
        } catch {
            throw OTPKitError.decodeFailed("\(subdirectory)/\(name).json", error.localizedDescription)
        }
    }
}
