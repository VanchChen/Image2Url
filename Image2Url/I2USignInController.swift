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
    
    public weak var menuController : I2UMenuController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //载入数据
        if let appID = I2UUDKey.AppID.string() {
            AppIDTextField.stringValue = appID
        }
        
        if let region = I2UUDKey.Region.string() {
            RegionTextField.stringValue = region
        }
        
        if let bucket = I2UUDKey.Bucket.string() {
            BucketTextField.stringValue = bucket
        }
        
        if let key = I2UUDKey.SecretKey.string() {
            SecretKeyTextField.stringValue = key
        }
        
        if let id = I2UUDKey.SecretID.string() {
            SecretIDTextField.stringValue = id
        }
        
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        self.view.window!.title = "Sign In"
    }
    
    @IBAction func didTapCancel(_ sender: NSButton) {
        self.view.window!.close()
    }
    
    @IBAction func didTapConfirm(_ sender: NSButton) {
        if AppIDTextField.stringValue.count == 0 {
            AppIDTextField.becomeFirstResponder()
            return;
        }
        
        if RegionTextField.stringValue.count == 0 {
            RegionTextField.becomeFirstResponder()
            return;
        }
        
        if BucketTextField.stringValue.count == 0 {
            BucketTextField.becomeFirstResponder()
            return;
        }
        
        if SecretKeyTextField.stringValue.count == 0 {
            SecretKeyTextField.becomeFirstResponder()
            return;
        }
        
        if SecretIDTextField.stringValue.count == 0 {
            SecretIDTextField.becomeFirstResponder()
            return;
        }
        
        I2UUDKey.AppID.set(value: AppIDTextField.stringValue)
        I2UUDKey.Region.set(value: RegionTextField.stringValue)
        I2UUDKey.Bucket.set(value: BucketTextField.stringValue)
        I2UUDKey.SecretKey.set(value: SecretKeyTextField.stringValue)
        I2UUDKey.SecretID.set(value: SecretIDTextField.stringValue)
        
        I2UDataManager.shared.setup()
        
        menuController.signInMenuItem.title = "Sign Out"
        
        self.view.window!.close()
    }
}
