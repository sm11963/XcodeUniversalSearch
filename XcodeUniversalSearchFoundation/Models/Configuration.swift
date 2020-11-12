//
//  Configuration.swift
//  XcodeUniversalSearch
//
//  Created by Sam Miller on 11/3/20.
//

import Foundation

public struct Configuration: Codable {
    
    struct Command: Codable {
        struct Options: Codable {
            let shouldEscapeForRegex: Bool
            let shouldEscapeDoubleQuotes: Bool
            
            static var `default`: Self {
                .init(shouldEscapeForRegex: false, shouldEscapeDoubleQuotes: false)
            }
        }

        let name: String
        let urlTemplate: String
        let options: Options
    }
    
    let commands: [Command]
}

public final class ConfigurationManager {
    
    enum Result {
        case success(_ configuration: Configuration?)
        case error(_ error: Error)
        
        var data: Configuration? {
            switch self {
            case .success(let configuration): return configuration
            case .error(_): return nil
            }
        }
    }
    
    init?() {
        guard let userDefaults = UserDefaults(suiteName: Self.defaultsSuiteName) else {
            return nil
        }
        self.userDefaults = userDefaults
    }
    
    func load() -> Result {
        let storedData = userDefaults.data(forKey: StorageKey.configuration.rawValue)
        guard let data = storedData else {
            return .success(nil)
        }
        
        do {
            return .success(try Self.decoder.decode(Configuration.self, from: data))
        } catch {
            return .error(error)
        }
    }
    
    func save(_ configuration: Configuration) -> Bool {
        guard let data = try? Self.encoder.encode(configuration) else {
            return false
        }
        
        userDefaults.set(data, forKey: StorageKey.configuration.rawValue)
        return true
    }
    
    func clearStorage() {
        userDefaults.removeObject(forKey: StorageKey.configuration.rawValue)
    }
    
    // MARK: - Private
    
    private enum StorageKey: String {
        case configuration
    }
    
    private let userDefaults: UserDefaults
    
    private static let decoder = JSONDecoder()
    private static let encoder = JSONEncoder()
    
    private static let defaultsSuiteName = "M952V223C9.group.com.pandaprograms.XcodeUniversalSearch"
}
