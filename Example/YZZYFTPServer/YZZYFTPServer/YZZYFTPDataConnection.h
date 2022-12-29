//
//  YZZYFTPDataConnection.h
//  YZZYFTPServer_Example
//
//  Created by 云中追月 on 2022/12/29.
//  Copyright © 2022 stqyzzy. All rights reserved.
//

/*===================================================
        * 文件描述 ：<#文件功能描述必写#> *
=====================================================*/

#import <Foundation/Foundation.h>
#import "AsyncSocket.h"
#import "YZZYFTPDefines.h"

@class YZZYFTPConnection;
NS_ASSUME_NONNULL_BEGIN

@interface YZZYFTPDataConnection : NSObject
@property (nonatomic, strong) AsyncSocket *dataSocket;
@property (nonatomic, strong) YZZYFTPConnection *ftpConnection; // 生成我们绑定的数据套接字的连接
@property (nonatomic, strong) AsyncSocket *dataListeningSocket;
@property (nonatomic, strong) id dataConnection; // 目前还不知道有什么用，也不确定用strong还是weak修饰

// ASYNCSOCKET DELEGATES
@property (nonatomic, assign) YZZYFTPConnectionState connectionState;
@property (nonatomic, strong, readonly) NSMutableData *receivedData;

- (instancetype)initWithAsyncSocket:(AsyncSocket *)newSocket forConnection:(id)aConnection withQueuedData:(NSMutableArray *)queuedData;
- (void)writeData:(NSMutableData *)data;
- (void)closeConnection;
@end

NS_ASSUME_NONNULL_END
 
