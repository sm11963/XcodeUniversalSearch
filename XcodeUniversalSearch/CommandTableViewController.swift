//
//  CommandTableController.swift
//  XcodeUniversalSearch
//
//  Created by Sam Miller on 11/3/20.
//

import Foundation
import AppKit
import SwiftUI

/**
 TODO: Follow https://samwize.com/2018/11/27/drag-and-drop-to-reorder-nstableview/ to enable re-ordering rows
 */

protocol CommandTableControllerViewDelegate: class {
    var canRemoveRow: Bool { get set }
}

final class CommandTableViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, NSTextFieldDelegate {
    
    weak var viewDelegate: CommandTableControllerViewDelegate?
        
    func refresh() {
        tableView.reloadData()
    }
    
    func removeSelectedRow() {
        guard !tableView.selectedRowIndexes.isEmpty else { return }
        
        for index in tableView.selectedRowIndexes.sorted().reversed() {
            commands.remove(at: index)
        }
        tableView.removeRows(at: tableView.selectedRowIndexes, withAnimation: .effectGap)
        synchronizeCommands()
    }
    
    func addRow() {
        let newIndex = commands.count
        commands.append(.init(name: "Custom Command", urlTemplate: "https://example.com/search?q=%s", options: .default))
        tableView.insertRows(at: IndexSet(integer: newIndex), withAnimation: .effectGap)
        makeTextFieldFirstResponder(atRow: newIndex, column: 0)
        synchronizeCommands()
    }
    
    // MARK: - NSViewController
    
    override func loadView() {
        view = tableScrollView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        tableScrollView.documentView = tableView
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.headerView?.isHidden = false
        tableView.allowsMultipleSelection = true
        tableView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        
        let nameColumn = NSTableColumn(identifier: .name)
        nameColumn.minWidth = 150
        nameColumn.headerCell = NSTableHeaderCell(textCell: "Command name")
        tableView.addTableColumn(nameColumn)
        
        let urlTemplateColumn = NSTableColumn(identifier: .urlTemplate)
        urlTemplateColumn.minWidth = 250
        urlTemplateColumn.headerCell = NSTableHeaderCell(textCell: "URL Template")
        tableView.addTableColumn(urlTemplateColumn)
        
        let optionsColumn = NSTableColumn(identifier: .options)
        optionsColumn.minWidth = 80
        optionsColumn.headerCell = NSTableHeaderCell(textCell: "Options")
        tableView.addTableColumn(optionsColumn)
        
        tableView.doubleAction = #selector(handleDoubleTap(tableView:))
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        loadFromConfiguration()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        tableView.reloadData()
    }
    
    // MARK: - NSControlTextEditingDelegate
    
    func controlTextDidEndEditing(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField else { return }
        
        let col = tableView.column(for: textField)
        let row = tableView.row(for: textField)
        
        
        let command = commands[row]
        let newCommand: Configuration.Command?
        switch tableView.tableColumns[col].identifier {
        case .name:
            newCommand = .init(name: textField.stringValue, urlTemplate: command.urlTemplate, options: command.options)
        case .urlTemplate:
            newCommand = .init(name: command.name, urlTemplate: textField.stringValue, options: command.options)
        default:
            newCommand = nil
        }
        
        if let newCommand = newCommand {
            commands.remove(at: row)
            commands.insert(newCommand, at: row)
        } else {
            print("ERROR: could not create new command, could not match column identifiers")
        }
        synchronizeCommands()
    }


