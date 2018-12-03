//
//  I2UDataController.swift
//  Image2Url
//
//  Created by 陈文琦 on 2018/11/30.
//  Copyright © 2018 vanch. All rights reserved.
//

import Foundation

open class I2UDataManager {
    static var shared = I2UDataManager()

    func signIn() -> Bool {
        guard let appID = I2UUDKey.AppID.string() else {
            return false
        }
        guard let region = I2UUDKey.Region.string() else {
            return false
        }
        guard let bucket = I2UUDKey.Bucket.string() else {
            return false
        }
        guard let secretID = I2UUDKey.SecretID.string() else {
            return false
        }
        guard let secretKey = I2UUDKey.SecretKey.string() else {
            return false
        }
        
        let configuration = QCloudServiceConfiguration()
        configuration.appID = appID
        
        return false
    }
}
