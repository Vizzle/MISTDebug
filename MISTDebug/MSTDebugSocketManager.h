//
//  MSTDebugSocketManager.h
//  MIST
//
//  Created by wuwen on 2017/1/24.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const MISTDebugSocketDidRecivedDataNotification;
FOUNDATION_EXPORT NSString *const MISTDebugSocketDataKey;

@interface MSTDebugSocketManager : NSObject

+ (instancetype)manager;

- (void)connectToHost:(NSString *)host port:(NSString *)port;

@end
