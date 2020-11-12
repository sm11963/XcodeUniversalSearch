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
    
    @State var percentEncodeFullUrl: Bool
    @State var escapeRegex: Bool
    @State var escapeDoubleQuote: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            Toggle("Remove percent encoding from url template and encode final url", isOn: $percentEncodeFullUrl)
            Toggle("Escape regex metacharacters in search string (escaped with /)", isOn: $escapeRegex)
            Toggle("Escape double quotes in search string (escaped with ///)", isOn: $escapeDoubleQuote)
            HStack {
                Spacer()
                Button("Save") {
                    saveAction(.init(shouldPercentEncodeFullUrl: percentEncodeFullUrl,
                                     shouldEscapeForRegex: escapeRegex,
                                     shouldEscapeDoubleQuotes: escapeDoubleQuote))
                }
            }
        }
        .padding(20)
        .fixedSize()
    }
    
    init(initialOptions: Configuration.Command.Options, saveAction: (@escaping (Configuration.Command.Options) -> ())) {
        self._percentEncodeFullUrl = State(initialValue: initialOptions.shouldPercentEncodeFullUrl)
        self._escapeRegex = State(initialValue: initialOptions.shouldEscapeForRegex)
        self._escapeDoubleQuote = State(initialValue: initialOptions.shouldEscapeDoubleQuotes)
        self.saveAction = saveAction
    }
}

struct CommandTableViewController_Previews: PreviewProvider {
    static var previews: some View {
        CommandOptionsView(initialOptions: .init(shouldPercentEncodeFullUrl: true,
                                                 shouldEscapeForRegex: false,
                                                 shouldEscapeDoubleQuotes: false), saveAction: { _ in })
    }
}
