//
//  MSTDebugDownloader.m
//  MIST
//
//  Created by wuwen on 2017/1/23.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#import "MSTDebugDownloader.h"
//#import "VZMistTemplateManager.h"
#import "MSTDebugConfig.h"
#import <objc/runtime.h>
#import "MSTDebugDefine.h"
#import <UIKit/UIKit.h>

@interface VZMistTemplate : NSObject

- (instancetype)initWithTemplateId:(NSString *)tplId content:(NSDictionary *)content;

@end

static void downloadTemplates(id self, SEL _cmd, NSArray* tplIds, void(^completion)(NSDictionary<NSString *, VZMistTemplate *> *), NSDictionary *options) {
    [[MSTDebugDownloader sharedInstance] downloadTemplates:tplIds completion:completion options:options];
}

@interface MSTDebugDownloader ()

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, weak) Class downloaderClass;

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
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(configDidChanged:)
                                                     name:MISTDebugConfigDidChangedNotification
                                                   object:nil];
    }
    return self;
}

- (void)downloadTemplates:(NSArray* )tplIds
               completion:(void(^)(NSDictionary<NSString *, NSDictionary *> *)) completion
                  options:(NSDictionary* )opt {
    __block NSMutableDictionary *results = [NSMutableDictionary dictionary];
    __block NSInteger count = 0;
    __block NSMutableArray *failedTemplates = [NSMutableArray array];
    for (NSString *tplId in tplIds) {
        [self downloadTemplate:tplId completion:^(NSDictionary *result) {
            dispatch_async(dispatch_get_main_queue(), ^{
                ++count;
                if (result) {
                    VZMistTemplate *template = [[VZMistTemplate alloc] initWithTemplateId:tplId content:result];
                    [results setValue:template forKey:tplId];
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

- (void)downloadTemplate:(NSString *)templateId completion:(void(^)(NSDictionary *))completion {
    NSString *baseURL = [NSString stringWithFormat:@"http://%@:10001", [MSTDebugConfig sharedConfig].localIP];
    NSString *URL = [NSString stringWithFormat:@"%@/%@.mist#t=%lf", baseURL, templateId, [[NSDate date] timeIntervalSince1970]];
    NSURLSessionDataTask *task = [self.session dataTaskWithURL:[NSURL URLWithString:URL] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSDictionary *result = nil;
        if (!error && data) {
            result = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
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

static IMP originalImp = NULL;

- (void)startWithDownloader:(Class)downloaderClass {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if (![downloaderClass instancesRespondToSelector:@selector(downloadTemplates:completion:options:)]) {
#pragma clang diagnostic pop
        return;
    }
    self.downloaderClass = downloaderClass;
    if ([MSTDebugConfig sharedConfig].localTemplateMode) {
        [self startIntercept];
    }
}

- (void)startIntercept {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    Method method = class_getInstanceMethod(self.downloaderClass, @selector(downloadTemplates:completion:options:));
#pragma clang diagnostic pop
    IMP imp = method_getImplementation(method);
    if (!originalImp) {
        originalImp = imp;
    }
    if (imp != (IMP)downloadTemplates) {
        method_setImplementation(method, (IMP)downloadTemplates);
    }
}

- (void)stopIntercept {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    Method method = class_getInstanceMethod(_downloaderClass, @selector(downloadTemplates:completion:options:));
#pragma clang diagnostic pop
    if (originalImp) {
        method_setImplementation(method, originalImp);
    }
}

- (void)configDidChanged:(NSNotification *)notification {
    if ([MSTDebugConfig sharedConfig].localTemplateMode) {
        [self startIntercept];
    } else {
        [self stopIntercept];
    }
}

@end
