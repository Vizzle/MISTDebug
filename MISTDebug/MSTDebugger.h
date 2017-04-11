//
//  MSTDebugger.h
//  MIST
//
//  Created by wuwen on 2017/1/23.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const MISTDebugShouldReloadNotification;

@interface MSTDebugger : NSObject

/**
 * You should customize client port and server port if you are
 * working with 2 or more different mist projects simultaneously.
 *
 * Use:
 *    [MSTDebugger defaultDebugger].clientPort = xxxx
 *    [MSTDebugger defaultDebugger].serverPort = xxxx
 * 
 * Default value: client-10002, server-10001
 */
@property (nonatomic, assign) UInt16 clientPort;

@property (nonatomic, assign) UInt16 serverPort;

+ (instancetype)defaultDebugger;

- (void)startWithDownloader:(Class)downloaderClass;

@end
