//
//  QCloudCOSXMLCopyObjectRequest.m
//  QCloudCOSXML
//
//  Created by erichmzhang(张恒铭) on 16/11/2017.
//

#import "QCloudCOSXMLCopyObjectRequest.h"
#import "QCloudCOSXMLService.h"
#import "QCloudCOSXMLService+Transfer.h"
#import "QCloudPutObjectRequest.h"
#import "QCloudMultipartInfo.h"
#import "QCloudCOSXMLTransfer.h"
#import "QCloudCompleteMultipartUploadRequest.h"
#import "QCloudCompleteMultipartUploadInfo.h"
#import "QCloudHeadObjectRequest.h"
#import "QCloudURLHelper.h"
static NSString* const kTempServiceKey =   @"tempServiceKey";
static NSString* const kContentLengthKey = @"Content-Length";
static NSString* const kLastModifiedKey =  @"Last-Modified";
static const int64_t   kMultipartThreshold = 5242880;
static const int64_t   kCopySliceLength    = 5242880;

@interface QCloudCOSXMLCopyObjectRequest()
@property (nonatomic, assign) int64_t fileSize;
@property (nonatomic, assign) int64_t sliceCount;
@property (nonatomic, strong) dispatch_source_t dispatchSource;
@property (nonatomic, copy) NSString* uploadID;
@property (nonatomic, strong) NSMutableArray* uploadParts;
@property (nonatomic, copy) NSString* lastModified;
@property (nonatomic, copy) CopyProgressBlock copyProgressBlock;
@end

@implementation QCloudCOSXMLCopyObjectRequest

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    _fileSize = 0;
    _sliceCount = 0;
    return self;
}

- (void)fackStart {
    QCloudHeadObjectRequest* headObjectRequest = [[QCloudHeadObjectRequest alloc] init];
    headObjectRequest.bucket = self.sourceBucket;
    headObjectRequest.object = self.sourceObject;
    headObjectRequest.ifModifiedSince = self.objectCopyIfModifiedSince;
    __weak typeof(self) weakSelf = self;
    [headObjectRequest setFinishBlock:^(id outputObject, NSError* error) {
        if (error) {
            if (self.finishBlock) {
                self.finishBlock(nil, error);
            }
        } else {
            NSDictionary* resultDictionray = (NSDictionary*)outputObject;
            int64_t fileSize = [resultDictionray[kContentLengthKey] longLongValue];
            weakSelf.lastModified = resultDictionray[kLastModifiedKey];
            if (fileSize > kMultipartThreshold) {
                weakSelf.sliceCount = fileSize / kCopySliceLength;
                if (fileSize % kCopySliceLength != 0) {
                    weakSelf.sliceCount++;
                }
                weakSelf.fileSize = fileSize;
                [weakSelf multipleCopy];
            } else {
                [weakSelf simpleCopy];
            }
        }
    }];
    QCloudCOSXMLService* service = [self tempService];
    [service HeadObject:headObjectRequest];
}

- (void)simpleCopy {
    QCloudPutObjectCopyRequest* request = [[QCloudPutObjectCopyRequest alloc] init];
    request.bucket = self.bucket;
    request.object = self.object;
    request.objectCopyIfMatch = self.objectCopyIfMatch;
    request.objectCopyIfNoneMatch = self.objectCopyIfNoneMatch;
    request.objectCopyIfModifiedSince = self.objectCopyIfModifiedSince;
    request.objectCopyIfUnmodifiedSince = self.objectCopyIfUnmodifiedSince;
    request.accessControlList = self.accessControlList;
    request.grantRead = self.grantRead;
    request.grantWrite = self.grantWrite;
    request.grantFullControl = self.grantFullControl;
    QCloudCOSXMLService* service = [self tempService];
    [request setFinishBlock:self.finishBlock];
    NSMutableString* objectCopySource = [NSMutableString string];
    NSString* serviceURL =[service.configuration.endpoint serverURLWithBucket:self.sourceBucket appID:self.sourceAPPID].absoluteString;
    [objectCopySource appendString:[serviceURL componentsSeparatedByString:@"://"][1]];
    [objectCopySource appendFormat:@"/%@",QCloudPercentEscapedStringFromString(self.sourceObject)];
    request.objectCopySource = objectCopySource;
    QCloudLogDebug(@"Object copy source url %@", objectCopySource);
    [[QCloudCOSXMLService defaultCOSXML] PutObjectCopy:request];
}

- (void)multipleCopy {
    QCloudInitiateMultipartUploadRequest* initMultipartUploadRequest = [[QCloudInitiateMultipartUploadRequest alloc] init];
    initMultipartUploadRequest.bucket = self.bucket;
    initMultipartUploadRequest.object = self.object;
    initMultipartUploadRequest.customHeaders = self.customHeaders;
    __weak typeof(self) weakSelf = self;
    [initMultipartUploadRequest setFinishBlock:^(QCloudInitiateMultipartUploadResult* result, NSError* error) {
        if (nil == error) {
            weakSelf.uploadID = result.uploadId;
            [weakSelf uploadCopyParts];
        } else {
            if (weakSelf.finishBlock) {
                weakSelf.finishBlock(nil, error);
            }
        }
    }];
    
    [[QCloudCOSXMLService defaultCOSXML] InitiateMultipartUpload:initMultipartUploadRequest];
    
}

