//
//  YZZYViewController.m
//  YZZYFTPServer
//
//  Created by stqyzzy on 12/27/2022.
//  Copyright (c) 2022 stqyzzy. All rights reserved.
//

#import "YZZYViewController.h"
#import "YZZYFTPServer.h"

@interface YZZYViewController ()
@property (nonatomic, strong) YZZYFTPServer *ftpServer;
@property (nonatomic, assign) NSUInteger ftpPort;
@end

@implementation YZZYViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.ftpServer = [[YZZYFTPServer alloc] initWithPort:self.ftpPort withDir:NSHomeDirectory() notifyObject:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSUInteger)ftpPort {
    return 23333;
}
@end
