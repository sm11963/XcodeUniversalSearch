//
//  SourceEditorExtension.swift
//  XcodeUniversalSearchExtension
//
//  Created by Sam Miller on 11/1/20.
//

import Foundation
import XcodeKit
import XcodeUniversalSearchFoundation

final class SourceEditorExtension: NSObject, XCSourceEditorExtension {
    
    func extensionDidFinishLaunching() {}
    
    var commandDefinitions: [[XCSourceEditorCommandDefinitionKey: Any]] {
        guard let config = configurationManager?.load().data else {
            return [
                [
                    .classNameKey: SourceEditorCommand.className(),
                    .nameKey: "-- Internal extension error loading from storage --",
                    .identifierKey: [Bundle.main.bundleIdentifier, "\(-1)"]
                        .compactMap { $0 }
                        .joined(separator: "."),
                ]
            ]
        }

        return config.commands
            .enumerated()
            .map { idx, command in
                [
                    .classNameKey: SourceEditorCommand.className(),
                    .nameKey: command.name,
                    .identifierKey: [Bundle.main.bundleIdentifier, "\(idx)"].compactMap { $0 }.joined(separator: ".")
                ]
            }
         
    }
    
    // MARK: - Private
    
    private let configurationManager = ConfigurationManager()
}
