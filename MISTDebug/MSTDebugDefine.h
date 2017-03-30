//
//  MSTDebugDefine.h
//  MIST
//
//  Created by wuwen on 2017/1/24.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef DEBUG
#define MSTDLog(fmt, ...) NSLog(@"[MISTDebug] "fmt, ##__VA_ARGS__)
#else
#define MSTDLog(fmt, ...)
#endif
