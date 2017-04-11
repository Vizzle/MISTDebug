//
//  MSTDebugConnection.m
//  MIST
//
//  Created by wuwen on 2017/1/24.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#import "MSTDebugConnection.h"
#import <CocoaHTTPServer/HTTPFileResponse.h>
#import <CocoaHTTPServer/HTTPServer.h>
#import "MSTDebugDefine.h"
#import "MSTDebugger.h"
#import "MSTDebugConfig.h"

@implementation MSTDebugConnection

+ (void)startServer {
    static HTTPServer *_httpServer = nil;
    NSString *docPath = [[NSBundle mainBundle] resourcePath];
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _httpServer = [[HTTPServer alloc] init];
        [_httpServer setConnectionClass:[MSTDebugConnection class]];
        [_httpServer setPort:[MSTDebugger defaultDebugger].clientPort];
        [_httpServer setDocumentRoot:docPath];
    });
    
    if (!_httpServer.isRunning) {
        NSError *error = nil;
        if (![_httpServer start:&error]) {
            MSTDLog(@"Failed to run HTTP Server: %@", error);
        } else {
            MSTDLog(@"HTTP server running!");
        }
    }
}

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
    if ([path isEqualToString:@"/refresh"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([MSTDebugConfig sharedConfig].localTemplateMode) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:MISTDebugShouldReloadNotification object:nil];
                });
            }
        });
    }
    return nil;
}


@end
