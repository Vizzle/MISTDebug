//
//  MSTDebugDownloader.m
//  MIST
//
//  Created by wuwen on 2017/1/23.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#import "MSTDebugDownloader.h"
#import "MSTDebugConfig.h"
#import <objc/runtime.h>
#import "MSTDebugDefine.h"
#import <UIKit/UIKit.h>

static void downloadTemplates(id self, SEL _cmd, NSArray* tplIds, MSTDownloadResult completion, NSDictionary *options) {
    if (![MSTDebugConfig sharedConfig].localTemplateMode) {
        // Orignal method
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        SEL selector = @selector(mst_downloadTemplates:completion:options:);
#pragma clang diagnostic pop
        NSMethodSignature *methodSignature = [self methodSignatureForSelector:selector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
        invocation.selector = selector;
        [invocation setArgument:&tplIds atIndex:2];
        [invocation setArgument:&completion atIndex:3];
        [invocation setArgument:&options atIndex:4];
        [invocation invokeWithTarget:self];
        return;
    }
    [[MSTDebugDownloader sharedInstance] downloadTemplates:tplIds completion:completion options:options];
}

@interface MSTDebugDownloader ()

@property (nonatomic, strong) NSURLSession *session;

@end

@implementation MSTDebugDownloader

+ (instancetype)sharedInstance {
    static MSTDebugDownloader * _sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [MSTDebugDownloader new];
    });
    return _sharedInstance;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)downloadTemplates:(NSArray* )tplIds
               completion:(MSTDownloadResult)completion
                  options:(NSDictionary* )opt {
    __block NSMutableDictionary *results = [NSMutableDictionary dictionary];
    __block NSInteger count = 0;
    __block NSMutableArray *failedTemplates = [NSMutableArray array];
    for (NSString *tplId in tplIds) {
        [self downloadTemplate:tplId completion:^(NSString *result) {
            dispatch_async(dispatch_get_main_queue(), ^{
                ++count;
                if (result) {
                    results[tplId] = result;
                } else {
                    [failedTemplates addObject:tplId];
                }
                if (count == tplIds.count) {
                    if (failedTemplates.count > 0) {
                        NSString *message = [NSString stringWithFormat:@"确认执行 mist server \n出错模板：%@", [failedTemplates componentsJoinedByString:@", "]];
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"模板加载失败"
                                                                        message:message
                                                                       delegate:nil
                                                              cancelButtonTitle:@"确定"
                                                              otherButtonTitles:nil];
                        [alert show];
                    }
                    if (completion) {
                        completion(results);
                    }
                }
            });
        }];
    }
}

- (void)downloadTemplate:(NSString *)templateId completion:(void(^)(NSString *))completion {
    NSString *baseURL = [NSString stringWithFormat:@"http://%@:%@", [MSTDebugConfig sharedConfig].serverIP, [MSTDebugConfig sharedConfig].serverPort];
    NSString *URL = [NSString stringWithFormat:@"%@/%@.mist#t=%lf", baseURL, templateId, [[NSDate date] timeIntervalSince1970]];
    NSURLSessionDataTask *task = [self.session dataTaskWithURL:[NSURL URLWithString:URL] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSString *result = nil;
        if (!error && data) {
            result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
        if (completion) {
            completion(result);
        }
    }];
    [task resume];
}

- (NSURLSession *)session {
    if (!_session) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    }
    return _session;
}

- (void)startWithDownloader:(Class)downloaderClass {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if (![downloaderClass instancesRespondToSelector:@selector(downloadTemplates:completion:options:)]) {
#pragma clang diagnostic pop
        return;
    }
    
    // Add category method
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        Method originalMethod = class_getInstanceMethod(downloaderClass, @selector(downloadTemplates:completion:options:));
        struct objc_method_description *methodDescription = method_getDescription(originalMethod);
        SEL swizzledSel = @selector(mst_downloadTemplates:completion:options:);
        class_addMethod(downloaderClass, swizzledSel, (IMP)downloadTemplates, methodDescription->types);
        Method swizzledMethod = class_getInstanceMethod(downloaderClass, swizzledSel);
        method_exchangeImplementations(originalMethod, swizzledMethod);
#pragma clang diagnostic pop
    });
}

@end
