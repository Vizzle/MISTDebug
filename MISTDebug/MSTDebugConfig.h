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
@property (nonatomic, copy) NSString *localIP;
@property (nonatomic, copy) NSString *localPort;
@property (nonatomic, copy) NSString *socketPort;

+ (instancetype)sharedConfig;

@end
