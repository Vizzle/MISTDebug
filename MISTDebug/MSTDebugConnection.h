//
//  MSTDebugConnection.h
//  MIST
//
//  Created by wuwen on 2017/1/24.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#import <CocoaHTTPServer/HTTPConnection.h>

@interface MSTDebugConnection : HTTPConnection

+ (void)startServer;

@end