    // MARK: - NSTableViewDataSource
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        commands.count
    }
    
    // MARK: - NSTableViewDelegate
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        viewDelegate?.canRemoveRow = !tableView.selectedRowIndexes.isEmpty
    }
    
    func tableView(_ tableView: NSTableView, shouldEdit tableColumn: NSTableColumn?, row: Int) -> Bool {
        true
    }
    
    
    func tableView(_ tableView: NSTableView, shouldReorderColumn columnIndex: Int, toColumn newColumnIndex: Int) -> Bool {
        true
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        enum CellType {
            case text(_ value: String?)
            case button
        }
        
        let cellType: CellType?
        
        let command = commands[row]
        switch tableColumn?.identifier {
        case .name?:
            cellType = .text(command.name)
        case .urlTemplate?:
            cellType = .text(command.urlTemplate)
        case .options?:
            cellType = .button
        default:
            cellType = nil
        }

        switch cellType {
        case .text(let value)?:
            let cellView: NSTableCellView? = (tableView.makeView(withIdentifier: .text, owner: self) as? NSTableCellView) ?? {
                // Create a text field for the cell
                let textField = NSTextField()
                textField.backgroundColor = .clear
                textField.translatesAutoresizingMaskIntoConstraints = false
                textField.isBordered = false
                textField.controlSize = .small
                textField.delegate = self
                            
                // Create a cell
                let newCell = NSTableCellView()
                newCell.identifier = .text
                newCell.addSubview(textField)
                newCell.textField = textField
                newCell.widthAnchor.constraint(equalTo: textField.widthAnchor).isActive = true
                newCell.heightAnchor.constraint(equalTo: textField.heightAnchor).isActive = true
                
                return newCell
            }()
            
            cellView?.textField?.stringValue = value ?? ""
            
            return cellView
        case .button?:
            let view: NSButton = (tableView.makeView(withIdentifier: .optionsButton, owner: self) as? NSButton) ?? {
                let button = NSButton(title: "Options", target: nil, action: nil)
                button.target = self
                button.action = #selector(handleOptionsButton(sender:))
                button.identifier = .optionsButton
                
                return button
            }()
            
            return view
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        30
    }
    
    // MARK: - Private
    
    private var commands: [Configuration.Command] = []
    private let configurationManager = ConfigurationManager()
    
    private lazy var tableScrollView = NSScrollView()
    private lazy var tableView = NSTableView()
    
    
    @objc private func handleDoubleTap(tableView: NSTableView) {
        if (tableView.clickedRow, tableView.clickedColumn) == (-1, -1) {
            addRow()
        } else {
            makeTextFieldFirstResponder(atRow: tableView.clickedRow, column: tableView.clickedColumn)
        }
    }

    @objc private func handleOptionsButton(sender: NSButton) {
        let row = tableView.row(for: sender)
               
        let vc = NSHostingController(rootView: CommandOptionsView(initialOptions: commands[row].options, saveAction: { [weak self] options in
            guard let strongSelf = self else { return }
            
            let oldCommand = strongSelf.commands.remove(at: row)
            
            let newCommand = Configuration.Command(name: oldCommand.name,
                                                   urlTemplate: oldCommand.urlTemplate,
                                                   options: options)
            strongSelf.commands.insert(newCommand, at: row)
            strongSelf.synchronizeCommands()
            
            if let vc = strongSelf.presentedViewControllers?.first {
                strongSelf.dismiss(vc)
            }
        }))
        
        vc.title = "Command Options"
        
        presentAsModalWindow(vc)
    }
    
    private func makeTextFieldFirstResponder(atRow row: Int, column: Int) {
        guard let view = tableView.rowView(atRow: row, makeIfNecessary: false)?.view(atColumn: column) else {
            // TODO: Throw a better error
            print("ERROR: Unable to retrieve view at (\(row), \(column)) to start editing")
            return
        }
        
        if let textField = (view as? NSTableCellView)?.textField,
           textField.acceptsFirstResponder {
            textField.window?.makeFirstResponder(textField)
        }
    }
    
    private func loadFromConfiguration() {
        guard let configurationManager = configurationManager else {
            print("ERROR: Cannot load data - Failed initializing storage")
            return
        }
        
        let result = configurationManager.load()
        
        switch result {
        case .error(let error):
            // TODO: Add a much better error and show in UI
            print("ERROR: Encountered error loading configuration: \(error)")
        case .success(let configuration):
            if let config = configuration {
                commands = config.commands
            } else {
                // This is a first launch, no configuration saved before - add defaults
                commands = [
                    .init(name: "Google", urlTemplate: "https://google.com/search?q=%s", options: .default),
                    .init(name: "StackOverflow", urlTemplate: "https://stackoverflow.com/search?q=%s", options: .default),
                    .init(name: "Apple Documentation", urlTemplate: "https://developer.apple.com/search?q=%s", options: .default)
                ]
                synchronizeCommands()
            }
        }
    }
    
    private func synchronizeCommands() {
        if configurationManager?.save(.init(commands: commands)) != true {
            // TODO: Handle error properly and show in UI
            print("ERROR: Saving commands failed")
        }
    }
}

private extension NSUserInterfaceItemIdentifier {
    static var name: Self { .init("name") }
    static var urlTemplate: Self { .init("urlTemplate") }
    static var options: Self { .init("options") }
    
    static var text: Self { .init("text") }
    static var optionsButton: Self { .init("optionsButton") }
}
