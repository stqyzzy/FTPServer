//
//  YZZYFTPHelper.m
//  YZZYFTPServer_Example
//
//  Created by 云中追月 on 2023/1/10.
//  Copyright © 2023 stqyzzy. All rights reserved.
//

#import "YZZYFTPHelper.h"

#import <SystemConfiguration/SystemConfiguration.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <unistd.h>
#include <ifaddrs.h>

@interface YZZYFTPHelper()

@end

@implementation YZZYFTPHelper

// 获得IP地址
+ (NSString *)localIPAddress {
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // 检索当前接口 成功时返回0
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // 循环连接的接口
        temp_addr = interfaces;
        while (temp_addr != NULL) {
            if (temp_addr->ifa_addr->sa_family == AF_INET) {
                // 检查接口是否为en0，这是iPhone上的wifi连接
                if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    freeifaddrs(interfaces);
    return address;
}
@end

NSString *createList(NSString *directoryPath) {
    NSFileManager *fileManager = [NSFileManager defaultManager]; // 文件管理器
    NSDictionary *fileAtttributes; // 文件属性
    NSError *error;
    
    NSString *fileType; // 文件类型
    NSNumber *filePermissions; // 文件许可
    long fileSubdirCount; // 子路径计数
    NSString *fileOwner; // 文件拥有者
    NSString *fileGroup; // 文件群组
    NSNumber *fileSize; // 文件大小
    NSDate *fileModified; // 文件修改时间
    NSString *fileDateFormatted; // 文件时间格式
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init]; // 时间格式
    
    BOOL fileIsDirectory; // 文件是否是文件夹
    
    NSMutableString *returnString = [[NSMutableString alloc] init];
    NSString *formattedString;
    NSString *binaryString;
    
    [returnString appendString:@"\r\n"];
    
    NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:directoryPath]; // 枚举路径下的所有文件
    NSString *filePath; // 文件路径
    
    NSString *firstChar;
    NSString *fullFilePath;
    
    [dateFormatter setDateFormat:@"MMM dd HH:mm"];
    NSLocale *englishLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en"];
    [dateFormatter setLocale:englishLocale];
    
    NSLog(@"Get LS for %@", directoryPath);
    int numberOfFiles = 0;
    while (filePath = [dirEnum nextObject]) {
        firstChar = [filePath substringToIndex:1];
        [dirEnum skipDescendants]; // 跳过递归路径
        if (![firstChar isEqualToString:@"."]) { // 不展示隐藏文件
            fullFilePath = [directoryPath stringByAppendingPathComponent:filePath];
            
            fileAtttributes = [fileManager attributesOfItemAtPath:fullFilePath error:&error]; // 文件属性
            
            fileType = [fileAtttributes valueForKey:NSFileType];
            
            filePermissions = [fileAtttributes valueForKey:NSFilePosixPermissions];
            fileSubdirCount = filesinDirectory(fullFilePath);
            
            fileOwner = [fileAtttributes valueForKey:NSFileOwnerAccountName];
            fileGroup = [fileAtttributes valueForKey:NSFileGroupOwnerAccountName];
            fileSize = [fileAtttributes valueForKey:NSFileSize];
            fileModified = [fileAtttributes valueForKey:NSFileModificationDate];
            fileDateFormatted = [dateFormatter stringFromDate:fileModified];
            
            fileIsDirectory = (fileType == NSFileTypeDirectory);
            
            fileSubdirCount = fileSubdirCount < 1 ? 1 : fileSubdirCount;
            
            binaryString = int2BinString([filePermissions intValue]);
            binaryString = [binaryString substringFromIndex:7]; // 剪掉前面
            formattedString = [NSString stringWithFormat:@"%@%@ %5li %12@ %12@ %10qu %@ %@", fileIsDirectory ? @"d" : @"-", bin2perms(binaryString), fileSubdirCount, fileOwner, fileGroup, [fileSize unsignedLongLongValue], fileDateFormatted, filePath];
            
            [returnString appendString:formattedString];
            [returnString appendString:@"\n"];
            numberOfFiles++;
        }
    }
    [returnString insertString:[NSString stringWithFormat:@"total %d", numberOfFiles] atIndex:0];
    return returnString;
}

int filesinDirectory(NSString *filePath) {
    int no_files = 0;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:filePath];
    while (filePath = [dirEnum nextObject]) {
        [dirEnum skipDescendents];                                        // don't want children
        no_files++;
    }
    return no_files;
}

// 16进制按8位截断，转成字符串
NSString *int2BinString(int x) {
    NSMutableString *returnString = [[NSMutableString alloc] init];
    int hi, lo;
    hi = (x>>8) & 0xff; // 高8位
    lo=x&0xff; // 低8位
    
    [returnString appendString:byte2String(hi)];
    [returnString appendString:byte2String(lo)];
    return [returnString copy];
}

// 字节转字符串
NSString *byte2String(int x) {
    NSMutableString *returnString = [[NSMutableString alloc ] init];
    int n;
    for(n = 0; n < 8; n++) {
        if ((x & 0x80) != 0) {
            [returnString appendString:@"1"];
        } else {
            [returnString appendString:@"0"];
        }
        x = x<< 1;
    }
    return [returnString copy];
}
// 二进制转许可
NSString *bin2perms(NSString *binaryValue) {
    NSMutableString *returnString = [[NSMutableString alloc] init];
    NSRange subStringRange;
    subStringRange.length = 1;
    NSString *replaceWithChar = nil;
    
    for (int n = 0; n < [binaryValue length]; n++) {
        subStringRange.location = n;
        // take the char
        // if pos = 0, 3,6
        if (n == 0 || n == 3 || n ==6) {
            replaceWithChar = @"r";
        }
        if(n == 1 || n == 4 || n ==7) {
            replaceWithChar = @"w";
        }
        if (n == 2 || n == 5 || n ==7) {
            replaceWithChar = @"x";
        }
        
        if ([[binaryValue substringWithRange:subStringRange] isEqualToString:@"1"]) {
            [returnString appendString:replaceWithChar];
        } else {
            [returnString appendString:@"-"];
        }
    }
    return [returnString copy];
}
