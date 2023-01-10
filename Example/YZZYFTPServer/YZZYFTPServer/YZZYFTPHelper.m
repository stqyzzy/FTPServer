//
//  YZZYFTPHelper.m
//  YZZYFTPServer_Example
//
//  Created by 云中追月 on 2023/1/10.
//  Copyright © 2023 stqyzzy. All rights reserved.
//

#import "YZZYFTPHelper.h"

@interface YZZYFTPHelper()

@end

@implementation YZZYFTPHelper

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
NSString *createList(NSString *directoryPath) {
    NSFileManager *fileManaer = [NSFileManager defaultManager];
    NSDictionary *fileAtttributes;
}

#pragma mark -
#pragma mark - <#custom#> Delegate

#pragma mark -
#pragma mark - private methods

#pragma mark -
#pragma mark - getters and setters


@end
