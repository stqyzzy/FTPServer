//
//  YZZYFTPConnection.m
//  YZZYFTPServer_Example
//
//  Created by 云中追月 on 2022/12/27.
//  Copyright © 2022 stqyzzy. All rights reserved.
//

#import "YZZYFTPConnection.h"
#import "YZZYFTPDefines.h"
#include <sys/time.h>

@interface YZZYFTPConnection()

@end

@implementation YZZYFTPConnection

#pragma mark -
#pragma mark - life cycle - 生命周期
- (void)dealloc{
    if (_connectionSocket) {
        [self.connectionSocket setDelegate:nil];
        [self.connectionSocket disconnect];
    }
    
    if (_dataListeningSocket) {
        [self.dataListeningSocket setDelegate:nil];
        [self.dataListeningSocket disconnect];
    }
    
    if (_dataSocket) {
        [self.dataSocket setDelegate:nil];
        [self.dataSocket disconnect];
    }
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
// 初始化方法
- (instancetype)initWithAsyncSocket:(AsyncSocket*)newSocket forServer:(YZZYFTPServer *)myServer {
    if (self = [super init]) {
        self.connectionSocket = newSocket;
        self.server = myServer;
        self.connectionSocket.delegate = self;
        // 向客户端发送欢迎消息
        [self.connectionSocket writeData:DATASTR(@"220 iosFtp server ready.\r\n") withTimeout:-1 tag:0];
        // 开始监听客户端当前连接的命令
        [self.connectionSocket readDataToData:[AsyncSocket CRLFData] withTimeout:READ_TIMEOUT tag:FTP_CLIENT_REQUEST];
        self.dataListeningSocket = nil;
        self.dataPort = 2001;
        self.transferMode = YZZYFTPTransferModePASVFTP;
        self.queuedDataMutableArray = [[NSMutableArray alloc] init];
        self.currentDirString = [self.server.baseDirString copy]; // 此连接的工作目录，在服务器设置为的目录中启动。 在服务器代码中将 chroot=true 设置为沙盒
        self.currentFileString = nil;
        self.currentFileHandle = nil;
        self.rnfrFilenameString = nil;
        self.currentUserString = nil;
        
        if (g_XMFTP_LogEnabled) {
            XMFTPLog(@"FC: Current Directory starting at %@", self.currentDirString);
        }
        
    }
    return self;
}

// STATE
- (NSString *)connectionAddress {
    return self.connectionSocket.connectedHost;
}


// CHOOSE DATA SOCKET
// FDC 读取数据（即传输）的通知
- (void)didReceiveDataRead {
    // 必须发送一个文件

}

// ASYNCSOCKET FTPCLIENT CONNECTION
// 来自FtpDataConnection的通知，表明数据已写入
- (void)didReceiveDataWritten {
    
}

- (void)didFinishReading {
    
}
#pragma mark -
#pragma mark - <#custom#> Delegate

#pragma mark -
#pragma mark - private methods
// ASYNCSOCKET DATACONN CHOOSE DataSocekt
- (BOOL)openDataSocket:(UInt16)portNumber {
    NSString *responseString;
    NSError *error = nil;
    if (self.dataSocket) {
        // Socket和连接有内存泄露
        self.dataSocket = nil;
    }
    // 创建一个Socket对象
    self.dataSocket = [[AsyncSocket alloc] initWithDelegate:self];
    if (self.dataConnection) {
        self.dataConnection = nil;
    }
    switch (self.transferMode) {
        case YZZYFTPTransferModePORTFTP:
            self.dataPort = portNumber;
            responseString = [NSString stringWithFormat:@"200 PORT command successful."];
            // 连接到Server
            [self.dataSocket connectToHost:[self connectionAddress] onPort:portNumber error:&error];
            self.dataConnection = [[YZZYFTPDataConnection alloc] initWithAsyncSocket:self.dataSocket forConnection:self withQueuedData:self.queuedDataMutableArray];
            break;
        case YZZYFTPTransferModeLPRTFTP:
            self.dataPort = portNumber;
            responseString = [ NSString stringWithFormat:@"228 Entering Long Passive Mode     (af, hal, h1, h2, h3,..., pal, p1, p2...)"]; //, dataPort >>8, dataPort & 0xff;
            [self.dataSocket connectToHost:[self connectionAddress] onPort:portNumber error:&error];
            self.dataConnection = [[YZZYFTPDataConnection alloc] initWithAsyncSocket:self.dataSocket forConnection:self withQueuedData:self.queuedDataMutableArray];
            break;
        case YZZYFTPTransferModeEPRTFTP:
            self.dataPort = portNumber;
            responseString = @"200 EPRT command successful.";
            [self.dataSocket connectToHost:[self connectionAddress] onPort:portNumber error:&error];
            self.dataConnection = [[YZZYFTPDataConnection alloc] initWithAsyncSocket:self.dataSocket forConnection:self withQueuedData:self.queuedDataMutableArray];
            break;
            
            
        default:
            break;
    }
}

- (int)choosePasvDataPort {
    struct timeval tv;
    unsigned short int seed[3];
    
    gettimeofday(&tv, NULL);
    seed[0] = (tv.tv_sec >> 16) & 0xFFFF;
    seed[1] = tv.tv_sec & 0xFFFF;
    seed[2] = tv.tv_usec & 0xFFFF;
    seed48(seed);
    
    int portNumber;
    portNumber = (lrand48() % 64512) + 1024;
    return portNumber;
}
#pragma mark -
#pragma mark - getters and setters


@end
