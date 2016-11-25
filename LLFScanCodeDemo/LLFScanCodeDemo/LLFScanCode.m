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

@interface LLFScanCode () <AVCaptureMetadataOutputObjectsDelegate>
// 显示的界面
@property (nonatomic, strong) UIViewController *vc;
// 扫描框的设置
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) BOOL upOrdown;
@property (nonatomic, assign) NSInteger num;
@property (nonatomic, strong) UIImageView *lineImg;
@property (nonatomic, strong) UIImageView *borderImg;
// 摄像头的设置
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *captureVidePreviewLayer;
@property (nonatomic, strong) AVCaptureMetadataOutput *captureMetadataOutput;
// 扫描码
@property (nonatomic, copy) NSString *code;
@property (nonatomic, assign) int flag; // 多次输出



@end

@implementation LLFScanCode 

#pragma mark -- 单例
+ (instancetype)shareInstance {
    static LLFScanCode *scanCode = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        scanCode = [[LLFScanCode alloc]init];
    });
    
    return scanCode;
}

#pragma mark -- 开始扫描
+ (void)startScanWithView:(UIViewController *)vc {
    LLFScanCode *scanCode = [LLFScanCode shareInstance];
    scanCode.vc = vc;
    if ((int)scanCode.scan_minX == 0) {
        scanCode.scan_minX = 50;
    }
    if ((int)scanCode.scan_minY == 0) {
        scanCode.scan_minY = 50;
    }
    if ((int)scanCode.scan_width == 0) {
        scanCode.scan_width = SCREEN_WIDTH - scanCode.scan_minX * 2;
    }
    if ((int)scanCode.scan_height == 0) {
        scanCode.scan_height = scanCode.scan_width;
    }
    
    if (scanCode.captureSession == nil) {
        [scanCode lazyExcute];
    }
    else {
        [scanCode.captureMetadataOutput setMetadataObjectsDelegate:scanCode queue:dispatch_get_main_queue()];
        [scanCode.captureSession startRunning];
    }
}

// 结束扫描
+ (void)stop {
    LLFScanCode *scanCode = [LLFScanCode shareInstance];
    
    scanCode.code = nil;
    [scanCode.captureMetadataOutput setMetadataObjectsDelegate:nil queue:dispatch_get_main_queue()];
    [scanCode.captureSession stopRunning];
}

- (void)dealloc {
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
    
    [scanCode startScan];
    [scanCode addMask];
}

#pragma mark -- 摄像头权限
- (BOOL)isAuthorizationCamera {
    LLFScanCode *scanCode = [LLFScanCode shareInstance];
    
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (status == AVAuthorizationStatusRestricted ||
        status == AVAuthorizationStatusDenied) {
        UIAlertController *alertContro = [UIAlertController alertControllerWithTitle:@"" message:@"请在iPhone的“设置-隐身-相机”选项中设置访问权限" preferredStyle:UIAlertControllerStyleAlert];
        [scanCode.vc presentViewController:alertContro animated:YES completion:nil];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                               style:UIAlertActionStyleDefault
                                                             handler:nil];
        UIAlertAction *sureAction = [UIAlertAction actionWithTitle:@"确定"
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * _Nonnull action) {
                                                               dispatch_after(0.1, dispatch_get_main_queue(), ^{
                                                                   [[UIApplication sharedApplication]openURL:[NSURL URLWithString:@"prefs:root=Privacy"]];
                                                               });
                                                           }];
        [alertContro addAction:cancelAction];
        [alertContro addAction:sureAction];
        
        return NO;
    }
    
    return YES;
}

#pragma mark -- 扫描范围
- (void)notificationHandle:(NSNotification *)noti {
    LLFScanCode *scanCode = [LLFScanCode shareInstance];
    
    AVCaptureMetadataOutput *output = (AVCaptureMetadataOutput *)_captureSession.outputs[0];
    CGRect rect = CGRectMake(scanCode.scan_minX, scanCode.scan_minY, scanCode.scan_width, scanCode.scan_height);
    output.rectOfInterest = [scanCode.captureVidePreviewLayer metadataOutputRectOfInterestForRect:rect];
}

