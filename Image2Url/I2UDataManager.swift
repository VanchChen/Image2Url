//
//  I2UDataController.swift
//  Image2Url
//
//  Created by 陈文琦 on 2018/11/30.
//  Copyright © 2018 vanch. All rights reserved.
//

import Foundation

open class I2UDataManager : NSObject, QCloudSignatureProvider {
    
    static let shared = I2UDataManager()
    
    public func setup() {
        //Attamp 2 sign in
        I2UUDKey.Login.set(value: self.signIn())
    }
    
    public func signIn() -> Bool {
        guard let appID = I2UUDKey.AppID.string() else {
            return false
        }
        guard let region = I2UUDKey.Region.string() else {
            return false
        }
        guard I2UUDKey.Bucket.string() != nil else {
            return false
        }
        guard I2UUDKey.SecretID.string() != nil else {
            return false
        }
        guard I2UUDKey.SecretKey.string() != nil else {
            return false
        }
        
        //设置
        let configuration = QCloudServiceConfiguration()
        configuration.signatureProvider = self
        configuration.appID = appID
        let endPoint = QCloudCOSXMLEndPoint()
        endPoint.regionName = region
        configuration.endpoint = endPoint
        
        QCloudCOSXMLService.registerDefaultCOSXML(with: configuration)
        QCloudCOSTransferMangerService.registerDefaultCOSTransferManger(with: configuration)
        
        return true
    }
    
    public func signature(with fileds: QCloudSignatureFields!, request: QCloudBizHTTPRequest!, urlRequest urlRequst: NSMutableURLRequest!, compelete continueBlock: QCloudHTTPAuthentationContinueBlock!) {
        guard let secretID = I2UUDKey.SecretID.string() else {
            return
        }
        guard let secretKey = I2UUDKey.SecretKey.string() else {
            return
        }
        
        let credential = QCloudCredential()
        credential.secretID = secretID
        credential.secretKey = secretKey
        let creator = QCloudAuthentationV5Creator(credential: credential)
        let signature = creator?.signature(forData: urlRequst)
        continueBlock(signature, nil)
    }
    
    public func uploadData(_ data: NSData) {
        guard let bucket = I2UUDKey.Bucket.string() else {
            return
        }
        
        let put = QCloudCOSXMLUploadObjectRequest<NSData>()
        put.object = "a.jpg"
        put.bucket = bucket
        put.body = data
        put.sendProcessBlock = {(bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) in
            print("Sent:\(bytesSent) total:\(totalBytesSent) expect:\(totalBytesExpectedToSend)")
        }
        put.finishBlock = {(outputObject: Any?, error: Error?) in
            if outputObject != nil {
                print("uploadSuccess:\(outputObject ?? "nil")")
            }
        }
        QCloudCOSTransferMangerService.defaultCOSTransferManager().uploadObject(put as! QCloudCOSXMLUploadObjectRequest<AnyObject>)
    }
}
