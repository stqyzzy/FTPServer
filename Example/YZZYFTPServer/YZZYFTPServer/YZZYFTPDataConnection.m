//
//  YZZYFTPDataConnection.m
//  YZZYFTPServer_Example
//
//  Created by 云中追月 on 2022/12/29.
//  Copyright © 2022 stqyzzy. All rights reserved.
//

#import "YZZYFTPDataConnection.h"
#import "YZZYFTPConnection.h"

@interface YZZYFTPDataConnection()

@end

@implementation YZZYFTPDataConnection

#pragma mark -
#pragma mark - life cycle - 生命周期
- (void)dealloc{
    NSLog(@"%@ - dealloc", NSStringFromClass([self class]));
}

- (instancetype)init{
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

#pragma mark -
#pragma mark - init setup - 初始化
- (void)setup{
    [self setDefault];//初始化默认数据
}

/// 设置默认数据
- (void)setDefault{
    
}

#pragma mark -
#pragma mark - public methods
- (instancetype)initWithAsyncSocket:(AsyncSocket *)newSocket forConnection:(id)aConnection withQueuedData:(NSMutableArray *)queuedData {
    if (self = [super init]) {
        self.dataSocket = newSocket;
        self.ftpConnection = aConnection;
        [self.dataSocket setDelegate:self];
        if (queuedData.count > 0) {
            if (g_XMFTP_LogEnabled) {
                XMFTPLog(@"FC:Write Queued Data");
            }
            // writeQueuedData
        }
    }
    return self;
}

#pragma mark -
#pragma mark - <#custom#> Delegate

#pragma mark -
#pragma mark - private methods
- (void)writeQueuedData:(NSMutableArray *)queuedData {
    for (NSMutableData *data in queuedData) {
        [self writeData:data];
    }
}

- (void)writeData:(NSMutableData *)data {
    if (g_XMFTP_LogEnabled) {
        XMFTPLog(@"FDC:writeData");
    }
    self.connectionState = YZZYFTPConnectionStateClientReceiving;
    [self.dataSocket writeData:data withTimeout:READ_TIMEOUT tag:FTP_CLIENT_REQUEST];
    [self.dataSocket readDataWithTimeout:READ_TIMEOUT tag:FTP_CLIENT_REQUEST];
}

- (void)writeString:(NSString *)dataString {
    if (g_XMFTP_LogEnabled) {
        XMFTPLog(@"FDC:writeStringData");
    }
    NSMutableData *data = [[dataString dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];
    // 拼接换行符
    [data appendData:[AsyncSocket CRLFData]];
    
    [self.dataSocket writeData:data withTimeout:READ_TIMEOUT tag:FTP_CLIENT_REQUEST];
    [self.dataSocket readDataWithTimeout:READ_TIMEOUT tag:FTP_CLIENT_REQUEST];
}


#pragma mark -
#pragma mark - getters and setters


@end
