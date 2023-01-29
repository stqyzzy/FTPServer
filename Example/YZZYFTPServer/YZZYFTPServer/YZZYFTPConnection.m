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

@interface YZZYFTPConnection()<AsyncSocketDelegate>

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
- (instancetype)initWithAsyncSocket:(AsyncSocket *)newSocket forServer:(YZZYFTPServer *)myServer {
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
    if (self.currentFileHandle != nil) {
        [self.currentFileHandle writeData:self.dataConnection.receivedData];
    } else {
        if (g_XMFTP_LogEnabled) {
            XMFTPLog(@"Couldn't write data");
        }
    }
}

// ASYNCSOCKET FTPCLIENT CONNECTION
// 来自FtpDataConnection的通知，表明数据已写入
- (void)didReceiveDataWritten {
    if (g_XMFTP_LogEnabled) {
        XMFTPLog(@"SENDING COMPLETED");
    }
    [self sendMessage:@"226 Transfer complete."]; // 发送完成消息给客户端
    [self.dataConnection closeConnection];
}

// 我们假定，在从客户端的数据连接结束时调用
- (void)didFinishReading {
    if (self.currentFileString) {
        if (g_XMFTP_LogEnabled) {
            XMFTPLog(@"Closing File Handle");
        }
        self.currentFileString = nil;
    } else {
        if (g_XMFTP_LogEnabled) {
            XMFTPLog(@"FC:Data Sent but not sure where its for ");
        }
    }
    [self sendMessage:@"226 Transfer complete."]; // 发送完成消息给客户端
    
    if (self.currentFileHandle != nil) {
        if (g_XMFTP_LogEnabled) {
            XMFTPLog(@"Closing File Handle");
        }
        [self.currentFileHandle closeFile];
        self.currentFileHandle = nil;
        [self.server didReceiveFileListChanged];
    }
    self.dataConnection.connectionState = YZZYFTPConnectionStateClientQuiet;
}
#pragma mark -
#pragma mark - AsyncSocketDelegate Delegate
- (BOOL)onSocketWillConnect:(AsyncSocket *)sock {
    if (g_XMFTP_LogEnabled) {
        XMFTPLog(@"FC:onSocketWillConnect");
    }
    [sock readDataWithTimeout:READ_TIMEOUT tag:0];
    return YES;
}

// 以2001端口的数据连接（data Connection）使用
- (void)onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket {
    // 打开的被动连接套接字 - 连接到此的新套接字，即被动连接（passive connection）
    if (g_XMFTP_LogEnabled) {
        XMFTPLog(@"FC:New Connection -- should be for the data port");
    }
    self.dataConnection = [[YZZYFTPDataConnection alloc] initWithAsyncSocket:newSocket forConnection:self withQueuedData:self.queuedDataMutableArray];
}

// 从Socket读物数据，即从Socket连接收到数据
- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    if (g_XMFTP_LogEnabled) {
        XMFTPLog(@"FC:didReadData");
    }
    [self.connectionSocket readDataToData:[AsyncSocket CRLFData] withTimeout:READ_TIMEOUT tag:FTP_CLIENT_REQUEST]; // 开始读取数据
    // 将数据转换成方法并执行
    [self processDataRead:data];
}

- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag {
    // 开始读取数据
    [self.connectionSocket readDataToData:[AsyncSocket CRLFData] withTimeout:READ_TIMEOUT tag:FTP_CLIENT_REQUEST ];
}
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
        case YZZYFTPTransferModePORTFTP: {
            self.dataPort = portNumber;
            responseString = [NSString stringWithFormat:@"200 PORT command successful."];
            // 连接到Server
            [self.dataSocket connectToHost:[self connectionAddress] onPort:portNumber error:&error];
            self.dataConnection = [[YZZYFTPDataConnection alloc] initWithAsyncSocket:self.dataSocket forConnection:self withQueuedData:self.queuedDataMutableArray];
            break;
        }
        case YZZYFTPTransferModeLPRTFTP: {
            self.dataPort = portNumber;
            responseString = [NSString stringWithFormat:@"228 Entering Long Passive Mode     (af, hal, h1, h2, h3,..., pal, p1, p2...)"]; //, dataPort >>8, dataPort & 0xff;
            [self.dataSocket connectToHost:[self connectionAddress] onPort:portNumber error:&error];
            self.dataConnection = [[YZZYFTPDataConnection alloc] initWithAsyncSocket:self.dataSocket forConnection:self withQueuedData:self.queuedDataMutableArray];
            break;
        }
        case YZZYFTPTransferModeEPRTFTP: {
            self.dataPort = portNumber;
            responseString = @"200 EPRT command successful.";
            [self.dataSocket connectToHost:[self connectionAddress] onPort:portNumber error:&error];
            self.dataConnection = [[YZZYFTPDataConnection alloc] initWithAsyncSocket:self.dataSocket forConnection:self withQueuedData:self.queuedDataMutableArray];
            break;
        }
        case YZZYFTPTransferModePASVFTP:{
            self.dataPort = [self choosePasvDataPort];
            NSString *addressString = [[self.connectionSocket localHost] stringByReplacingOccurrencesOfString:@"." withString:@","];
            responseString = [NSString stringWithFormat:@"227 Entering Passive Mode (%@,%d,%d)", addressString, self.dataPort>>8, self.dataPort&0xff];
            [self.dataSocket acceptOnPort:self.dataPort error:&error];
            self.dataConnection = nil; // 将从监听的套接字接起
            break;
        }
        case YZZYFTPTransferModeEPSVFTP:{
            self.dataPort = [self choosePasvDataPort];
            responseString = [NSString stringWithFormat:@"229 Entering Extended Passive Mode (|||%d|)", self.dataPort];
            [self.dataSocket acceptOnPort:self.dataPort error:&error];
            self.dataConnection = nil; // 将从监听的套接字接起
            break;
        }
        default:
            break;
    }
    if (g_XMFTP_LogEnabled) {
        XMFTPLog(@"-- %@", [error localizedDescription]);
    }
    [self sendMessage:responseString];
    
    return YES;
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

