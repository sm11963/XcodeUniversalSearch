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
        guard let configurationManager = configurationManager else {
            completionHandler(generalError(withDescription: "Internal application error: Unable to initialize configuration storage"))
            return
        }
        
        let result = configurationManager.load()
        
        let configuration: Configuration?
        switch result {
        case .success(let config):
            configuration = config
        case .error(let error):
            completionHandler(generalError(withDescription: "Internal application error: Failed to load configuration with error - \(error.localizedDescription)"))
            return
        }
        
        guard let commandIndexString = invocation.commandIdentifier.split(separator: ".").last,
            let commandIndex = Int(commandIndexString),
            let command = configuration?.commands[safe: commandIndex] else {
            completionHandler(generalError(withDescription: "Internal application error: Extension failed to load correctly"))
            return
        }
        
        // TODO: Handle selection accross multiple lines
        guard let selection = invocation.buffer.selections.firstObject as? XCSourceTextRange,
            let line = invocation.buffer.lines[selection.start.line] as? String else {
                completionHandler(generalError(withDescription: "Error processing the text selection"))
            return
        }

        let selectedText = String(line[selection.start.column ..< selection.end.column])
        let processedSelection = processSelectedText(selectedText, with: command.options)
        
        guard let encodedSelection = processedSelection.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            completionHandler(generalError(withDescription: "Error adding percent encoding to full URL with template: \"\(command.urlTemplate)\" and selection: \"\(processedSelection)\""))
            return
        }
        
        let urlString: String
        if command.options.shouldPercentEncodeFullUrl {
            guard let encoded = command.urlTemplate
                    // First remove percent encoding in case somethings are already encoded in the url template
                    .removingPercentEncoding(ignoringTokens: [Self.selectionToken])?
                    .replacingOccurrences(of: Self.selectionToken, with: encodedSelection)
                    // Note that this is not exactly escaping correctly. We are escaping all characters since we are escaping the full url string for characters
                    // not accepted in the url query string. Really each url component should be escaped individually. So if any issues occur with the urls
                    // there is good chance this is an issue.
                    .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                completionHandler(generalError(withDescription: "Error adding percent encoding to full URL with template: \"\(command.urlTemplate)\" and selection: \"\(processedSelection)\""))
                return
            }
            urlString = encoded
        } else {
            urlString = command.urlTemplate
                .replacingOccurrences(of: Self.selectionToken, with: encodedSelection)
        }
                
        guard let url = URL(string: urlString) else {
            completionHandler(generalError(withDescription: "Error creating url from \"\(urlString)\""))
            return
        }
        
        NSWorkspace.shared.open(url)

        completionHandler(nil)
    }
    
    // MARK: - Private
    
    private static let selectionToken = "%s"
    
    private let configurationManager = ConfigurationManager()
    
    private func processSelectedText(_ text: String, with options: Configuration.Command.Options) -> String {
        
        var result = text
        
        if options.shouldEscapeForRegex {
            result = NSRegularExpression.escapedPattern(for: result)
        }

        if options.shouldEscapeDoubleQuotes {
            result = result.replacingOccurrences(of: "\"", with: "\\\"")
        }
        
        return result
    }
    
    private func generalError(withDescription description: String) -> NSError {
        .init(domain: "XcodeUniversalSearch", code: 0, userInfo: [NSLocalizedDescriptionKey: description])
    }
}
