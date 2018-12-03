//
//  I2UMenuController.swift
//  Image2Url
//
//  Created by 陈文琦 on 2018/11/15.
//  Copyright © 2018 vanch. All rights reserved.
//

import Cocoa

class I2UMenuController: NSObject {
    let maxPixelHeight = 1280
    let maxFactor = 0.8
    let maxSize = 500 * 1024
    
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
                var imageData : Data?
                do {
                    imageData = try Data(contentsOf: self.panel.url!)
                } catch _ {
                    imageData = nil
                }
                if imageData != nil && imageData!.count > 0 {
                    //self.handle(imageData: imageData!)
                    I2UDataManager.shared.uploadData(imageData! as NSData)
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
        panel.allowedFileTypes = Array(arrayLiteral: "jpg", "png", "jpeg")
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
    
    //MARK:- Image Handler
    func handle(imageData: Data) {
        guard let image = NSImage(data: imageData) else {
            return
        }
        
        if imageData.count < maxSize {
            self.upload2Cloud(image: image)
        }
        
        var imageSize = image.size
        if imageSize.height > 1280 {
            //如果高度大于1280，就缩小到这个尺寸
            imageSize.width = 1280 / imageSize.height * imageSize.width
            imageSize.height = 1280
        }
        
        guard let rep = NSBitmapImageRep.init(bitmapDataPlanes: nil,
                                        pixelsWide: Int(imageSize.width),
                                        pixelsHigh: Int(imageSize.height),
                                        bitsPerSample: 8,
                                        samplesPerPixel: 4,
                                        hasAlpha: true,
                                        isPlanar: false,
                                        colorSpaceName: NSColorSpaceName.calibratedRGB,
                                        bytesPerRow: 0,
                                        bitsPerPixel: 0) else {
                                            return;
        }
        
        guard let ctx = NSGraphicsContext.current?.cgContext else {
            return;
        }
        
        ctx.interpolationQuality = .high
        image.draw(in: NSMakeRect(0, 0, imageSize.width, imageSize.height),
                    from: NSMakeRect(0, 0, image.size.width, image.size.height),
                   operation: .copy, fraction: 1)
        
        let newImage = NSImage.init(size: imageSize)
        newImage.addRepresentation(rep)
        
        rep.representation(using: .jpeg, properties: Dictionary(dictionaryLiteral: (NSBitmapImageRep.PropertyKey.compressionFactor, 0.8)))
        
        
        /*
            // Compress by quality
            CGFloat compression = 1;
            NSData *data = UIImageJPEGRepresentation(self, compression);
            //NSLog(@"Before compressing quality, image size = %ld KB",data.length/1024);
            if (data.length < maxLength) return data;
            
            CGFloat max = 1;
            CGFloat min = 0;
            for (int i = 0; i < 6; ++i) {
                compression = (max + min) / 2;
                data = UIImageJPEGRepresentation(self, compression);
                //NSLog(@"Compression = %.1f", compression);
                //NSLog(@"In compressing quality loop, image size = %ld KB", data.length / 1024);
                if (data.length < maxLength * 0.9) {
                    min = compression;
                } else if (data.length > maxLength) {
                    max = compression;
                } else {
                    break;
                }
            }
            //NSLog(@"After compressing quality, image size = %ld KB", data.length / 1024);
            if (data.length < maxLength) return data;
            UIImage *resultImage = [UIImage imageWithData:data];
            // Compress by size
            NSUInteger lastDataLength = 0;
            while (data.length > maxLength && data.length != lastDataLength) {
                lastDataLength = data.length;
                CGFloat ratio = (CGFloat)maxLength / data.length;
                //NSLog(@"Ratio = %.1f", ratio);
                CGSize size = CGSizeMake((NSUInteger)(resultImage.size.width * sqrtf(ratio)),
                                         (NSUInteger)(resultImage.size.height * sqrtf(ratio))); // Use NSUInteger to prevent white blank
                UIGraphicsBeginImageContext(size);
                [resultImage drawInRect:CGRectMake(0, 0, size.width, size.height)];
                resultImage = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                data = UIImageJPEGRepresentation(resultImage, compression);
                //NSLog(@"In compressing size loop, image size = %ld KB", data.length / 1024);
            }
            //NSLog(@"After compressing size loop, image size = %ld KB", data.length / 1024);
 */
    }
    
    func upload2Cloud(image: NSImage) {
        
    }
}

