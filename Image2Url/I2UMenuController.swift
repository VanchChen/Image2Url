//
//  I2UMenuController.swift
//  Image2Url
//
//  Created by 陈文琦 on 2018/11/15.
//  Copyright © 2018 vanch. All rights reserved.
//

import Cocoa

class I2UMenuController: NSObject {
    let maxFactor = 0.75
    let maxSize = 500 * 1024
    let maxWidth : CGFloat = 128.0
    
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var compressMenuItem: NSMenuItem!
    @IBOutlet weak var signInMenuItem: NSMenuItem!
    
    let statusItem = NSStatusBar.system.statusItem(withLength: 27)
    let panel = NSOpenPanel()

    //MARK:- Life Circle
    override func awakeFromNib() {
        self.setupPanel()
        
        self.setupUserData()
        
        self.setupUI()
    }
    
    //MARK:- Action Methods
    @IBAction func didTapQuit(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }
    
    @IBAction func didTapSignIn(_ sender: NSMenuItem) {
        if I2UUDKey.Login.bool() {
            //Sign Out
            I2UUDKey.Login.clearSettings()
            I2UUDKey.Login.set(value: false)
            signInMenuItem.title = "Sign In"
            
            return
        }
        
        guard let storyBoard = NSStoryboard.main else {
            return;
        }
        
        let signInWindowController = storyBoard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("SignInWindowController")) as! NSWindowController
        signInWindowController.window!.orderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        let signInViewController = signInWindowController.window?.contentViewController as! I2USignInController
        signInViewController.menuController = self
    }
    
    @IBAction func didTapCompress(_ sender: NSMenuItem) {
        let isCompress = !I2UUDKey.Compress.bool()
        I2UUDKey.Compress.set(value: isCompress)
        compressMenuItem.state = isCompress ? NSControl.StateValue.on : NSControl.StateValue.off
    }
    
    @IBAction func didTapUpload(_ sender: NSMenuItem) {
        panel.beginSheetModal(for: NSApplication.shared.windows.first!) { response -> Void in
            if response.rawValue == 1 {
                let imageData = try? Data(contentsOf: self.panel.url!)
                
                var compressData : Data? = nil
                if I2UUDKey.Compress.bool() == false {
                    compressData = imageData
                } else {
                    do {
                        compressData = try self.compressImage(imageData)
                    } catch CompressError.NoImage {
                        print("Image Not Exist")
                    } catch CompressError.NotKnown {
                        print("Image Compress Error")
                    } catch CompressError.OverSize(let size) {
                        print("Image over size of \(size)")
                    } catch CompressError.ResizeNotWork {
                        print("Image resize not work")
                    } catch _ {}
                }
                
                if compressData != nil && compressData!.count > 0 {
                    I2UDataManager.shared.uploadData(compressData! as NSData)
                }
            }
        }
    }
    
    @IBAction func didTapAboutMe(_ sender: NSMenuItem) {
        NSApplication.shared.orderFrontStandardAboutPanel(sender)
    }
    
    //MARK:- Worker Methods
    func setupPanel() {
        let image = NSImage(named: NSImage.Name(rawValue: "Menu"))
        image?.isTemplate = true
        statusItem.button?.image = image
        statusItem.menu = statusMenu
        
        panel.message = "Choose an image"
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.allowedFileTypes = ["jpg", "png", "jpeg"]
    }
    
    func setupUserData() {
        if I2UUDKey.Setup.bool() == false {
            I2UUDKey.Setup.set(value: true)
            I2UUDKey.Compress.set(value: true)
            return
        }
        
        I2UDataManager.shared.setup()
    }
    
    func setupUI() {
        let isCompress = I2UUDKey.Compress.bool()
        compressMenuItem.state = isCompress ? NSControl.StateValue.on : NSControl.StateValue.off
        
        if I2UUDKey.Login.bool() {
            signInMenuItem.title = "Sign Out"
        } else {
            signInMenuItem.title = "Sign In"
        }
    }
    
    //MARK:- Compress Image
    func compressImage(_ imageData: Data?) throws -> Data? {
        guard var compressData = imageData else {
            throw CompressError.NoImage
        }
        
        if compressData.count == 0 {
            throw CompressError.NoImage
        }
        
        let rep = NSBitmapImageRep(data: compressData)
        
        var compressionFactor = 0.95
        while compressData.count > maxSize &&
            compressionFactor >= maxFactor {
                let repData = rep?.representation(using: .jpeg, properties: [.compressionFactor : compressionFactor])
                if repData == nil {
                    throw CompressError.NotKnown
                }
                compressData = repData!
                compressionFactor -= 0.05
        }
        
        if compressData.count == 0 {
            throw CompressError.NotKnown
        }
        
        if compressData.count < maxSize {
            return compressData
        }
        
        //resize
        guard let image = NSImage(data: compressData) else {
            throw CompressError.NotKnown
        }
        if image.size.width > maxWidth {
            let newSize = NSSize(width: maxWidth, height: maxWidth / image.size.width * image.size.height)
            
            if let resizeData = image.resized(to: newSize),
                resizeData.count < maxSize {
                return resizeData
            }
            
            throw CompressError.ResizeNotWork
        }
        
        throw CompressError.OverSize(size: compressData.count)
    }
}

