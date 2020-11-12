//
//  ContentView.swift
//  XcodeUniversalSearch
//
//  Created by Sam Miller on 11/1/20.
//

import SwiftUI
import Foundation
import AppKit
import XcodeUniversalSearchFoundation
import Combine

struct ContentView: View {
    
    @State private var canRemoveRow: Bool = false
    
    private let addRowSubject = PassthroughSubject<(), Never>()
    private let removeRowSubject = PassthroughSubject<(), Never>()
    private let reloadSubject = PassthroughSubject<(), Never>()

    var body: some View {
        VStack {
            
            HStack {
                Spacer()
                Button("Import", action: importConfiguration)
                Button("Export", action: exportConfiguration)
            }
            
            CommandTable(canRemoveRow: $canRemoveRow,
                         addRowPublisher: addRowSubject.eraseToAnyPublisher(),
                         removeRowPublisher: removeRowSubject.eraseToAnyPublisher(),
                         reloadPublisher: reloadSubject.eraseToAnyPublisher())
            
            HStack {
                #if DEBUG
                // In debug mode, expose a button to clear the configuration
                Button("Clear storage") {
                    configurationManager?.clearStorage()
                }
                #endif
                Spacer()
                Button("Delete") {
                    removeRowSubject.send()
                }
                    .disabled(!canRemoveRow)
                Button("Add Command") {
                    addRowSubject.send()
                }
            }
        }
        .padding(20)
        .frame(minWidth: 600,
               idealWidth: 800,
               maxWidth: .infinity,
               minHeight: 400,
               idealHeight: 400,
               maxHeight: .infinity,
               alignment: .center)
    }
    
    // MARK: - Private
    
    // TODO: If the configuration manager does not load, we should disable everything and show an error
    private let configurationManager = ConfigurationManager()
    
    private func importConfiguration() {
        let dialog = NSOpenPanel()
        
        dialog.title = "Choose a file to import configuration"
        dialog.showsResizeIndicator = true
        dialog.showsHiddenFiles = false
        dialog.allowedFileTypes = ["json"]
        dialog.allowsOtherFileTypes = false
        dialog.nameFieldStringValue = "xcode_universal_search_config.json"
        
        if (dialog.runModal() == .OK) {
            guard let url = dialog.url else {
                // TODO: Handle error better
                print("ERROR: Unable to retreive URL from save file dialog")
                return
            }
            
            guard let configurationManager = configurationManager else {
                // TODO: Handle error better
                print("Unable to load key value storage")
                return
            }
            
            do {
                let configuration = try configurationManager.read(from: url.path)
                if let configuration = configuration {
                    let oldConfiguration = configurationManager.load().data
                    
                    let mergedCommands = (oldConfiguration?.commands ?? []) + configuration.commands
                    let mergedConfiguration = Configuration(commands: mergedCommands)
                    
                    let success = configurationManager.save(mergedConfiguration)
                    if !success {
                        print("Failed to save configuration to internal storage")
                    }
                    reloadSubject.send()
                } else {
                    // TODO: Handle error better
                    print("Failed to load configuration from path \"\(url.path)\"")
                }
            } catch {
                print("Error reading from configuration at \"\(url.path)\" - \(error.localizedDescription)")
            }
        }
    }
    
    private func exportConfiguration() {
        let dialog = NSSavePanel()
        
        dialog.title = "Choose a file to export configuration"
        dialog.showsResizeIndicator = true
        dialog.showsHiddenFiles = false
        dialog.allowedFileTypes = ["json"]
        dialog.allowsOtherFileTypes = false
        dialog.nameFieldStringValue = "xcode_universal_search_config.json"
        
        if (dialog.runModal() == .OK) {
            guard let url = dialog.url else {
                // TODO: Handle error better
                print("ERROR: Unable to retreive URL from save file dialog")
                return
            }
            
            guard let configurationManager = configurationManager else {
                // TODO: Handle error better
                print("Unable to load key value storage")
                return
            }
            
            do {
                if !(try configurationManager.write(to: url.path)) {
                    // TODO: Handle error better
                    print("ERROR: Failed to write to file")
                }
            } catch ConfigurationManager.ConfigurationWriteError.noConfiguration {
                // TODO: Handle error better
                print("ERROR: No configuration to write")
            } catch {
                //TODO: Handle error better
                print("ERROR: Error while writing configuration file - \(error.localizedDescription)")
            }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
