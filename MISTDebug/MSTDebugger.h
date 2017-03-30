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

+ (instancetype)defaultDebugger;

- (void)startWithDownloader:(Class)downloaderClass;

@end