// ASYNCSOCKET FTPCLIENT CONNECTION
// calls FC  writedata
- (void)sendMessage:(NSString *)ftpMessage {
    if (g_XMFTP_LogEnabled) {
        XMFTPLog(@">%@",ftpMessage );
    }
    NSMutableData *dataString = [[ftpMessage dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];
    [dataString appendData:[AsyncSocket CRLFData]];
    [self.connectionSocket writeData:dataString withTimeout:READ_TIMEOUT tag:FTP_CLIENT_REQUEST];
    [self.connectionSocket readDataToData:[AsyncSocket CRLFData] withTimeout:READ_TIMEOUT tag:FTP_CLIENT_REQUEST];
}

// PROCESS
// 将数据转成客户端连接的命令
- (void)processDataRead:(NSData *)data {
    NSData *strData = [data subdataWithRange:NSMakeRange(0, data.length - 2)]; // 删掉最后两个字符
    NSString *crlfMessageString = [[NSString alloc] initWithData:strData encoding:self.server.clientEncoding];
    NSString *messageString = [crlfMessageString stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    if (g_XMFTP_LogEnabled) {
        XMFTPLog(@"<%@", messageString);
    }
    self.msgComponentsArray = [messageString componentsSeparatedByString:@" "]; // 将其更改为使用空格 - 对于 FTP 协议
    [self processCommand];
    [self.connectionSocket readDataToData:[AsyncSocket CRLFData] withTimeout:-1 tag:0]; // 强制读取数据检查
}

// 假设数据已放置在数组msgComponentsArray中
- (void)processCommand {
    NSString *commandString = [self.msgComponentsArray objectAtIndex:0];
    if (commandString.length > 0) {
        // 搜索命令字典，找到它调用的命令和方法
        NSString *commandSelectorString = [[[self.server commandsDic] objectForKey:[commandString lowercaseString]] stringByAppendingString:@"arguments:"];
        if (commandSelectorString) {
            SEL action = NSSelectorFromString(commandSelectorString); // 根据方法名创建方法对象
            if ([self respondsToSelector:action]) {
                // 执行命令
                NSLog(@"stq-------commandSelector = %@", commandSelectorString);
                [self performSelector:action withObject:self withObject:self.msgComponentsArray]; // 执行带参数的命令
            } else {
                // 未知的命令
                NSString *outputString = [NSString stringWithFormat:@"500 '%@': command not understood.", commandString];
                [self sendMessage:outputString];
                if (g_XMFTP_LogEnabled) {
                    XMFTPLog(@"DONT UNDERSTAND");
                }
            }
        } else {
            // 未知的命令
            NSString *outputString = [NSString stringWithFormat:@"500 '%@': command not understood.", commandString];
            [self sendMessage:outputString];
        }
    } else {
        // 输出错误信息
    }
}

- (void)sendDataString:(NSString *)dataString {
    NSMutableString *messageString = [[NSMutableString alloc] initWithString:dataString];
    CFStringNormalize((CFMutableStringRef)messageString, kCFStringNormalizationFormC);
    NSMutableData *data = [[messageString dataUsingEncoding:self.server.clientEncoding] mutableCopy];
    if (self.dataConnection) {
        if (g_XMFTP_LogEnabled) {
             XMFTPLog(@"FC:sendData");
        }
        [self.dataConnection writeData:data];
    } else {
        [self.queuedDataMutableArray addObject:data];
    }
}

- (void)sendData:(NSMutableData *)data {
    if (self.dataConnection) {
        if (g_XMFTP_LogEnabled) {
            XMFTPLog(@"FC:sendData");
        }
        [self.dataConnection writeData:data];
    } else {
        [self.queuedDataMutableArray addObject:data];
    }
}

#pragma mark COMMANDS - https://zh.m.wikipedia.org/zh-hans/FTP命令列表
// 断开连接命令
- (void)doQuit:(id)sender arguments:(NSArray *)arguments {
    if (g_XMFTP_LogEnabled) {
        XMFTPLog(@"Quit : %@",arguments);
    }
    [self sendMessage:@"221- Data traffic for this session was 0 bytes in 0 files"];
    [self sendMessage:@"221 Thank you for using the FTP service on localhost."];
    if (self.connectionSocket) {
        [self.connectionSocket disconnectAfterWriting];
    }
    [self.server closeConnection:self]; //  告知服务端关闭该连接，将该服务从连接列表中移除
}

// 用户名认证
- (void)doUser:(id)sender arguments:(NSArray *)arguments {
    // 发出确认信息--331 password required for
    if (self.currentUserString != nil) {
        self.currentUserString = [arguments objectAtIndex:1];// 传递过来的用户名
        NSString *outputString = @"";
        NSString *localUserNameString = @""; // 本地设置的用户名
        if ([self.currentUserString isEqualToString:localUserNameString]) {
            outputString = [ NSString stringWithFormat:@"331 Password required for %@", self.currentUserString];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"currentUserLogin" object:nil]; // 发送登录通知
        } else {
            outputString = @"530 Invalid username\n"; // 无效信息
        }
        [sender sendMessage:outputString];
    }
}

// 密码认证
- (void)doPass:(id)sender arguments:(NSArray *)arguments {
    NSString *receivedPasswordString = [arguments objectAtIndex:1]; // 收到的密码
    NSString *outputString = @"";
    NSString *localPasswordString = @"123"; // 本地的正确密码
    if ([receivedPasswordString isEqualToString:localPasswordString]) {
        outputString = [NSString stringWithFormat:@"230 User %@ logged in.", self.currentUserString];
    } else {
        outputString = @"500 Invalid username or password\n";
    }
    [sender sendMessage:outputString];
}

// 返回当前的状态
- (void)doStat:(id)sender arguments:(NSArray *)arguments {
    // 发送状态消息
    [sender sendMessage:@"211-localhost FTP server status:"];
    // FIXME - add in the stats
    [sender sendMessage:@"211 End of Status"];
}

// 获得服务器支持的特性列表
- (void)doFeat:(id)sender arguments:(NSArray*)arguments {
    [sender sendMessage:@"211-Features supported"];
    // If encoding is UTF8, notify the client
    if (self.server.clientEncoding == NSUTF8StringEncoding) {
        [sender sendMessage:@" UTF8"];
    }
    [sender sendMessage:@"211 End"];
}

// 返回工作目录的信息--如果指定了文件或目录，返回其信息；否则返回当前工作目录的信息
- (void)doList:(id)sender arguments:(NSArray *)arguments {
    // 获取要求我们列出的任何其他目录的名称，如果是空，就是当前目录
    NSString *lsDirString = [self fileNameFromArgs:arguments]; // 获取我们请求的目录
    NSString *listTextString;
    if (lsDirString.length < 1) {
        lsDirString = self.currentDirString;
    } else {
        lsDirString = [self rootedPath:lsDirString];
    }
    
    if (g_XMFTP_LogEnabled) {
        XMFTPLog(@"doList currentDir(%@) changeRoot%d", lsDirString, self.server.changeRoot);
        XMFTPLog(@"Will list %@ ", lsDirString);
    }
    
    listTextString = [self.server createList:lsDirString];
    if (g_XMFTP_LogEnabled) {
        XMFTPLog( @"doList sending this. %@", listTextString);
    }
    [sender sendMessage:@"150 Opening ASCII mode data connection for '/bin/ls'."];
    
    [sender sendDataString:listTextString];
}

// 打印工作目录，返回主机的当前目录
- (void)doPwd:(id)sender arguments:(NSArray *)arguments {
    if (g_XMFTP_LogEnabled) {
        XMFTPLog(@"Will PWD %@ ", [self visibleCurrentDir]);
    }
    NSString *cmdString = [NSString stringWithFormat:@"257 \"%@\" is the current directory.", [self visibleCurrentDir]];
    [sender sendMessage:cmdString];
}

// 无操作（哑包；通常用来保活）
- (void)doNoop:(id)sender arguments:(NSArray*)arguments {
    [sender sendMessage:@"200 NOOP command successful."];
}

// 返回系统类型
- (void)doSyst:(id)sender arguments:(NSArray*)arguments {
    [sender sendMessage:@"215 UNIX Type: L8 Version: iosFtp 20080912"];
}

// 为服务器指定要连接的长地址和端口
- (void)doLprt:(id)sender arguments:(NSArray *)arguments {
    // LPRT,"6,16,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,2,231,92"
    NSString *socketDescString = [arguments objectAtIndex:1];
    NSArray *socketAddrArray = [socketDescString componentsSeparatedByString:@","];
    int hb = [[socketAddrArray objectAtIndex:19] intValue];
    int lb = [[socketAddrArray objectAtIndex:20] intValue];
    if (g_XMFTP_LogEnabled) {
        XMFTPLog(@"%d %d %d", hb<<8, hb, lb);
    }
    int clientPort = (hb << 8) + lb;
    [sender setTransferMode:YZZYFTPTransferModeLPRTFTP];
    [sender openDataSocket:clientPort];
}

// 为服务器指定要连接的扩展地址和端口
- (void)doEprt:(id)sender arguments:(NSArray *)arguments {
    // EPRT |2|1080::8:800:200C:417A|5282|
    NSString *socketDescString = [arguments objectAtIndex:1];
    NSArray *socketAddrArray = [socketDescString componentsSeparatedByString:@"|"];
    if (g_XMFTP_LogEnabled) {
        for (NSString *item in socketAddrArray) {
            XMFTPLog(@"%@", item);
        }
    }
    int clientPort = [[socketAddrArray objectAtIndex:3] intValue];
    if (g_XMFTP_LogEnabled) {
        XMFTPLog(@"Got Send Port %d", clientPort);
    }
    [sender setTransferMode:YZZYFTPTransferModeEPRTFTP];
    [sender openDataSocket:clientPort];
}

// 进入被动模式
- (void)doPasv:(id)sender arguments:(NSArray *)arguments {
    [sender setTransferMode:YZZYFTPTransferModePASVFTP];
    [sender openDataSocket:0];
}

// 进入扩展被动模式
- (void)doEpsv:(id)sender arguments:(NSArray *)arguments {
    [sender setTransferMode:YZZYFTPTransferModeEPSVFTP];
    [sender openDataSocket:0];
}

// 指定服务器要连接的地址和端口
- (void)doPort:(id)sender arguments:(NSArray *)arguments {
    int hb, lb;
    // 端口格式如下：PORT 127,0,0,1,197,251
    // 获取第二个参数并以“,”拆分，然后取最后2位
    NSString *socketDescString = [arguments objectAtIndex:1];
    NSArray *socketAddrArray = [socketDescString componentsSeparatedByString:@","];
    
    hb = [[socketAddrArray objectAtIndex:4] intValue];
    lb = [[socketAddrArray objectAtIndex:5] intValue];
    
    int clientPort = (hb << 8) + lb;
    [sender setTransferMode:YZZYFTPTransferModePORTFTP];
    [sender openDataSocket:clientPort];
}

// 为特性选择选项
- (void)doOpts:(id)sender arguments:(NSArray *)arguments {
    NSString *cmd = [arguments objectAtIndex:1];
    NSString *cmdstr = [NSString stringWithFormat:@"502 Unknown command '%@'",cmd];
    [sender sendMessage:cmdstr];
}

// 设定传输模式（ASCII/二进制).
- (void)doType:(id)sender arguments:(NSArray *)arguments {
    NSString *cmd = [arguments objectAtIndex:1];
    NSString *cmdString = [NSString stringWithFormat:@"200 Type set to  %@.", cmd];
    [sender sendMessage:cmdString];
}

// 改变工作目录
- (void)doCwd:(id)sender arguments:(NSArray *)arguments {
    //    250
    //    500, 501, 502, 421, 530, 550
    //    250 CWD command successful.
    if (g_XMFTP_LogEnabled) {
        XMFTPLog(@"DoCwd arguments is %@",arguments);
    }
    NSString *cmdString;
    NSString *cwdDirString = [self fileNameFromArgs:arguments]; // 获取我们请求的目录
    if ([self changeCurrentDirectoryTo:cwdDirString]) {
        cmdString = [NSString stringWithFormat:@"250 OK. Current directory is %@", [self visibleCurrentDir]]; // 当前目录已经在新位置了
        cmdString = @"250 CWD command successful.";
    } else {
        cmdString = @"550 CWD failed.";
    }
    [sender sendMessage:cmdString];
    if (g_XMFTP_LogEnabled) {
        XMFTPLog(@"currentDir is now %@", self.currentDirString);
    }
}

// 返回指定目录的文件名列表
- (void)doNlst:(id)sender arguments:(NSArray *)arguments {
    [self doList:sender arguments:arguments];
}

// 接收数据并且在服务器站点保存为文件
- (void)doStor:(id)sender arguments:(NSArray *)arguments {
    // 以存储my filename here.mp3 文件为例， STOR = 0，my = 1，filename = 2等
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *fileNameString = [self fileNameFromArgs:arguments];
    NSString *cmdString;
    self.currentFileString = [self makeFilePathFrom:fileNameString];
    // 检查这是否在我们允许写入的文件系统区域内
    if ([self validNewFilePath:self.currentFileString]) {
        // 创建并且打开文件，准备写入
        if ([fileManager createFileAtPath:self.currentFileString contents:nil attributes:nil] == YES) {
            cmdString = [NSString stringWithFormat:@"150 Opening BINARY mode data connection for '%@'.", fileNameString];
        } else {
            cmdString = [NSString stringWithFormat:@"553 %@: Permission denied.", fileNameString];
        }
    } else {
        // 不能创建文件
        cmdString = [NSString stringWithFormat:@"553 %@: Permission denied.", fileNameString];
    }
    
    if (g_XMFTP_LogEnabled) {
        XMFTPLog(@"FC:doStor  %@", self.currentFileString);
    }
    
    [sender sendMessage:cmdString];
    
    if (self.dataConnection) {
        if (g_XMFTP_LogEnabled) {
            XMFTPLog(@"FC:setting connection state to clientSending");
        }
        self.dataConnection.connectionState = YZZYFTPConnectionStateClientSending;
    } else {
        if (g_XMFTP_LogEnabled) {
            XMFTPLog(@"FC:Erorr  Cant set connection state to Client Sending : no Connection yet ");
        }
    }
}

// 传输文件副本到客户端
- (void)doRetr:(id)sender arguments:(NSArray *)arguments {
    // 下载到客户端
    BOOL isDir;
    NSString *cmdString;
    NSString *fileNameString = [self fileNameFromArgs:arguments];
    NSString *filePathString = [self makeFilePathFrom:fileNameString]; // 将相对路径或绝对路径转换成我们需要的格式
    
    if (g_XMFTP_LogEnabled) {
        XMFTPLog(@"FC:doRetr: %@", filePathString);
    }
    
    if ([self accessibleFilePath:filePathString]) {
        // 判断这个文件路径是否在root区域，并且它是一个真实的文件
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePathString isDirectory:&isDir]) {
            if (isDir) {
                [sender sendMessage:[NSString stringWithFormat:@"550 %@: Not a plain file.", fileNameString]];
            } else {
                NSMutableData *fileData = [NSMutableData dataWithContentsOfFile:filePathString];
                cmdString = [NSString stringWithFormat:@"150 Opening BINARY mode data connection for '%@'.", fileNameString];
                [sender sendMessage:cmdString];
                [sender sendData:fileData];
            }
        }
    } else {
        cmdString = [NSString stringWithFormat:@"50 %@ No such file or directory.", fileNameString];
        if (g_XMFTP_LogEnabled) {
            XMFTPLog(@"FC:doRetr: file %@ doesnt' exist ", filePathString);
        }
        [sender sendMessage:cmdString];
    }
}

