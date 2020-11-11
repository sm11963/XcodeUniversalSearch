//
//  SourceEditorCommand.swift
//  XcodeUniversalSearchExtension
//
//  Created by Sam Miller on 11/1/20.
//

import Foundation
import XcodeKit
import AppKit
import XcodeUniversalSearchFoundation

final class SourceEditorCommand: NSObject, XCSourceEditorCommand {
    
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        print("Handling command with id: \(invocation.commandIdentifier)")
        
        guard let configurationManager = configurationManager else {
            completionHandler(NSError(domain: "XcodeUniversalSearch", code: 0, userInfo: [NSLocalizedDescriptionKey: "Internal application error: Unable to initialize configuration storage"]))
            return
        }
        
        let result = configurationManager.load()
        
        let configuration: Configuration?
        switch result {
        case .success(let config):
            configuration = config
        case .error(let error):
            completionHandler(NSError(domain: "XcodeUniversalSearch", code: 0, userInfo: [NSLocalizedDescriptionKey: "Internal application error: Failed to load configuration with error - \(error.localizedDescription)"]))
            return
        }
        
        guard let commandIndexString = invocation.commandIdentifier.split(separator: ".").last,
            let commandIndex = Int(commandIndexString),
            let command = configuration?.commands[safe: commandIndex] else {
            completionHandler(NSError(domain: "XcodeUniversalSearch", code: 0, userInfo: [NSLocalizedDescriptionKey: "Internal application error: Extension failed to load correctly"]))
            return
        }
        
        // TODO: Handle selection accross multiple lines
        guard let selection = invocation.buffer.selections.firstObject as? XCSourceTextRange,
            let line = invocation.buffer.lines[selection.start.line] as? String else {
                completionHandler(NSError(domain: "XcodeUniversalSearch", code: 0, userInfo: [NSLocalizedDescriptionKey: "Error processing the text selection"]))
            return
        }

        let selectedText = String(line[selection.start.column ..< selection.end.column])
        
        guard let urlString = command.urlTemplate
            .replacingOccurrences(of: "%s", with: processText(selectedText, with: command.options))
            // Note that this is not exactly escaping correctly escaping all characters since we are escaping the full url string for characters
            // not accepted in the url query string. Really each url component should be escaped individually. So if any issues occur with the urls
            // there is good chance this is an issue.
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        else {
            completionHandler(NSError(domain: "XcodeUniversalSearch", code: 0, userInfo: [NSLocalizedDescriptionKey: "Error escaping url with selection"]))
            return
        }
        
        guard let url = URL(string: urlString) else {
            completionHandler(NSError(domain: "XcodeUniversalSearch", code: 0, userInfo: [NSLocalizedDescriptionKey: "Error creating url"]))
            return
        }
        
        NSWorkspace.shared.open(url)

        completionHandler(nil)
    }
    
    // MARK: - Private
    
    private let configurationManager = ConfigurationManager()
    
    private func processText(_ text: String, with options: Configuration.Command.Options) -> String {
        
        var result = text
        
        if options.shouldEscapeForRegex {
            result = NSRegularExpression.escapedPattern(for: result)
        }

        if options.shouldEscapeDoubleQuotes {
            result = result.replacingOccurrences(of: "\"", with: "\\\"")
        }

        return result
    }
}
