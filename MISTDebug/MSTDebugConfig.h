//
//  MSTDebugConfig.h
//  MIST
//
//  Created by wuwen on 2017/1/24.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const MISTDebugConfigDidChangedNotification;

@interface MSTDebugConfig : NSObject

@property (nonatomic, assign) BOOL localTemplateMode;
@property (nonatomic, copy) NSString *serverIP;
@property (nonatomic, copy) NSString *serverPort;
@property (nonatomic, copy) NSString *socketPort;

+ (instancetype)sharedConfig;

//for MSTDebugger use
- (void)updateServerPort:(UInt16)serverPort;

@end