// 删除文件
- (void)doDele:(id)sender arguments:(NSArray *)arguments {
    NSString *cmdString;
    NSError *error;
    NSString *fileNameString = [self fileNameFromArgs:arguments];
    NSString *filePathString = [self makeFilePathFrom:fileNameString];
    
    if (g_XMFTP_LogEnabled) {
        XMFTPLog(@"filename is %@",fileNameString);
    }
    
    if ([self accessibleFilePath:filePathString]) {
        if ([[NSFileManager defaultManager] removeItemAtPath:filePathString error:&error]) {
            cmdString = [NSString stringWithFormat:@"250 DELE command successful.", fileNameString];
            [self.server didReceiveFileListChanged];
        } else {
            cmdString = [ NSString stringWithFormat:@"550 DELE command unsuccessful.", fileNameString];
        }
    } else {
        cmdString = [NSString stringWithFormat:@"550 %@ No such file or directory.", fileNameString];
    }
    [sender sendMessage:cmdString];
}


#pragma mark UTILITIES
- (NSString *)fileNameFromArgs:(NSArray *)arguments {
    NSString *fileNameString = @"";
    if (g_XMFTP_LogEnabled) {
        XMFTPLog(@"%@", [arguments description]);
    }
    if (arguments.count > 1) {
        for (int i = 1; i < arguments.count; i++) {
            // 测试参数是否以"-"开头，如果以“-”开头，就可能是参数而不是名字
            if ([[[arguments objectAtIndex:i] substringToIndex:1] isEqualToString:@"-"]) {
                if (fileNameString.length == 0) {
                    fileNameString = [arguments objectAtIndex:i];
                } else {
                    fileNameString = [NSString stringWithFormat:@"%@ %@", fileNameString, [arguments objectAtIndex:i]];
                }
            } else {
                if (g_XMFTP_LogEnabled) {
                    XMFTPLog(@"HYPHEN FOUND IGNORE");
                }
            }
        }
    }
    return fileNameString;
}

