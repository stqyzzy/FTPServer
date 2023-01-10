//
//  YZZYFTPServer.m
//  YZZYFTPServer_Example
//
//  Created by 云中追月 on 2022/12/27.
//  Copyright © 2022 stqyzzy. All rights reserved.
//

#import "YZZYFTPServer.h"
#import "YZZYFTPDefines.h"
#import "YZZYFTPConnection.h"

BOOL g_XMFTP_LogEnabled = NO;

@interface YZZYFTPServer()

@end

@implementation YZZYFTPServer

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
// 初始化方法，Dir是可以通讯的文件路径
- (instancetype)initWithPort:(unsigned)serverPort withDir:(NSString*)aDirectory notifyObject:(id)sender {
    if (self = [super init]) {
        self.notificationObject = sender; // 设置通知对象
        // 加载命令
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"xmftp_commands" ofType:@"plist"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
            // 文件不存在，则产生断言
            NSAssert(0, @"xmftp_commands.plist missing");
        }
        self.commandsDic = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
        // 清楚连接列表
        self.connectionsMutableArray = [[NSMutableArray alloc] init];
        // 创建一个socket端口
        self.portNumber = serverPort;
        // 创建Socket连接
        AsyncSocket *myListenSocket = [[AsyncSocket alloc] initWithDelegate:self];
        self.listenSocket = myListenSocket;
        
        // 日志开关
        if (g_XMFTP_LogEnabled) {
            XMFTPLog(@"Listening on %zd", self.portNumber);
        }
        NSError *error = nil;
        // Socket开启监听
        [self.listenSocket acceptOnPort:serverPort error:&error];
        self.connectedSocketsMutableArray = [[NSMutableArray alloc] initWithCapacity:1];
        
        // 设置路径
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *expandedPath = [aDirectory stringByStandardizingPath]; // 拼接标准路径
        
        
        if ([fileManager changeCurrentDirectoryPath:expandedPath]) {
            // 尝试改成标准化路径
            self.baseDirString = [[fileManager currentDirectoryPath] copy];
        } else {
            self.baseDirString = aDirectory;
        }
        self.changeRoot = NO;
        // 默认编码是 UTF8
        self.clientEncoding = NSUTF8StringEncoding;
    }
    return self;
}

// 停止FTP服务
- (void)stopFtpServer {
    if (self.listenSocket) {
        [self.listenSocket disconnect];
    }
    
    [self.connectedSocketsMutableArray removeAllObjects];
    [self.connectionsMutableArray removeAllObjects];
}

// NOTIFICATIONS
- (void)didReceiveFileListChanged {
    if ([self.notificationObject respondsToSelector:@selector(didReceiveFileListChanged)]) {
        [self.notificationObject didReceiveFileListChanged];
    }
}

#pragma mark -
#pragma mark - ASYNCSOCKET Delegate
- (void)onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket {
    YZZYFTPConnection *newConnection = [[YZZYFTPConnection alloc] initWithAsyncSocket:newSocket forServer:self];
    [self.connectionsMutableArray addObject:newConnection]; // 添加到连接数组中
    if (g_XMFTP_LogEnabled) {
        XMFTPLog(@"FS:didAcceptNewSocket  port:%i", [sock localPort]);
    }
    if ([sock localPort] == self.portNumber) {
        if (g_XMFTP_LogEnabled) {
            XMFTPLog(@"Connection on Server Port");
        }
    } else {
        // 必须是数据通信端口，生成一个数据通信端口，查找具有相同端口的连接，并连接它
        if (g_XMFTP_LogEnabled) {
            XMFTPLog(@"--ERROR %i, %d", [sock localPort], self.portNumber);
        }
    }
}


#pragma mark -
#pragma mark - private methods

#pragma mark -
#pragma mark - getters and setters


@end
