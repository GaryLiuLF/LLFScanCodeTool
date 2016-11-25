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

// 单例
+ (instancetype)shareInstance;
// 开始扫描
+ (void)start;
// 结束扫描
+ (void)stop;

+ (void)scanWithView:(UIViewController *)vc

@end