- (NSString *)rootedPath:(NSString *)path {
    NSString *expandedPathString;
    // 获取新目录的全路径
    if ([path characterAtIndex:0] == '/') {
        // 如果是绝对路径
        if (self.server.changeRoot) {
            // 如果rooted了，这是一个相对路径，因此加上基础路径
            expandedPathString = [[self.server.baseDirString stringByAppendingPathComponent:path] stringByResolvingSymlinksInPath];
        } else {
            expandedPathString = path; // 使用绝对路径
        }
    } else {
        // 由于是相对路径，则拼接当前目录，成为绝对路径
        expandedPathString = [[self.currentDirString stringByAppendingPathComponent:path] stringByResolvingSymlinksInPath];
    }
    expandedPathString = [expandedPathString stringByStandardizingPath];
    return expandedPathString;
}

- (NSString *)visibleCurrentDir {
    if (self.server.changeRoot) {
        // 如果是root了
        NSUInteger alength = self.server.baseDirString.length;
        if (g_XMFTP_LogEnabled) {
            XMFTPLog(@"Length is %lu", alength);
        }
        NSString *aString = [self.currentDirString substringFromIndex:alength]; // 获取基础路径后一位开始获取子串（一个bit）
        if (![aString hasSuffix:@"/"]) {
            aString = [aString stringByAppendingString:@"/"];
        }
        // 返回一个基础地址前缀移除厚的路径，只返回路径的最后部分，不包括基础路径
        return aString;
    } else {
        // 返回完整路径
        return self.currentDirString;
    }
}

