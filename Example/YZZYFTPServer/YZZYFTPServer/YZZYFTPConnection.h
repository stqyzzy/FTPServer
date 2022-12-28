//
//  YZZYFTPConnection.h
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
#import "YZZYFTPServer.h"
#import "YZZYFTPDefines.h"
NS_ASSUME_NONNULL_BEGIN

@interface YZZYFTPConnection : NSObject
@property (nonatomic, strong) AsyncSocket *connectionSocket; // 连接对应的Socket
@property (nonatomic, strong) YZZYFTPServer *server; // FTPSever
@property (nonatomic, strong) AsyncSocket *dataListeningSocket; // Socket监听数据链接，这个暂时用不上
@property (nonatomic, assign) NSUInteger dataPort; // 数据端口
@property (nonatomic, assign) YZZYFTPTransferMode transferMode; // FTP传输模式
@property (nonatomic, copy) NSMutableArray *queuedDataMutableArray; // 用于在连接尚未完全启动时发送数据的缓冲区
@property (nonatomic, copy) NSString *currentDirString; // 此连接的工作目录，在服务器设置为的目录中启动。 在服务器代码中将 chroot=true 设置为沙盒
@property (nonatomic, copy) NSString *currentFileString; // 将要上传的文件路径
@property (nonatomic, strong) NSFileHandle *currentFileHandle; // 保存文件的句柄
@property (nonatomic, copy) NSString *rnfrFilenameString;
@property (nonatomic, copy) NSString *currentUserString; // 当前连接的用户

// 初始化方法
- (instancetype)initWithAsyncSocket:(AsyncSocket*)newSocket forServer:(YZZYFTPServer *)myServer;
@end

NS_ASSUME_NONNULL_END
