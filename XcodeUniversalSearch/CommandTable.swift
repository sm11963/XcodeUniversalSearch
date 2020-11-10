//
//  CommandTable.swift
//  XcodeUniversalSearch
//
//  Created by Sam Miller on 11/3/20.
//

import SwiftUI

struct CommandTable: NSViewControllerRepresentable {
    
    @Binding var canRemoveRow: Bool
    @Binding var removeRowAction: (() -> ())
    @Binding var addRowAction: (() -> ())
    
    typealias NSViewControllerType = CommandTableViewController
    
    class Coordinator: CommandTableControllerViewDelegate {
        var canRemoveRow: Bool {
            get {
                parent.canRemoveRow
            }
            set {
                parent.canRemoveRow = newValue
            }
        }
        
        private let parent: CommandTable
        
        init(_ parent: CommandTable) {
            self.parent = parent
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSViewController(
        context: NSViewControllerRepresentableContext<CommandTable>
    ) -> CommandTableViewController {
        
        let controller = CommandTableViewController()
        
        controller.viewDelegate = context.coordinator
        
        DispatchQueue.main.async { [controller] in
            self.removeRowAction = {
                controller.removeSelectedRow()
            }
            
            self.addRowAction = {
                controller.addRow()
            }
        }

        return controller
    }
    
    func updateNSViewController(
        _ nsViewController: CommandTableViewController,
        context: NSViewControllerRepresentableContext<CommandTable>
    ) {}
}
