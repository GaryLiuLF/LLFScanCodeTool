//
//  LLFScanCode.h
//  LLFScanCodeDemo
//
//  Created by gary.liu on 16/11/24.
//  Copyright © 2016年 gary.liu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@interface LLFScanCode : NSObject

@property (nonatomic, assign) float scan_minX;      // 扫描框的坐标
@property (nonatomic, assign) float scan_minY;      // 默认（50，50）
@property (nonatomic, assign) float scan_width;     // 扫描框的宽度
@property (nonatomic, assign) float scan_height;    // 扫描框的高度 默认宽度与高度一样


// 单例
+ (instancetype)shareInstance;
// 开始扫描
+ (void)startScanWithView:(UIViewController *)vc;
// 结束扫描
+ (void)stop;

@end
