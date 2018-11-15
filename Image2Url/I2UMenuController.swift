//
//  I2UMenuController.swift
//  Image2Url
//
//  Created by 陈文琦 on 2018/11/15.
//  Copyright © 2018 vanch. All rights reserved.
//

import Cocoa

class I2UMenuController: NSObject {

    @IBOutlet weak var statusMenu: NSMenu!
    
    let statusItem = NSStatusBar.system.statusItem(withLength: 27)
    
    override func awakeFromNib() {
        let image = NSImage(named: NSImage.Name(rawValue: "Menu"))
        image?.isTemplate = true
        statusItem.button?.image = image
        statusItem.menu = statusMenu
    }
    
    @IBAction func didTapQuit(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }
}
