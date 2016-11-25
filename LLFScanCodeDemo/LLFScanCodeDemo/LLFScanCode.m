//
//  LLFScanCode.m
//  LLFScanCodeDemo
//
//  Created by gary.liu on 16/11/24.
//  Copyright © 2016年 gary.liu. All rights reserved.
//

#import "LLFScanCode.h"

#define SCREEN_WIDTH    [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT   [UIScreen mainScreen].bounds.size.height

#define SCAN_MIN_X      50 // 扫描框的坐标
#define SCAN_MIN_Y      50 
#define SCAN_WIDTH      SCREEN_WIDTH - SCAN_MIN_X * 2   // 扫描框的宽度
#define SCAN_HEIGHT     SCAN_WIDTH  // 扫描框的高度

@interface LLFScanCode () <AVCaptureMetadataOutputObjectsDelegate>

// 扫描框的设置
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) BOOL upOrdown;
@property (nonatomic, assign) NSInteger num;
@property (nonatomic, strong) UIImageView *lineImg;
@property (nonatomic, strong) UIImageView *borderImg;

@property (nonatomic, strong) dispatch_queue_t dispatchQueue;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *captureVidePreviewLayer;
@property (nonatomic, strong) AVCaptureMetadataOutput *captureMetadataOutput;
// 扫描码
@property (nonatomic, copy) NSString *code;

@end

@implementation LLFScanCode 

// 单例
+ (instancetype)shareInstance {
    static LLFScanCode *scanCode = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        scanCode = [[LLFScanCode alloc]init];
    });
    
    return scanCode;
}

// 开始扫描
+ (void)start {
    LLFScanCode *scanCode = [LLFScanCode shareInstance];
    
    if (scanCode.captureSession == nil) {
        
    }
    else {
        [scanCode.captureMetadataOutput setMetadataObjectsDelegate:scanCode queue:dispatch_get_main_queue()];
        [scanCode.captureSession startRunning];
    }
}

// 结束扫描
+ (void)stop{
    LLFScanCode *scanCode = [LLFScanCode shareInstance];
    scanCode.code = nil;
    [scanCode.captureMetadataOutput setMetadataObjectsDelegate:nil queue:dispatch_get_main_queue()];
    [scanCode.captureSession stopRunning];
}

- (void)dealloc{
    LLFScanCode *scanCode = [LLFScanCode shareInstance];
    [[NSNotificationCenter defaultCenter]removeObserver:scanCode];
    [scanCode.timer invalidate];
    scanCode.timer = nil;
}

// 延时执行
- (void)lazyExcute{
    LLFScanCode *scanCode = [LLFScanCode shareInstance];
    if (![scanCode isAuthorizationCamera]) {
        return;
    }
    // 添加通知设置。扫描范围
    [[NSNotificationCenter defaultCenter]addObserver:scanCode selector:@selector(notificationHandle:) name:AVCaptureInputPortFormatDescriptionDidChangeNotification object:nil];
    
    
    
}

// 摄像头权限
- (BOOL)isAuthorizationCamera {
    return YES;
}
// 扫描范围
- (void)notificationHandle:(NSNotification *)nati {
    
}
// 开始扫描
- (void)startScanWithView:(UIViewController *)vc {
    NSError *error;
    LLFScanCode *scanCode = [LLFScanCode shareInstance];
    // 设置设备
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo]; // 设置视频类型
    // 设置获取设备输入
    AVCaptureDeviceInput *deviceInput = [[AVCaptureDeviceInput alloc]initWithDevice:captureDevice error:&error];
    if (!deviceInput) { // 如果无法获取设备输入
        NSLog(@"%@",error.description);
    }
    //设置设备输出
    scanCode.captureMetadataOutput = [[AVCaptureMetadataOutput alloc]init];
    // 设置捕捉会话
    scanCode.captureSession = [[AVCaptureSession alloc]init];
    [scanCode.captureSession addInput:deviceInput]; // 设备输入
    [scanCode.captureSession addOutput:scanCode.captureMetadataOutput]; // 设备输出
    // 设置代理
    [scanCode.captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    // 设置解析数据类型,需要识别的各种码
    [scanCode.captureMetadataOutput setMetadataObjectTypes:@[AVMetadataObjectTypeEAN13Code,
          AVMetadataObjectTypeEAN8Code,
          AVMetadataObjectTypeCode128Code,
          AVMetadataObjectTypeQRCode,
          AVMetadataObjectTypeUPCECode]];
    // 设置展示layer
    scanCode.captureVidePreviewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:scanCode.captureSession];
    [scanCode.captureVidePreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    scanCode.captureVidePreviewLayer.frame = CGRectMake(0, 0, CGRectGetWidth(vc.view.frame), CGRectGetHeight(vc.view.frame));
    [vc.view.layer addSublayer:scanCode.captureVidePreviewLayer];
    
    // 开始执行摄像头
    [scanCode.captureSession startRunning];
}

// 添加图层
- (void)addMaskWithView:(UIViewController *)vc {
    UIView *maskView = [[UIView alloc]init];
    maskView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    maskView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
    [vc.view addSubview:maskView];
    // 创建路径 绘制和透明黑色遮盖一样的矩形
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, CGRectGetWidth(maskView.frame), CGRectGetHeight(maskView.frame))];
    // 路径取反 绘制中间空白透明的矩形，并且取反路径。这样整个绘制的范围就只剩下，中间的矩形和边界的部分
    [path appendPath:[[UIBezierPath bezierPathWithRect:CGRectMake(SCAN_MIN_X, SCAN_MIN_Y, SCAN_WIDTH, SCAN_HEIGHT)]bezierPathByReversingPath]];
    
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    // 将路径交给layer绘制
    shapeLayer.path = path.CGPath;
    // 设置遮盖层
    [maskView.layer setMask:shapeLayer];
    
    // 扫描框的图片
    
}

// 动画效果
- (void)animation {
    if (_upOrdown == NO) {
        _num++;
        _lineImg.frame = CGRectMake(0, 2 * _num, SCAN_WIDTH, 2);
        if (2 * _num - 1 == (int)(SCAN_HEIGHT) || 2 * _num == (int)(SCAN_HEIGHT)) {
            _upOrdown = YES;
        }
        else {
            _num--;
            _lineImg.frame = CGRectMake(0, 2 * _num, SCAN_WIDTH, 2);
            if (_num == 0) {
                _upOrdown = NO;
            }
        }
    }
}

@end
