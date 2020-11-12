//
//  CommandOptionsView.swift
//  XcodeUniversalSearch
//
//  Created by Sam Miller on 11/3/20.
//

import SwiftUI
import XcodeUniversalSearchFoundation


struct CommandOptionsView: View {
    
    private let saveAction: ((Configuration.Command.Options) -> ())
        
    @State var escapeRegex: Bool
    @State var escapeDoubleQuote: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            Toggle("Escape regex metacharacters in search string (escaped with /)", isOn: $escapeRegex)
            Toggle("Escape double quotes in search string (escaped with ///)", isOn: $escapeDoubleQuote)
            HStack {
                Spacer()
                Button("Save") {
                    saveAction(.init(shouldEscapeForRegex: escapeRegex, shouldEscapeDoubleQuotes: escapeDoubleQuote))
                }
            }
        }
        .padding(20)
        .fixedSize()
    }
    
    init(initialOptions: Configuration.Command.Options, saveAction: (@escaping (Configuration.Command.Options) -> ())) {
        self._escapeRegex = State(initialValue: initialOptions.shouldEscapeForRegex)
        self._escapeDoubleQuote = State(initialValue: initialOptions.shouldEscapeDoubleQuotes)
        self.saveAction = saveAction
    }
}

struct CommandTableViewController_Previews: PreviewProvider {
    static var previews: some View {
        CommandOptionsView(initialOptions: .init(shouldEscapeForRegex: false, shouldEscapeDoubleQuotes: false), saveAction: { _ in })
    }
}
