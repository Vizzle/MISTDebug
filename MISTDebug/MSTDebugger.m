//
//  MSTDebugger.m
//  MIST
//
//  Created by wuwen on 2017/1/23.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#import "MSTDebugger.h"
#import "MSTDebugDownloader.h"
#import "MSTDebugSocketManager.h"
#import "MSTDebugConfig.h"
#import "MSTDebugDefine.h"
#import "MSTDebugConnection.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

NSString *const MISTDebugShouldReloadNotification = @"MISTDebugShouldReload";

@implementation MSTDebugger

+ (instancetype)defaultDebugger {
    static MSTDebugger *_defaultDebugger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultDebugger = [[self alloc] init];
    });
    return _defaultDebugger;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didReceiveData:)
                                                     name:MISTDebugSocketDidRecivedDataNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(configDidChanged:)
                                                     name:MISTDebugConfigDidChangedNotification
                                                   object:nil];
    }
    return self;
}

- (void)didReceiveData:(NSNotification *)notification {
    NSString *data = notification.userInfo[MISTDebugSocketDataKey];
    if ([data isEqualToString:@"refresh"]) {
        if ([MSTDebugConfig sharedConfig].localTemplateMode) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:MISTDebugShouldReloadNotification object:nil];
            });
        }
    }
}

- (void)configDidChanged:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:MISTDebugShouldReloadNotification object:nil];
        NSString *notice = [NSString stringWithFormat:@"%@", [MSTDebugConfig sharedConfig].localTemplateMode ? @"本地模版" : @"网关模版"];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:notice delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
        [alert show];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [alert dismissWithClickedButtonIndex:0 animated:YES];
        });
    });
}

- (void)startWithDownloader:(Class)downloaderClass {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if (![downloaderClass instancesRespondToSelector:@selector(downloadTemplates:completion:options:)]) {
#pragma clang diagnostic pop
        MSTDLog(@"Failed to start debug mode, Template downloader must implement [downloadTemplates:completion:options:]");
        return;
    }
    [MSTDebugConfig sharedConfig];
    [MSTDebugConnection startServer];
    [[MSTDebugDownloader sharedInstance] startWithDownloader:downloaderClass];
}

@end
