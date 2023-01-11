//
//  YZZYFTPHelper.h
//  YZZYFTPServer_Example
//
//  Created by 云中追月 on 2023/1/10.
//  Copyright © 2023 stqyzzy. All rights reserved.
//

/*===================================================
        * 文件描述 ：<#文件功能描述必写#> *
=====================================================*/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YZZYFTPHelper : NSObject
+ (NSString *)localIPAddress;
@end
#pragma mark LS replacement
NSString *createList(NSString *directoryPath);
int filesinDirectory(NSString *filePath );
NSString *int2BinString(int x);
NSString *byte2String(int x);
NSString *bin2perms(NSString *binaryValue);

NS_ASSUME_NONNULL_END

