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
@property (nonatomic, strong) YZZYFTPConnection *ftpConnection;                        // connection which generated data socket we are tied to

// ASYNCSOCKET DELEGATES
@property (nonatomic, assign) YZZYFTPConnectionState connectionState;
- (instancetype)initWithAsyncSocket:(AsyncSocket *)newSocket forConnection:(id)aConnection withQueuedData:(NSMutableArray *)queuedData;

@end

NS_ASSUME_NONNULL_END
 
