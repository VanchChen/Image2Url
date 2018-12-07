//
//  I2UCompressUtility.swift
//  Image2Url
//
//  Created by 陈文琦 on 2018/12/7.
//  Copyright © 2018 vanch. All rights reserved.
//

import Foundation

class I2UCompressUtility {
    static let maxFactor = 0.75
    static let maxSize = 500 * 1024
    static let maxWidth : CGFloat = 1280.0
    
    open class func compressImage(_ imageData: Data?) throws -> Data? {
        guard var compressData = imageData else {
            throw CompressError.NoImage
        }
        
        if compressData.count == 0 {
            throw CompressError.NoImage
        }
        
        compressData = try compressRep(NSBitmapImageRep(data: compressData))
        if compressData.count < maxSize {
            return compressData
        }
        
        //resize
        guard let image = NSImage(data: imageData!) else {
            throw CompressError.NotKnown
        }
        if image.size.width > maxWidth {
            let newSize = NSSize(width: maxWidth, height: ceil(maxWidth / image.size.width * image.size.height))
            
            if let resizeData = image.resized(to: newSize) {
                compressData = try compressRep(NSBitmapImageRep(data: resizeData))
                if compressData.count < maxSize {
                    return compressData
                }
            }
            
            throw CompressError.ResizeNotWork
        }
        
        throw CompressError.OverSize(size: compressData.count)
    }
    
    class func compressRep(_ rep : NSBitmapImageRep?) throws -> Data {
        if rep == nil {
            throw CompressError.NotKnown
        }
        
        var compressData : Data
        var compressionFactor = 1.0
        repeat {
            let repData = rep!.representation(using: .jpeg, properties: [.compressionFactor : compressionFactor])
            if repData == nil {
                throw CompressError.NotKnown
            }
            compressData = repData!
            compressionFactor -= 0.05
        } while compressData.count > maxSize &&
            compressionFactor >= maxFactor
        
        if compressData.count == 0 {
            throw CompressError.NotKnown
        }
        
        return compressData
    }
}
