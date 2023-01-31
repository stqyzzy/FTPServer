//
//  YZZYViewController.m
//  YZZYFTPServer
//
//  Created by stqyzzy on 12/27/2022.
//  Copyright (c) 2022 stqyzzy. All rights reserved.
//

#import "YZZYViewController.h"
#import "YZZYFTPServer.h"
#import "YZZYFTPHelper.h"
@interface YZZYViewController ()
@property (nonatomic, strong) UILabel *addressInfoLabel;
@property (nonatomic, strong) YZZYFTPServer *ftpServer;
@property (nonatomic, assign) NSUInteger ftpPort;
@end

@implementation YZZYViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.addressInfoLabel.text = [NSString stringWithFormat:@"ftp://%@:%u", [YZZYFTPHelper localIPAddress], self.ftpPort];
    
    [self generateTestFiles];
    
    self.ftpServer = [[YZZYFTPServer alloc] initWithPort:self.ftpPort withDir:NSHomeDirectory() notifyObject:self];
}

- (void)generateTestFiles {
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    NSDate *nowDate = [NSDate date];
    
    // Documents文件夹
    fmt.dateFormat = @"YY-MM-dd HH:mm:ss";
    NSString *docTextString = [NSString stringWithFormat:@"documents text generate by XMFTPServer at %@", [fmt stringFromDate:nowDate]];
    fmt.dateFormat = @"YYYYMMddHHmmss";
    NSString *documentsFolderPathSthring = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *filePathString = [documentsFolderPathSthring stringByAppendingPathComponent:[NSString stringWithFormat:@"xmftp_doc_test_files_%@", [fmt stringFromDate:nowDate]]];
    [docTextString writeToFile:filePathString atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    // Library
    fmt.dateFormat = @"YYYY-MM-dd HH:mm:ss";
    NSString *libText = [NSString stringWithFormat:@"library text generate by XMFTPServer at %@", [fmt stringFromDate:nowDate]];
    fmt.dateFormat = @"YYYYMMddHHmmss";
    [libText writeToFile:[[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject]stringByAppendingPathComponent:[NSString stringWithFormat:@"xmftp_lib_test_files_%@", [fmt stringFromDate:nowDate]]] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    // tmp
    fmt.dateFormat = @"YYYY-MM-dd HH:mm:ss";
    NSString *tmpText = [NSString stringWithFormat:@"tmp text generate by XMFTPServer at %@", [fmt stringFromDate:nowDate]];
    fmt.dateFormat = @"YYYYMMddHHmmss";
    [tmpText writeToFile:[NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"xmftp_tmp_test_files_%@", [fmt stringFromDate:nowDate]]] atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSUInteger)ftpPort {
    return 23333;
}

- (UILabel *)addressInfoLabel {
    if (_addressInfoLabel == nil) {
        _addressInfoLabel = [[UILabel alloc] init];
        _addressInfoLabel.frame = CGRectMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2, 250, 100);
        [self.view addSubview:_addressInfoLabel];
    }
    return _addressInfoLabel;
}
@end
