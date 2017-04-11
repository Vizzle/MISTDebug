//
//  MSTDebugConfig.m
//  MIST
//
//  Created by wuwen on 2017/1/24.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#import "MSTDebugConfig.h"
#import <Tweaks/FBTweak.h>
#import <Tweaks/FBTweakInline.h>
#import <Tweaks/FBTweakViewController.h>
#import <objc/runtime.h>
#import "MSTDebugDefine.h"
#import "MSTDebugScanView.h"
#import "MSTDebugSocketManager.h"

NSString *const MISTDebugConfigDidChangedNotification = @"MISTDebugConfigDidChanged";

#define kTweakId @"MIST-DEBUG"

@interface UIApplication (IFM) <FBTweakViewControllerDelegate>

@end


@implementation UIApplication (IFM)

+ (void)load
{
    Method original = class_getInstanceMethod(self, @selector(sendEvent:));
    Method swizzled = class_getInstanceMethod(self, @selector(ifm_sendEvent:));
    method_exchangeImplementations(original, swizzled);
}

- (void)ifm_sendEvent:(UIEvent *)event
{
    [self ifm_sendEvent:event];
    if (event && (event.subtype == UIEventSubtypeMotionShake)) {
        if ([[event valueForKey:@"shakeState"] boolValue]) {
            
            UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
            while (vc != nil && ![vc isKindOfClass:[FBTweakViewController class]]) {
                vc = vc.presentedViewController;
            }
            if (vc) {
                return;
            }
            
            FBTweakViewController *viewController = [[FBTweakViewController alloc] initWithStore:[FBTweakStore sharedInstance] category:kTweakId];
            viewController.tweaksDelegate = self;
            [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:viewController animated:YES completion:nil];
        }
    }
}

- (void)tweakViewControllerPressedDone:(FBTweakViewController *)tweakViewController
{
    [tweakViewController dismissViewControllerAnimated:YES completion:NULL];
    [[NSNotificationCenter defaultCenter] postNotificationName:MISTDebugConfigDidChangedNotification object:nil];
}

@end

@interface MSTDebugConfig () <MSTDebugScanViewDelegate>

@end

@implementation MSTDebugConfig

+ (instancetype)sharedConfig {
    static MSTDebugConfig *_config = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _config = [[self alloc] init];
    });
    return _config;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        FBTweakBind(self, localTemplateMode, kTweakId, @"MIST", @"本地模板", YES);
        FBTweakBind(self, serverIP, kTweakId, @"MIST", @"调试服务器IP", @"127.0.0.1");
        FBTweakBind(self, serverPort, kTweakId, @"MIST", @"调试服务器Port", @"10001");
        FBTweakBind(self, socketPort, kTweakId, @"MIST", @"Socket Port", @"");
        
        [MSTDebugScanView sharedView].delegate = self;
        [MSTDebugScanView sharedView].tipText = @"终端输入 mist -q 扫码连接";
        FBTweakAction(kTweakId, @"MIST", @"扫码连接", ^() {
            [[MSTDebugScanView sharedView] show];
        });        
    }
    return self;
}

- (void)reloadTweakView {
    UIViewController *currentVC = [UIApplication sharedApplication].keyWindow.rootViewController.presentedViewController;
    if (![currentVC isKindOfClass:[FBTweakViewController class]]) {
        return;
    }
    
    FBTweakViewController *tweakController = (FBTweakViewController *)currentVC;
    UIViewController *controller = [tweakController.viewControllers lastObject]; //_FBTweakCollectionViewController
    UITableView *tableView = (UITableView *)[controller valueForKey:@"tableView"];
    
    if (!tableView || ![tableView isKindOfClass:[UITableView class]]) {
        return;
    }
    
    [tableView reloadData];
}

#pragma mark - MSTDebugScanViewDelegate

- (void)scanView:(MSTDebugScanView *)scanView didGetResult:(NSString *)result {
    [[MSTDebugScanView sharedView] dismiss];
    
    NSDictionary *config = [NSJSONSerialization JSONObjectWithData:[(NSString *)result dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
    if (!config.allKeys.count) {
        return;
    }
    
    FBTweakCategory *category = [[FBTweakStore sharedInstance] tweakCategoryWithName:kTweakId];
    FBTweakCollection *collection = [category tweakCollectionWithName:@"MIST"];
    [collection tweakWithIdentifier:@"FBTweak:MIST-DEBUG-MIST-调试服务器IP"].currentValue = config[@"ip"]?:@"127.0.0.1";
    [collection tweakWithIdentifier:@"FBTweak:MIST-DEBUG-MIST-调试服务器Port"].currentValue = config[@"port"]?:@"10001";
    [collection tweakWithIdentifier:@"FBTweak:MIST-DEBUG-MIST-Socket Port"].currentValue = config[@"wsport"]?:@"";
    [self reloadTweakView];
    
    [[MSTDebugSocketManager manager] connectToHost:self.serverIP port:self.socketPort];
}

#pragma mark - Public

- (void)updateServerPort:(UInt16)serverPort {
    if (!serverPort) {
        return;
    }
    
    FBTweakCategory *category = [[FBTweakStore sharedInstance] tweakCategoryWithName:kTweakId];
    FBTweakCollection *collection = [category tweakCollectionWithName:@"MIST"];
    [collection tweakWithIdentifier:@"FBTweak:MIST-DEBUG-MIST-调试服务器Port"].currentValue = [NSString stringWithFormat:@"%d", serverPort];
    [self reloadTweakView];
}
@end
