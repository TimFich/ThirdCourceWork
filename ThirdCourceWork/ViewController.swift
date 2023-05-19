//
//  ViewController.swift
//  ThirdCourceWork
//
//  Created by Тимур Миргалиев on 25.01.2023.
//

import Cocoa

class ViewController: NSViewController {
    
    // UI
    @IBOutlet var buildManager: BuildManager!
    @IBOutlet weak var cancelButton: NSButton!
    @IBOutlet weak var derivedDataTextField: NSTextField!
    @IBOutlet weak var instructionsView: NSView!
    @IBOutlet weak var leftButton: NSButton!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var projectSelection: ProjectSelection!
    @IBOutlet weak var searchField: NSSearchField!
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var statusTextField: NSTextField!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var tableViewContainerView: NSScrollView!
    
    // Properties
    private let dataSource = ViewControllerDataSource()
    private var currentKey: String?
    private var nextDatabase: XcodeDatabase?
    private let lintWorker = LintWorker()
    private var processor = LogProcessor()
    
    var processingState: ProcessingState = .waiting {
        didSet {
            updateViewForState()
        }
    }
    
    // MARK: - View life cyrcle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource.aggregateByFile = true
        tableView.reloadData()
        configureLayout()
        
        buildManager.delegate = self
        projectSelection.delegate = self
        projectSelection.listFolders()
        
        tableView.tableColumns[0].sortDescriptorPrototype = NSSortDescriptor(key: CompileMeasure.Order.time.rawValue, ascending: true)
        tableView.tableColumns[1].sortDescriptorPrototype = NSSortDescriptor(key: CompileMeasure.Order.filename.rawValue, ascending: true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(windowWillClose(notification:)), name: NSWindow.willCloseNotification, object: nil)
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        makeWindowTopMost(topMost: false)
    }
    
    @objc
    func windowWillClose(notification: NSNotification) {
        guard let object = notification.object, !(object is NSPanel) else { return }
        NotificationCenter.default.removeObserver(self)
        
        processor.shouldCancel = true
        NSApp.terminate(self)
    }
    
    func configureLayout() {
        updateViewForState()
        showInstructions(true)
        
        derivedDataTextField.stringValue = UserSettings.derivedDataLocation
        makeWindowTopMost(topMost: UserSettings.windowShouldBeTopMost)
    }
    
    func showInstructions(_ show: Bool) {
        instructionsView.isHidden = !show
        
        let views: [NSView] = [leftButton, searchField, statusLabel, statusTextField, tableViewContainerView]
        views.forEach{ $0.isHidden = show }
        
        if show && processingState == .processing {
            processor.shouldCancel = true
            cancelButton.isHidden = true
            progressIndicator.isHidden = true
        }
    }
    
    func updateViewForState() {
        switch processingState {
        case .processing:
            showInstructions(false)
            progressIndicator.isHidden = false
            progressIndicator.startAnimation(self)
            statusTextField.stringValue = ProcessingState.processingString
            cancelButton.isHidden = false
            
        case .completed(_, let stateName):
            progressIndicator.isHidden = true
            progressIndicator.stopAnimation(self)
            statusTextField.stringValue = stateName
            cancelButton.isHidden = true
            
        case .waiting:
            progressIndicator.isHidden = true
            progressIndicator.stopAnimation(self)
            statusTextField.stringValue = ProcessingState.waitingForBuildString
            cancelButton.isHidden = true
        }
        
        if instructionsView.isHidden {
            searchField.isHidden = !cancelButton.isHidden
        }
    }
    
    func makeWindowTopMost(topMost: Bool) {
        if let window = NSApplication.shared.windows.first {
            let level: CGWindowLevelKey = topMost ? .floatingWindow : .normalWindow
            window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(level)))
        }
    }
    
    // MARK: - Actions
    
    @IBAction func clipboardButtonClicked(_ sender: AnyObject) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects(["-Xfrontend -debug-time-function-bodies" as NSPasteboardWriting])
    }
    
    @IBAction func visitDerivedData(_ sender: AnyObject) {
        NSWorkspace.shared.openFile(derivedDataTextField.stringValue)
    }
    
    
    @IBAction func cancelButtonClicked(_ sender: AnyObject) {
        processor.shouldCancel = true
    }
    
    @IBAction func leftButtonClicked(_ sender: NSButton) {
        configureMenuItems(showBuildTimesMenuItem: true)
        
        cancelProcessing()
        showInstructions(true)
        projectSelection.listFolders()
    }
    
    func controlTextDidChange(_ obj: Notification) {
        if let field = obj.object as? NSSearchField, field == searchField {
            dataSource.filter = searchField.stringValue
            tableView.reloadData()
        } else if let field = obj.object as? NSTextField, field == derivedDataTextField {
            buildManager.stopMonitoring()
            UserSettings.derivedDataLocation = field.stringValue
            
            projectSelection.listFolders()
            buildManager.startMonitoring()
        }
    }
    
    // MARK: - Utilities
    
    func cancelProcessing() {
        guard processingState == .processing else { return }
        
        processor.shouldCancel = true
        cancelButton.isHidden = true
    }
    
    func configureMenuItems(showBuildTimesMenuItem: Bool) {
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.configureMenuItems(showBuildTimesMenuItem: showBuildTimesMenuItem)
        }
    }
    
    func processLog(with database: XcodeDatabase) {
        guard processingState != .processing else {
            if let currentKey = currentKey, currentKey != database.key {
                nextDatabase = database
                processor.shouldCancel = true
            }
            return
        }
        
        configureMenuItems(showBuildTimesMenuItem: false)
        
        processingState = .processing
        currentKey = database.key
        
        processor.processDatabase(database: database) { [weak self] (result, didComplete, didCancel) in
            self?.handleProcessorUpdate(result: result, didComplete: didComplete, didCancel: didCancel)
        }
    }
    
    func handleProcessorUpdate(result: [CompileMeasure], didComplete: Bool, didCancel: Bool) {
        dataSource.resetSourceData(newSourceData: result)
        tableView.reloadData()
        
        if didComplete {
            completeProcessorUpdate(didCancel: didCancel)
        }
    }
    
    func completeProcessorUpdate(didCancel: Bool) {
        let didSucceed = !dataSource.isEmpty()
        
        var stateName = ProcessingState.failedString
        if didCancel {
            stateName = ProcessingState.cancelledString
        } else if didSucceed {
            stateName = ProcessingState.completedString
        }
        
        processingState = .completed(didSucceed: didSucceed, stateName: stateName)
        currentKey = nil
        
        if let nextDatabase = nextDatabase {
            self.nextDatabase = nil
            processLog(with: nextDatabase)
        }
        
        if !didSucceed {
            let text = "Ensure the Swift compiler flags has been added."
            NSAlert.show(withMessage: ProcessingState.failedString, andInformativeText: text)
            
            showInstructions(true)
            configureMenuItems(showBuildTimesMenuItem: true)
        }
    }
}