- (void)uploadCopyParts {
    QCloudCOSXMLService* service = [self tempService];
    __weak typeof(self) weakSelf = self;
    self.dispatchSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_ADD,
                                                 0,
                                                 0,
                                                 dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
    __block int64_t totalComplete = 0;
    dispatch_source_set_event_handler(self.dispatchSource, ^{
        NSUInteger value = dispatch_source_get_data(weakSelf.dispatchSource);
        totalComplete += value;
        if (weakSelf.copyProgressBlock) {
            weakSelf.copyProgressBlock(totalComplete, weakSelf.sliceCount);
        }
        if (totalComplete == self.sliceCount) {
            [weakSelf finishUploadParts];
            dispatch_source_cancel(weakSelf.dispatchSource);
        }
    });
    dispatch_resume(self.dispatchSource);
    for (int64_t i = 0; i*kCopySliceLength < self.fileSize; i++ ) {
        @autoreleasepool {
            QCloudUploadPartCopyRequest* request = [[QCloudUploadPartCopyRequest alloc] init];
            request.bucket = self.bucket;
            request.object = self.object;
            NSMutableString* objectCopySource = [NSMutableString string];
            NSString* serviceURL =[service.configuration.endpoint serverURLWithBucket:self.sourceBucket appID:self.sourceAPPID].absoluteString;
            [objectCopySource appendString:[serviceURL componentsSeparatedByString:@"://"][1]];
            [objectCopySource appendFormat:@"/%@",QCloudPercentEscapedStringFromString(self.sourceObject)];
            request.source = objectCopySource;
            request.uploadID = self.uploadID;
            request.partNumber = i+1;
            request.priority = QCloudAbstractRequestPriorityLow;
            int64_t currentOffset = i * kCopySliceLength;
            int64_t sliceLength = MIN(self.fileSize - currentOffset, kCopySliceLength);
            
            request.sourceRange = [self copySourceRangeWithFirst:currentOffset last:sliceLength + currentOffset - 1];
            __weak typeof(self) weakSelf = self;
            [request setFinishBlock:^(QCloudCopyObjectResult* result, NSError* error) {
                if (error) {
                    [weakSelf onError:error];
                    [weakSelf cancel];
                } else {
                    
                    QCloudMultipartInfo* info = [[QCloudMultipartInfo alloc] init];
                    info.eTag = result.eTag;
                    info.partNumber = [@(i+1) stringValue];
                    [weakSelf markPartFinish:info];
                    
                    dispatch_source_merge_data(weakSelf.dispatchSource, 1);
                }
            }];
            
            [self.transferManager.cosService UploadPartCopy:request];
        }
    }
}

- (void)cancel {
    
}

- (void)finishUploadParts {
    QCloudCompleteMultipartUploadRequest* request = [[QCloudCompleteMultipartUploadRequest alloc] init];
    request.bucket = self.bucket;
    request.object = self.object;
    request.uploadId = self.uploadID;
    QCloudCompleteMultipartUploadInfo* info = [[QCloudCompleteMultipartUploadInfo alloc ] init];
    [self.uploadParts sortUsingComparator:^NSComparisonResult(QCloudMultipartInfo* obj1, QCloudMultipartInfo* obj2) {
        if (obj1.partNumber.longLongValue > obj2.partNumber.longLongValue) {
            return NSOrderedDescending;
        } else {
            return NSOrderedAscending ;
        }
    }];
    info.parts = self.uploadParts;
    request.parts = info;
    __weak typeof(self) weakSelf = self;
    [request setFinishBlock:^(QCloudUploadObjectResult* result, NSError* error) {
        if (nil == error) {
            QCloudCopyObjectResult* copyResult = [[QCloudCopyObjectResult alloc] init];
            copyResult.eTag = result.eTag;
            copyResult.lastModified = self.lastModified;
            if (weakSelf.finishBlock) {
                weakSelf.finishBlock(copyResult, error);
            }
        } else {
            if (weakSelf.finishBlock) {
                weakSelf.finishBlock(nil, error);
            }
        }
    }];
    [[QCloudCOSXMLService defaultCOSXML] CompleteMultipartUpload:request];
}

- (QCloudCOSXMLService*)tempService {
    static dispatch_once_t onceToken;
    static QCloudCOSXMLService* service ;
    dispatch_once(&onceToken, ^{
        QCloudServiceConfiguration* configuration = [QCloudServiceConfiguration new];
        configuration.signatureProvider = self.transferManager.configuration.signatureProvider;
        configuration.appID = self.sourceAPPID;
        QCloudCOSXMLEndPoint* endpoint = [[QCloudCOSXMLEndPoint alloc] init];
        endpoint.regionName = self.sourceRegion;
        endpoint.serviceName = self.transferManager.configuration.endpoint.serviceName;
        endpoint.useHTTPS = self.transferManager.configuration.endpoint.useHTTPS;
        configuration.endpoint = endpoint;
        service = [QCloudCOSXMLService registerCOSXMLWithConfiguration:configuration withKey:kTempServiceKey];
    });
    return service;
}

- (void) setFinishBlock:(void (^)(QCloudCopyObjectResult* result, NSError * error))QCloudRequestFinishBlock {
    [super setFinishBlock:QCloudRequestFinishBlock];
}

- (NSString*)copySourceRangeWithFirst:(int64_t)first last:(int64_t)last {
    NSString* result = [NSString stringWithFormat:@"bytes=%lld-%lld",first,last];
    return result;
}

- (void) markPartFinish:(QCloudMultipartInfo*)info {
    if (!info) {
        return;
    }
    [self.uploadParts addObject:info];
}


- (NSMutableArray*)uploadParts {
    if (!_uploadParts) {
        _uploadParts = [NSMutableArray array];
    }
    return _uploadParts;
}
- (void)setCopyProgressBlock:(void (^)(int64_t, int64_t))copyProgressBlock {
    self.copyProgressBlock = copyProgressBlock;
}

@end
