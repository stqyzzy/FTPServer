//
//  YZZYFTPServer.h
//  YZZYFTPServer_Example
//
//  Created by 云中追月 on 2022/12/27.
//  Copyright © 2022 stqyzzy. All rights reserved.
//

/*===================================================
        * 文件描述 ：<#文件功能描述必写#> *
=====================================================*/

#import <Foundation/Foundation.h>
#import "AsyncSocket.h"

NS_ASSUME_NONNULL_BEGIN

@protocol YZZYFTPServerNotification <NSObject>
// NOTIFICATIONS
- (void)didReceiveFileListChanged;
@end

@interface YZZYFTPServer : NSObject <AsyncSocketDelegate>
@property (nonatomic, strong) id<YZZYFTPServerNotification> notificationObject; // 通知的对象
@property (nonatomic, copy) NSDictionary *commandsDic; // 命令字典
@property (nonatomic, copy) NSMutableArray *connectionsMutableArray; // 连接数组
@property (nonatomic, assign) NSInteger portNumber; // 端口号
@property (nonatomic, strong) AsyncSocket *listenSocket;
@property (nonatomic, copy) NSMutableArray *connectedSocketsMutableArray; // 连接的Sockets数组
@property (nonatomic, copy) NSString *baseDirString; // 基础文件路径
@property (nonatomic, assign) BOOL changeRoot; // Change root to virtual root ( basedir )
@property (nonatomic, assign) NSInteger clientEncoding; // 客户端编码

// 初始化方法，Dir是可以通讯的文件路径
- (instancetype)initWithPort:(unsigned)serverPort withDir:(NSString*)aDirectory notifyObject:(id)sender;
// 停止FTP服务
- (void)stopFtpServer;
// NOTIFICATIONS
- (void)didReceiveFileListChanged;
// CONNECTIONS
- (void)closeConnection:(id)theConnection;
@end

NS_ASSUME_NONNULL_END
