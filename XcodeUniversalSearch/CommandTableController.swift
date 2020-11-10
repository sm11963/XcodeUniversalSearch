//
//  CommandTableController.swift
//  XcodeUniversalSearch
//
//  Created by Sam Miller on 11/3/20.
//

import Foundation
import AppKit

protocol CommandTableControllerViewDelegate: class {
    var canRemoveRow: Bool { get set }
}

final class CommandTableViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, NSTextFieldDelegate {
    
    weak var viewDelegate: CommandTableControllerViewDelegate?
    
    private var commands: [Command] = [
        .init(name: "Google", urlTemplate: "https://google.com/search?q=%s"),
        .init(name: "StackOverflow", urlTemplate: "https://stackoverflow.com/search?q=%s")
    ]
    
    private lazy var tableScrollView = NSScrollView()
    private lazy var tableView = NSTableView()
    
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
        
        let nameColumn = NSTableColumn(identifier: .name)
        nameColumn.minWidth = 150
        nameColumn.headerCell = NSTableHeaderCell(textCell: "Command name")
        tableView.addTableColumn(nameColumn)
        
        let urlTemplateColumn = NSTableColumn(identifier: .urlTemplate)
        urlTemplateColumn.minWidth = 200
        urlTemplateColumn.headerCell = NSTableHeaderCell(textCell: "URL Template")
        tableView.addTableColumn(urlTemplateColumn)
        
        
        tableView.doubleAction = #selector(handleDoubleTap(tableView:))
    }
    
    @objc func handleDoubleTap(tableView: NSTableView) {
        print("Double click on \(tableView.clickedRow), \(tableView.clickedColumn)" )
        
        if (tableView.clickedRow, tableView.clickedColumn) == (-1, -1) {
            print("Double click on whitespace to add new row")
            addRow()
        } else {
            let rowView = tableView.rowView(atRow: tableView.clickedRow, makeIfNecessary: false)
            let cellView = rowView?.view(atColumn: tableView.clickedColumn)
            
            if let textField = (cellView as? NSTableCellView)?.textField,
               textField.acceptsFirstResponder {
                textField.isEditable = true
                NSApp.keyWindow?.makeFirstResponder(textField)
            }
        }
    }
        
    func refresh() {
        tableView.reloadData()
    }
    
    func removeSelectedRow() {
        guard !tableView.selectedRowIndexes.isEmpty else { return }
        
        for index in tableView.selectedRowIndexes.sorted().reversed() {
            commands.remove(at: index)
        }
        tableView.removeRows(at: tableView.selectedRowIndexes, withAnimation: .effectGap)
    }
    
    func addRow() {
        commands.append(Command(name: "Custom Command", urlTemplate: "https://example.com/search?q=%s"))
        tableView.insertRows(at: IndexSet(integer: commands.count-1), withAnimation: .effectGap)
        DispatchQueue.main.async {
            let rowView = self.tableView.rowView(atRow: self.commands.count-1, makeIfNecessary: true)
            let cellView = rowView?.view(atColumn: 0)
            
            if let textField = (cellView as? NSTableCellView)?.textField,
               textField.acceptsFirstResponder {
                textField.isEditable = true
                NSApp.keyWindow?.makeFirstResponder(textField)
            }
        }
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
        let newCommand: Command?
        switch tableView.tableColumns[col].identifier {
        case .name:
            newCommand = Command(name: textField.stringValue, urlTemplate: command.urlTemplate)
        case .urlTemplate:
            newCommand = Command(name: command.name, urlTemplate: textField.stringValue)
        default:
            newCommand = nil
        }
        
        if let newCommand = newCommand {
            commands.remove(at: row)
            commands.insert(newCommand, at: row)
        } else {
            print("ERROR: could not create new command, could not match column identifiers")
        }
    }


    // MARK: - NSTableViewDataSource
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        commands.count
    }
    
    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        print(String(describing: object))
    }
    
    // MARK: - NSTableViewDelegate
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        print(tableView.selectedRowIndexes)
        viewDelegate?.canRemoveRow = !tableView.selectedRowIndexes.isEmpty
    }
    
    func tableView(_ tableView: NSTableView, shouldEdit tableColumn: NSTableColumn?, row: Int) -> Bool {
        true
    }
    
    
    func tableView(_ tableView: NSTableView, shouldReorderColumn columnIndex: Int, toColumn newColumnIndex: Int) -> Bool {
        true
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let rowView: NSTableCellView? = (tableView.makeView(withIdentifier: .text, owner: self) as? NSTableCellView) ?? {
            // Create a text field for the cell
            let textField = NSTextField()
            textField.backgroundColor = .clear
            textField.translatesAutoresizingMaskIntoConstraints = false
            textField.isBordered = false
            textField.controlSize = .small
            textField.delegate = self
            
            //            return textField
            
            // Create a cell
            let newCell = NSTableCellView()
            newCell.identifier = .text
            newCell.addSubview(textField)
            newCell.textField = textField
            newCell.addConstraint(.init(item: textField, attribute: .height, relatedBy: .equal, toItem: newCell, attribute: .height, multiplier: 1.0, constant: 0.0))
            newCell.addConstraint(.init(item: textField, attribute: .width, relatedBy: .equal, toItem: newCell, attribute: .width, multiplier: 1.0, constant: 0.0))
            
            newCell.constraints.forEach { $0.isActive = true }
            
            return newCell
        }()
                
        let value: String?
        
        let command = commands[row]
        switch tableColumn?.identifier {
        case .name?:
            value = command.name
        case .urlTemplate?:
            value = command.urlTemplate
        default:
            value = nil
        }
        
        rowView?.textField?.stringValue = value ?? ""
        
        return rowView
    }
}
