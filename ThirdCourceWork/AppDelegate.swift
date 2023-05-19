//
//  AppDelegate.swift
//  ThirdCourceWork
//
//  Created by Тимур Миргалиев on 25.01.2023.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet weak var projectSelectionMenuItem: NSMenuItem!
    @IBOutlet weak var buildTimesMenuItem: NSMenuItem!
    @IBOutlet weak var alwaysInFrontMenuItem: NSMenuItem!
    
    var viewController: ViewController? {
        return NSApplication.shared.mainWindow?.contentViewController as? ViewController
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        alwaysInFrontMenuItem.state = UserSettings.windowShouldBeTopMost ? .on : .off
    }
    
    func configureMenuItems(showBuildTimesMenuItem: Bool) {
        projectSelectionMenuItem.isEnabled = !showBuildTimesMenuItem
        buildTimesMenuItem.isEnabled = showBuildTimesMenuItem
    }
    
    // MARK: Actions
    
    @IBAction func navigateToProjectSelection(_ sender: NSMenuItem) {
        configureMenuItems(showBuildTimesMenuItem: true)
        
        viewController?.cancelProcessing()
        viewController?.showInstructions(true)
    }
    
    @IBAction func navigateToBuildTimes(_ sender: NSMenuItem) {
        configureMenuItems(showBuildTimesMenuItem: false)
        viewController?.showInstructions(false)
    }
    
    @IBAction func toggleAlwaysInFront(_ sender: NSMenuItem) {
        let alwaysInFront = sender.state == .off
        
        sender.state = alwaysInFront ? .on : .off
        UserSettings.windowShouldBeTopMost = alwaysInFront
        
        viewController?.makeWindowTopMost(topMost: alwaysInFront)
    }
}