// MARK: - NSTableViewDataSource

extension ViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return dataSource.count()
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        
        
        let output = lintWorker.makeLintFile(path: dataSource.measure(index: row)?.path)
        
        
        let detailsView = LintViewController()
        detailsView.dataSource = output
        
        presentAsModalWindow(detailsView)
        return true
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        
    }
}

// MARK: - NSTableViewDelegate

extension ViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let tableColumn = tableColumn, let columnIndex = tableView.tableColumns.firstIndex(of: tableColumn) else { return nil }
        guard let item = dataSource.measure(index: row) else { return nil }
        
        let result = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "Cell\(columnIndex)"), owner: self) as? NSTableCellView
        result?.textField?.stringValue = item[columnIndex]
        
        return result
    }
    
    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        dataSource.sortDescriptors = tableView.sortDescriptors
        tableView.reloadData()
    }
}

// MARK: - BuildManagerDelegate

extension ViewController: BuildManagerDelegate {
    func buildManager(_ buildManager: BuildManager, shouldParseLogWithDatabase database: XcodeDatabase) {
        processLog(with: database)
    }
    
    func derivedDataDidChange() {
        projectSelection.listFolders()
    }
}

// MARK: - ProjectSelectionDelegate

extension ViewController: ProjectSelectionDelegate {
    func didSelectProject(with database: XcodeDatabase) {
        processLog(with: database)
    }
}
