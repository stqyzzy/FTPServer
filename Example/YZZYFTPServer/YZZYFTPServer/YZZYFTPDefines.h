//
//  YZZYFTPDefines.h
//  YZZYFTPServer
//
//  Created by 云中追月 on 2022/12/27.
//  Copyright © 2022 stqyzzy. All rights reserved.
//

#ifndef YZZYFTPDefines_h
#define YZZYFTPDefines_h

typedef NS_ENUM(NSUInteger, YZZYFTPTransferMode) {
    YZZYFTPTransferModePASVFTP = 0,
    YZZYFTPTransferModeEPSVFTP,
    YZZYFTPTransferModePORTFTP,
    YZZYFTPTransferModeLPRTFTP,
    YZZYFTPTransferModeEPRTFTP
};

#define DATASTR(args) [args dataUsingEncoding:NSUTF8StringEncoding]

#define READ_TIMEOUT -1

#define FTP_CLIENT_REQUEST 0

typedef NS_ENUM(NSInteger, YZZYFTPConnectionState) {
    YZZYFTPConnectionStateClientSending = 0,
    YZZYFTPConnectionStateClientReceiving = 1,
    YZZYFTPConnectionStateClientQuiet = 2,
    YZZYFTPConnectionStateClientSent = 3
};

#ifdef DEBUG
#define XMFTPLog(...) NSLog(__VA_ARGS__)
#else
#define XMFTPLog(...)
#endif

extern BOOL g_XMFTP_LogEnabled;

#endif /* YZZYFTPDefines_h */
