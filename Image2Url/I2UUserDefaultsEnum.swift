//
//  I2UUserDefaultsEnum.swift
//  Image2Url
//
//  Created by 陈文琦 on 2018/11/30.
//  Copyright © 2018 vanch. All rights reserved.
//

import Foundation

enum I2UUDKey : String {
    case Compress, Setup, AppID, Region, Bucket, SecretKey, SecretID
    
    func set(value : Bool) {
        UserDefaults.standard.set(value, forKey: self.rawValue)
    }
    
    func set(value : String?) {
        UserDefaults.standard.set(value, forKey: self.rawValue)
    }
    
    func bool() -> Bool {
        return UserDefaults.standard.bool(forKey: self.rawValue)
    }
    
    func string() -> String? {
        return UserDefaults.standard.string(forKey: self.rawValue)
    }
}
