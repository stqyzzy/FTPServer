//
//  YZZYFTPDataConnection.m
//  YZZYFTPServer_Example
//
//  Created by 云中追月 on 2022/12/29.
//  Copyright © 2022 stqyzzy. All rights reserved.
//

#import "YZZYFTPDataConnection.h"
#import "YZZYFTPConnection.h"

@interface YZZYFTPDataConnection()<AsyncSocketDelegate>
@property (nonatomic, strong, readwrite) NSMutableData *receivedData;

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
            [self writeQueuedData:[queuedData copy]];
            [queuedData removeAllObjects]; // 清理缓存数据
        }
        [self.dataSocket readDataWithTimeout:READ_TIMEOUT tag:FTP_CLIENT_REQUEST];
        self.dataListeningSocket = nil;
        self.receivedData = nil;
        self.connectionState = YZZYFTPConnectionStateClientQuiet;
    }
    return self;
}

- (void)writeData:(NSMutableData *)data {
    if (g_XMFTP_LogEnabled) {
        XMFTPLog(@"FDC:writeData");
    }
    self.connectionState = YZZYFTPConnectionStateClientReceiving;
    [self.dataSocket writeData:data withTimeout:READ_TIMEOUT tag:FTP_CLIENT_REQUEST];
    [self.dataSocket readDataWithTimeout:READ_TIMEOUT tag:FTP_CLIENT_REQUEST];
}

- (void)closeConnection {
    if (g_XMFTP_LogEnabled) {
        XMFTPLog(@"FDC:closeConnection");;
    }
    [self.dataSocket disconnect];
}
#pragma mark -
#pragma mark - ASYNCSOCKET Delegate
-(BOOL)onSocketWillConnect:(AsyncSocket *)sock {
    if (g_XMFTP_LogEnabled) {
        XMFTPLog(@"FDC:onSocketWillConnect");
    }
    [self.dataSocket readDataWithTimeout:READ_TIMEOUT tag:0];
    return YES;
}

- (void)onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket {
    // 这不应该发生 - 我们应该已经连接 - 并且没有设置侦听套接字
    if (g_XMFTP_LogEnabled) {
        XMFTPLog(@"FDC:New Connection -- shouldn't be called");
    }
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    if (g_XMFTP_LogEnabled) {
        XMFTPLog(@"FDC:didReadData");;
    }
    [self.dataSocket readDataWithTimeout:READ_TIMEOUT tag:FTP_CLIENT_REQUEST];
    self.receivedData = [data mutableCopy];
    // 通知连接数据通过，通知连接，让它知道去写文件
    [self.ftpConnection didReceiveDataRead];
    self.connectionState = YZZYFTPConnectionStateClientSent;
}



#pragma mark -
#pragma mark - private methods
- (void)writeQueuedData:(NSArray *)queuedData {
    for (NSMutableData *data in queuedData) {
        [self writeData:data];
    }
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