#pragma mark -- 开始扫描设置
- (void)startScan {
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
    scanCode.captureVidePreviewLayer.frame = CGRectMake(0, 0, CGRectGetWidth(scanCode.vc.view.frame), CGRectGetHeight(scanCode.vc.view.frame));
    [scanCode.vc.view.layer addSublayer:scanCode.captureVidePreviewLayer];
    
    // 开始执行摄像头
    [scanCode.captureSession startRunning];
}

#pragma mark -- 添加图层
- (void)addMask {
    LLFScanCode *scanCode = [LLFScanCode shareInstance];
    
    UIView *maskView = [[UIView alloc]init];
    maskView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    maskView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
    [scanCode.vc.view addSubview:maskView];
    // 创建路径 绘制和透明黑色遮盖一样的矩形
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, CGRectGetWidth(maskView.frame), CGRectGetHeight(maskView.frame))];
    // 路径取反 绘制中间空白透明的矩形，并且取反路径。这样整个绘制的范围就只剩下，中间的矩形和边界的部分
    [path appendPath:[[UIBezierPath bezierPathWithRect:CGRectMake(scanCode.scan_minX, scanCode.scan_minY, scanCode.scan_width, scanCode.scan_height)]bezierPathByReversingPath]];
    
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    // 将路径交给layer绘制
    shapeLayer.path = path.CGPath;
    // 设置遮盖层
    [maskView.layer setMask:shapeLayer];
    
    // 扫描框的图片
    _num = 0; // 扫描线移动的次数
    _upOrdown = NO;
    
    _borderImg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"scan_border"]];
    _borderImg.frame = CGRectMake(scanCode.scan_minX, scanCode.scan_minY, scanCode.scan_width, scanCode.scan_height);
    [scanCode.vc.view addSubview:_borderImg];
    
    _lineImg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"scan_line"]];
    _lineImg.frame = CGRectMake(0, 0, scanCode.scan_width, 2);
    [_borderImg addSubview:_lineImg];
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(animation) userInfo:nil repeats:YES];
    
    // 提示
    UILabel *message = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(_borderImg.frame), CGRectGetMaxY(_borderImg.frame), CGRectGetWidth(_borderImg.frame), 20)];
    message.font = [UIFont systemFontOfSize:12.0f];
    message.text = @"将取景器对准扫描的条形码或二维码";
    message.textAlignment = NSTextAlignmentCenter;
    message.textColor = [UIColor whiteColor];
    message.backgroundColor = [UIColor clearColor];
    [maskView addSubview:message];
    
}

#pragma mark -- 动画效果
- (void)animation {
    LLFScanCode *scanCode = [LLFScanCode shareInstance];
    
    if (_upOrdown == NO) {
        _num++;
        _lineImg.frame = CGRectMake(0, 2 * _num, scanCode.scan_width, 2);
        if (2 * _num - 1 == (int)(scanCode.scan_height) || 2 * _num == (int)(scanCode.scan_height)) {
            _upOrdown = YES;
        }
    }
    else {
        _num--;
        _lineImg.frame = CGRectMake(0, 2 * _num, scanCode.scan_width, 2);
        if (_num == 0) {
            _upOrdown = NO;
        }
    }
}

#pragma mark -- AVCaptureMetadataOutputObjectDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if (metadataObjects != nil && metadataObjects.count > 0) {
        
        AVMetadataMachineReadableCodeObject *metadataObj = metadataObjects[0];
        if (_code == nil) {  // 获取第一个值
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
            dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"%@",metadataObj.stringValue);
            });
            if (!self.isNext) {
                return;
            }
            _code = metadataObj.stringValue;
            ++_flag;
        }
        else {
            _flag = 0;
            _code = nil;
        }
    }
}

@end
