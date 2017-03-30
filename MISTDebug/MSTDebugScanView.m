//
//  MSTDebugScanView.m
//  MIST
//
//  Created by wuwen on 2017/1/24.
//  Copyright © 2017年 Vizlab. All rights reserved.
//

#import "MSTDebugScanView.h"
#import <AVFoundation/AVFoundation.h>

@interface MSTDebugScanMaskView : UIView

@end

@implementation MSTDebugScanMaskView

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [[[UIColor blackColor] colorWithAlphaComponent:0.5] setFill];
    
    CGMutablePathRef screenPath = CGPathCreateMutable();
    CGPathAddRect(screenPath, NULL, self.bounds);
    
    CGMutablePathRef scanPath = CGPathCreateMutable();
    CGPathAddRect(scanPath, NULL, CGRectMake(self.bounds.size.width/2-130, self.bounds.size.height/2-130, 260, 260));
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddPath(path, NULL, screenPath);
    CGPathAddPath(path, NULL, scanPath);
    
    CGContextAddPath(ctx, path);
    CGContextDrawPath(ctx, kCGPathEOFill);
    
    CGPathRelease(screenPath);
    CGPathRelease(scanPath);
    CGPathRelease(path);
}

@end

@interface MSTDebugScanView () <AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) UILabel *tip;

@end

@implementation MSTDebugScanView

+ (instancetype)sharedView {
    static MSTDebugScanView *_view = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _view = [[self alloc] init];
    });
    return _view;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:[UIScreen mainScreen].bounds];
    if (self) {
        UIView *maskView = [[MSTDebugScanMaskView alloc] initWithFrame:self.bounds];
        maskView.backgroundColor = [UIColor clearColor];
        [self addSubview:maskView];
        
        _tip = [[UILabel alloc] initWithFrame:CGRectMake(15, 88, self.frame.size.height-30, 32)];
        _tip.adjustsFontSizeToFitWidth = YES;
        _tip.backgroundColor = [UIColor colorWithWhite:0.15 alpha:0.64];
        _tip.textAlignment = NSTextAlignmentCenter;
        _tip.font = [UIFont systemFontOfSize:20];
        _tip.textColor = [UIColor colorWithRed:148/255.0 green:199/255.0 blue:111/255.0 alpha:1];
        _tip.hidden = YES;
        [self addSubview:_tip];
        
        UIButton *close = [UIButton buttonWithType:UIButtonTypeCustom];
        close.frame = CGRectMake(self.frame.size.width/2-33, self.frame.size.height - 120, 66, 66);
        close.titleLabel.font = [UIFont systemFontOfSize:52];
        [close setTitle:@"❌" forState:UIControlStateNormal];
        [close setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [close addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:close];
    }
    return self;
}

- (void)show {
#if TARGET_IPHONE_SIMULATOR
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"模拟器不支持扫码" delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    [alert show];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [alert dismissWithClickedButtonIndex:0 animated:YES];
    });
    
    return;
#endif
    
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(status == AVAuthorizationStatusNotDetermined){
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if(granted){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self show];
                });
            } else {
                return;
            }
        }];
        
        return;
    }
    
    if (!self.session) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
        AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
        [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
        
        self.session = [[AVCaptureSession alloc] init];
        [self.session setSessionPreset:AVCaptureSessionPresetHigh];
        [self.session addInput:input];
        [self.session addOutput:output];
        
        output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
        [self.session startRunning];
    } else {
        if (![self.session isRunning]) {
            [self.session startRunning];
        }
    }
    
    AVCaptureVideoPreviewLayer *layer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    layer.frame = self.layer.bounds;
    layer.videoGravity=AVLayerVideoGravityResizeAspectFill;
    [self.layer insertSublayer:layer atIndex:0];
    
    [[UIApplication sharedApplication].keyWindow addSubview:self];
}

- (void)dismiss {
    [self.session stopRunning];
    CALayer *previewLayer = self.layer.sublayers[0];
    [previewLayer removeFromSuperlayer];
    [self removeFromSuperview];
}

- (void)setTipText:(NSString *)tipText {
    self.tip.text = tipText;
    if (!tipText.length) {
        self.tip.hidden = YES;
    } else {
        self.tip.hidden = NO;
    }
}

- (NSString *)tipText {
    return self.tip.text;
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    if (metadataObjects.count > 0) {
        AVMetadataMachineReadableCodeObject *metadataObject = [metadataObjects objectAtIndex: 0];
        if ([self.delegate respondsToSelector:@selector(scanView:didGetResult:)]) {
            [self.delegate scanView:self didGetResult:metadataObject.stringValue];
        }
    }
}

@end
