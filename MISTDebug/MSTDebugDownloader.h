//
//  MSTDebugDownloader.h
//  MIST
//
//  Created by wuwen on 2017/1/23.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MSTDebugDownloader : NSObject

+ (instancetype)sharedInstance;

- (void)startWithDownloader:(Class)downloaderClass;

- (void)downloadTemplates:(NSArray* )tplIds
               completion:(void(^)(NSDictionary<NSString *, NSDictionary *> *)) completion
                  options:(NSDictionary* )opt;

- (void)downloadTemplate:(NSString *)templateId completion:(void(^)(NSDictionary *))completion;

@end
