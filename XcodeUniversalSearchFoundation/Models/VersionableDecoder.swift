// This was adapted from https://github.com/krzysztofzablocki/Versionable

import Foundation

public final class VersionableDecoder {
    public init() {
    }

    public func decode<T>(_ type: T.Type, from data: Data, usingDecoder decoder: JSONDecoder = .init()) throws -> T where T: Versionable {
        let serializedVersion = try decoder.decode(VersionContainer<T.Version>.self, from: data)

        if serializedVersion.version == type.latestVersion {
            return try decoder.decode(T.self, from: data)
        }

        guard var payload = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw VersionableDecoderError.unexpectedJSONType
        }

        #if DEBUG
        let originalList = type.Version.allCases
        let sorted = originalList.sorted(by: { $0 < $1 })
        assert(originalList.map { $0 } == sorted.map { $0 }, "\(type) Versions should be sorted by their comparable order")
        #endif

        type
            .Version
            .allCases
            .filter { serializedVersion.version < $0 }
            .forEach {
                type.migrate(to: $0)(&payload)
                payload["version"] = $0.rawValue
            }

        let data = try JSONSerialization.data(withJSONObject: payload as Any, options: [])
        return try decoder.decode(T.self, from: data)
    }
    
    enum VersionableDecoderError: Error {
        case unexpectedJSONType
    }
}
