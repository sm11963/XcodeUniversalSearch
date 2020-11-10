//
//  ContentView.swift
//  XcodeUniversalSearch
//
//  Created by Sam Miller on 11/1/20.
//

import SwiftUI
import Foundation
import AppKit

struct ContentView: View {
    
    @State var canRemoveRow: Bool = false
    @State var removeRowAction: (() -> ()) = { fatalError("Action needs to be set before being executed") }
    @State var addRowAction: (() -> ()) = { fatalError("Action needs to be set before being executed") }
        
    var body: some View {
        VStack {
            CommandTable(canRemoveRow: $canRemoveRow,
                           removeRowAction: $removeRowAction,
                           addRowAction: $addRowAction)
            HStack {
                Button("Clear storage") {
                    configurationManager?.clearStorage()
                }
                Spacer()
                Button("Delete", action: removeRowAction)
                    .disabled(!canRemoveRow)
                Button("Add Command", action: addRowAction)
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
    
    private let configurationManager = ConfigurationManager()
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
