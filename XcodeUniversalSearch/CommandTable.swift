//
//  CommandTable.swift
//  XcodeUniversalSearch
//
//  Created by Sam Miller on 11/3/20.
//

import SwiftUI
import Combine

struct CommandTable: NSViewControllerRepresentable {
    
    @Binding var canRemoveRow: Bool
    let addRowPublisher: AnyPublisher<(), Never>
    let removeRowPublisher: AnyPublisher<(), Never>
    let reloadPublisher: AnyPublisher<(), Never>
        
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
        
        var dismantleScopedCancellables = Set<AnyCancellable>()
        
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
        
        addRowPublisher
            .sink {
                controller.addRow()
            }
            .store(in: &context.coordinator.dismantleScopedCancellables)
        
        removeRowPublisher
            .sink {
                controller.removeSelectedRow()
            }
            .store(in: &context.coordinator.dismantleScopedCancellables)
        
        reloadPublisher
            .sink {
                controller.refresh()
            }
            .store(in: &context.coordinator.dismantleScopedCancellables)

        return controller
    }
    
    func updateNSViewController(
        _ nsViewController: CommandTableViewController,
        context: NSViewControllerRepresentableContext<CommandTable>
    ) {}
    
    static func dismantleNSViewController(_ nsViewController: CommandTableViewController, coordinator: Coordinator) {
        coordinator.dismantleScopedCancellables.removeAll()
    }
}
