//
//  NSAlert.swift
//  ThirdCourceWork
//
//  Created by Тимур Миргалиев on 20.02.2023.
//

import Cocoa

extension NSAlert {
    static func show(withMessage message: String, andInformativeText informativeText: String = "") {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = informativeText
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
