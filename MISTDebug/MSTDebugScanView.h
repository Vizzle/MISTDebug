//
//  MSTDebugScanView.h
//  MIST
//
//  Created by wuwen on 2017/1/24.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MSTDebugScanView;

@protocol MSTDebugScanViewDelegate <NSObject>

@optional

- (void)scanView:(MSTDebugScanView *)scanView didGetResult:(NSString *)result;

@end

@interface MSTDebugScanView : UIView

@property (nonatomic, weak) id<MSTDebugScanViewDelegate> delegate;
@property (nonatomic, strong) NSString *tipText;

+ (instancetype)sharedView;

- (void)show;

- (void)dismiss;

@end
