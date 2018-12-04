//
//  NSTextField+I2U.swift
//  Image2Url
//
//  Created by 陈文琦 on 2018/12/3.
//  Copyright © 2018 vanch. All rights reserved.
//

import Foundation

extension NSTextField {
    override open func performKeyEquivalent(with event: NSEvent) -> Bool {
        let commandKey = NSEvent.ModifierFlags.command.rawValue
        let commandShiftKey = NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.shift.rawValue
        
        if event.type == NSEvent.EventType.keyDown {
            let key = event.modifierFlags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue
            if key == commandKey {
                switch event.charactersIgnoringModifiers! {
                case "x":
                    if NSApp.sendAction(#selector(NSText.cut(_:)), to:nil, from:self) { return true }
                case "c":
                    if NSApp.sendAction(#selector(NSText.copy(_:)), to:nil, from:self) { return true }
                case "v":
                    if NSApp.sendAction(#selector(NSText.paste(_:)), to:nil, from:self) { return true }
                case "z":
                    if NSApp.sendAction(Selector(("undo:")), to:nil, from:self) { return true }
                case "a":
                    if NSApp.sendAction(#selector(NSResponder.selectAll(_:)), to:nil, from:self) { return true }
                default:
                    break
                }
            } else if key == commandShiftKey {
                if event.charactersIgnoringModifiers == "Z" {
                    if NSApp.sendAction(Selector(("redo:")), to:nil, from:self) { return true }
                }
            }
        }
        
        return super.performKeyEquivalent(with: event)
    }
}

extension NSImage {
    func resized(to newSize: NSSize) -> Data? {
        if let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: Int(newSize.width), pixelsHigh: Int(newSize.height),
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0
            ) {
            bitmapRep.size = newSize
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
            draw(in: NSRect(x: 0, y: 0, width: newSize.width, height: newSize.height), from: .zero, operation: .copy, fraction: 1.0)
            NSGraphicsContext.restoreGraphicsState()

            return bitmapRep.tiffRepresentation(using: .jpeg, factor: 0.7)
        }

        return nil
    }
}
