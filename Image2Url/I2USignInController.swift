//
//  I2USignInController.swift
//  Image2Url
//
//  Created by 陈文琦 on 2018/11/27.
//  Copyright © 2018 vanch. All rights reserved.
//

import Cocoa

class I2USignInController : NSViewController {
    @IBOutlet weak var AppIDTextField: NSTextField!
    @IBOutlet weak var RegionTextField: NSTextField!
    @IBOutlet weak var BucketTextField: NSTextField!
    @IBOutlet weak var SecretKeyTextField: NSTextField!
    @IBOutlet weak var SecretIDTextField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        self.view.window!.title = "Sign In"
    }
    
    @IBAction func didTapCancel(_ sender: NSButton) {
        self.view.window!.close()
    }
    
    @IBAction func didTapConfirm(_ sender: NSButton) {
    }
}
