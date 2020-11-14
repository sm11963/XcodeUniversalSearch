//
//  Configuration.swift
//  XcodeUniversalSearch
//
//  Created by Sam Miller on 11/3/20.
//

import Foundation

public struct Configuration: Codable {
    
    public struct Command: Codable {
        public struct Options: Codable {
            public let shouldEscapeForRegex: Bool
            public let shouldEscapeDoubleQuotes: Bool
            
            public static var `default`: Self {
                .init(shouldEscapeForRegex: false, shouldEscapeDoubleQuotes: false)
            }
            
            public init(shouldEscapeForRegex: Bool, shouldEscapeDoubleQuotes: Bool) {
                self.shouldEscapeForRegex = shouldEscapeForRegex
                self.shouldEscapeDoubleQuotes = shouldEscapeDoubleQuotes
            }
        }

        public let name: String
        public let urlTemplate: String
        public let options: Options
        
        public init(name: String, urlTemplate: String, options: Options) {
            self.name = name
            self.urlTemplate = urlTemplate
            self.options = options 
        }
    }
    
    public let commands: [Command]
    public let version: Version
    
    public init(commands: [Command]) {
        self.version = Self._version
        self.commands = commands
    }
    
    // MARK: Private
    
    private static let _version: Version = .v1
}

extension Configuration: Versionable {
    
    public enum Version: Int, VersionType {
        case v1 = 1
    }

    public static func migrate(to: Version) -> Migration {
        switch to {
        case .v1:
            return .none
        }
    }
}

public final class ConfigurationManager {
    
    public enum Result {
        case success(_ configuration: Configuration?)
        case error(_ error: Error)
        
        public var data: Configuration? {
            switch self {
            case .success(let configuration): return configuration
            case .error(_): return nil
            }
        }
    }
    
    public enum ConfigurationWriteError: Error {
        case noConfiguration
    }
    
    public init?() {
        guard let userDefaults = UserDefaults(suiteName: Self.defaultsSuiteName) else {
            return nil
        }
        self.userDefaults = userDefaults
    }
    
    public func load() -> Result {
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
    
    public func save(_ configuration: Configuration) -> Bool {
        guard let data = try? Self.encoder.encode(configuration) else {
            return false
        }
        
        userDefaults.set(data, forKey: StorageKey.configuration.rawValue)
        return true
    }
    
    public func clearStorage() {
        userDefaults.removeObject(forKey: StorageKey.configuration.rawValue)
    }
    
    public func write(to path: String) throws -> Bool {
        Self.encoder.outputFormatting.insert(.prettyPrinted)
        defer { Self.encoder.outputFormatting.remove(.prettyPrinted) }
        
        switch load() {
        case .success(let configuration):
            if let configuration = configuration {
                return Self.fileManager.createFile(atPath: path, contents: try Self.encoder.encode(configuration))
            } else {
                throw ConfigurationWriteError.noConfiguration
            }
        case .error(let error):
            throw error
        }
    }
    
    public func read(from path: String) throws -> Configuration? {
        guard let data = Self.fileManager.contents(atPath: path) else {
            // TODO: Handle error better
            print("Failed to load data from file at path \"\(path)\"")
            return nil
        }
        
        return try Self.decoder.decode(Configuration.self, from: data)
    }
    
    // MARK: - Private
    
    private enum StorageKey: String {
        case configuration
    }
    
    private let userDefaults: UserDefaults
    
    private static let decoder = VersionableDecoder()
    private static let encoder = JSONEncoder()
    private static let fileManager = FileManager.default
    
    private static let defaultsSuiteName = "M952V223C9.group.com.pandaprograms.XcodeUniversalSearch"
}