- (Boolean)changeCurrentDirectoryTo:(NSString *)newDirectory {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *currentDirectoryString = [fileManager currentDirectoryPath]; // 保存当前的目录
    
    NSString *expandedPathString = [self rootedPath:newDirectory];
    if (![self canChangeDirectoryTo:expandedPathString]) {
        // 测试我们能否使用这个目录
        return false;
    }
    
    // 切换到新目录并且获取系统文件路径
    if (![fileManager changeCurrentDirectoryPath:expandedPathString]) {
        return false;
    }
    
    NSString *testDirectoryString = [fileManager currentDirectoryPath]; // 获取新目录
    if (![fileManager changeCurrentDirectoryPath:currentDirectoryString]) {
        return false; // Not a valid directory, shouldnt happen, but could u know
    }
    self.currentDirString = testDirectoryString;
    return true;
}

- (Boolean)canChangeDirectoryTo:(NSString *)testDirectory {
    if (self.server.changeRoot && (![testDirectory hasPrefix:self.server.baseDirString])) {
        return false;
    } else {
        return true;
    }
}

- (NSString *)makeFilePathFrom:(NSString *)fileName {
    if ([fileName characterAtIndex:0] == '/') {
        // 绝对路径
        if (self.server.changeRoot) {
            // 相对baseDir的相对路径
            return [[self.server.baseDirString stringByAppendingPathComponent:fileName] stringByResolvingSymlinksInPath];
        } else {
            return fileName;
        }
    } else {
        return [self.currentDirString stringByAppendingPathComponent:fileName];
    }
}

- (Boolean)validNewFilePath:(NSString*)filePath {
    return true;
}

- (Boolean)accessibleFilePath:(NSString*)filePath {
    return [[NSFileManager defaultManager] fileExistsAtPath:filePath];
}


#pragma mark -
#pragma mark - getters and setters


@end
