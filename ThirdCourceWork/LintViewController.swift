//
//  LintTableViewCell.swift
//  ThirdCourceWork
//
//  Created by Тимур Миргалиев on 02.04.2023.
//

import Cocoa

class LintViewController: NSViewController {
    
    var dataSource: [String] = []
    
    var component: [String] = []
    var path: [String] = []
    var line: [String] = []
    var column: [String] = []
    var lastComponent: String = ""
    var errorType: [String] = []
    var errorMessage: [String] = []
    
    var initialized = false
    
    // UI
    let scrollView = NSScrollView()
    let tableView = NSTableView()
    
    private lazy var backButton: NSButton = {
        let button = NSButton()
        button.title = "Back"
        button.target = self
        button.action = #selector(backButtonTapped)
        button.bezelStyle = .texturedSquare
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - View life cyrcle
    
    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 400))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidLayout() {
        if !initialized {
            initialized = true
            workWithData()
            setupTableView()
        }
    }
    
    func setupTableView() {
        view.addSubview(backButton)
        
        backButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.heightAnchor.constraint(equalToConstant: CGFloat(30))
        ])
        
        view.addSubview(scrollView)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16)
        ])
        
        tableView.frame = scrollView.bounds
        tableView.delegate = self
        tableView.dataSource = self
        let customHeader = CustomTableHeaderView(frame: NSRect(x: 0, y: 0, width: 300, height: 30))
        tableView.headerView = customHeader
        scrollView.backgroundColor = NSColor.clear
        
        let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "col"))
        col.minWidth = 350
        col.title = ""
        tableView.addTableColumn(col)
        
        scrollView.documentView = tableView
        scrollView.hasHorizontalScroller = false
        scrollView.hasVerticalScroller = true
    }
    
    // MARK: - Private
    
    private func workWithData() {
        guard !dataSource.isEmpty else { return }
        dataSource.removeLast()
        for inputString in dataSource {
            component = inputString.components(separatedBy: ":")
            path.append(component[0])
            line.append(component[1])
            column.append(component[2])
            lastComponent = component[3].trimmingCharacters(in: .whitespacesAndNewlines)
            
            if lastComponent.hasPrefix("warning") {
                errorType.append("warning")
                errorMessage.append(component[4].trimmingCharacters(in: .whitespacesAndNewlines))
            } else {
                errorType.append("error")
                errorMessage.append(component[4].trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }
    }
    
    // MARK: - Actions
    
    @objc func backButtonTapped() {
        dismiss(self)
    }
}

// MARK: - NSTableViewDelegate, NSTableViewDataSource

extension LintViewController: NSTableViewDelegate, NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        guard !dataSource.isEmpty else { return 1 }
        return dataSource.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        if !dataSource.isEmpty {
            let cell = NSTableCellView()
            
            let lineLabel = NSTextField()
            lineLabel.stringValue = line[row]
            lineLabel.isEditable = false
            lineLabel.drawsBackground = false
            lineLabel.isBordered = false
            
            let warningTypeLabel = NSTextField()
            warningTypeLabel.stringValue = errorType[row]
            warningTypeLabel.drawsBackground = false
            warningTypeLabel.isEditable = false
            warningTypeLabel.isBordered = false
            
            let warningMessageLabel = NSTextField()
            warningMessageLabel.stringValue = errorMessage[row]
            warningMessageLabel.drawsBackground = false
            warningTypeLabel.isEditable = false
            warningMessageLabel.isBordered = false
            
            
            cell.addSubview(lineLabel)
            lineLabel.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                lineLabel.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
                lineLabel.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 8),
                lineLabel.widthAnchor.constraint(equalToConstant: CGFloat(24))
            ])
            
            cell.addSubview(warningTypeLabel)
            warningTypeLabel.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                warningTypeLabel.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
                warningTypeLabel.leadingAnchor.constraint(equalTo: lineLabel.trailingAnchor, constant: 16),
                warningTypeLabel.widthAnchor.constraint(equalToConstant: CGFloat(50))
            ])
            
            cell.addSubview(warningMessageLabel)
            warningMessageLabel.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                warningMessageLabel.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
                warningMessageLabel.leadingAnchor.constraint(equalTo: warningTypeLabel.trailingAnchor, constant: 16),
                warningMessageLabel.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -13)
            ])
            
            return cell
        } else {
            let text = NSTextField()
            text.stringValue = "No any lint warnings"
            let cell = NSTableCellView()
            cell.addSubview(text)
            text.drawsBackground = false
            text.isBordered = false
            text.translatesAutoresizingMaskIntoConstraints = false
            cell.addConstraint(NSLayoutConstraint(item: text, attribute: .centerY, relatedBy: .equal, toItem: cell, attribute: .centerY, multiplier: 1, constant: 0))
            cell.addConstraint(NSLayoutConstraint(item: text, attribute: .left, relatedBy: .equal, toItem: cell, attribute: .left, multiplier: 1, constant: 13))
            cell.addConstraint(NSLayoutConstraint(item: text, attribute: .right, relatedBy: .equal, toItem: cell, attribute: .right, multiplier: 1, constant: -13))
            return cell
        }
    }
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let rowView = NSTableRowView()
        rowView.isEmphasized = false
        return rowView
    }
}

class CustomTableHeaderView: NSTableHeaderView {
    let textField1 = NSTextField()
    let textField2 = NSTextField()
    let textField3 = NSTextField()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSubviews()
    }

    private func setupSubviews() {
        textField1.stringValue = "Line"
        textField2.stringValue = "Error type"
        textField3.stringValue = "Error message"

        textField1.isEditable = false
        textField2.isEditable = false
        textField3.isEditable = false
        textField1.drawsBackground = false
        textField1.isBordered = false
        textField2.drawsBackground = false
        textField2.isBordered = false
        textField3.drawsBackground = false
        textField3.isBordered = false

        // Размещение текстовых полей в headerView
        let stackView = NSStackView(views: [textField1, textField2, textField3])
        stackView.orientation = .horizontal
        stackView.alignment = .centerY
        stackView.spacing = 10

        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

