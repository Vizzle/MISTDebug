//
//  MSTDebugSocketManager.m
//  MIST
//
//  Created by wuwen on 2017/1/24.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#import "MSTDebugSocketManager.h"
#import <UIKit/UIKit.h>
#include <arpa/inet.h>
#import <CocoaAsyncSocket/GCDAsyncSocket.h>
#import "MSTDebugDefine.h"

NSString *const MISTDebugSocketDataKey = @"MISTDebugSocketData";
NSString *const MISTDebugSocketDidRecivedDataNotification = @"MISTDebugSocketDidRecivedData";

enum {
    SocketOfflineByServer,//服务器掉线，默认为0
    SocketOfflineByUser,  //用户主动cut
};

@interface MSTDebugSocketManager () <GCDAsyncSocketDelegate>

@property (nonatomic, strong) GCDAsyncSocket *socket;
@property (nonatomic, strong) NSString *socketHost;
@property (nonatomic, assign) UInt16 socketPort;
@property (nonatomic, assign) BOOL connected;

@end

@implementation MSTDebugSocketManager

+ (instancetype)manager {
    static MSTDebugSocketManager *_manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [[self alloc] init];
    });
    return _manager;
}

- (void)connectToHost:(NSString *)host port:(NSString *)port {
    self.socketHost = host;
    self.socketPort = [port integerValue];
    [self connect];
}

- (void)connect {
    self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    NSError *error = nil;
    [self.socket connectToHost:self.socketHost onPort:self.socketPort withTimeout:10 error:&error];
    if (error) {
        MSTDLog(@"Connection failed with error %@", error);
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.socket readDataWithTimeout:-1 tag:0];
    });
}

- (void)disconnect {
    self.connected = NO;
    self.socket.userData = @(SocketOfflineByUser);
    [self.socket disconnect];
}

#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    self.connected = YES;
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"连接成功" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    [alert show];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [alert dismissWithClickedButtonIndex:0 animated:YES];
    });
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    if (!data) {
        return;
    }
    
    NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:MISTDebugSocketDidRecivedDataNotification
                                                        object:nil
                                                      userInfo:@{MISTDebugSocketDataKey: message}];
    
    [self.socket readDataWithTimeout:-1 tag:0];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    self.connected = false;
    
    if ([sock.userData isEqual:@(SocketOfflineByServer)]) {
        [self connect];
    } else if ([sock.userData isEqual:@(SocketOfflineByUser)]) {
        return;
    }
}

@end
