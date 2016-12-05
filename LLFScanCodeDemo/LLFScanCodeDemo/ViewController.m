//
//  ViewController.m
//  LLFScanCodeDemo
//
//  Created by gary.liu on 16/11/24.
//  Copyright © 2016年 gary.liu. All rights reserved.
//

#import "ViewController.h"
#import "LLFScanCode.h"
#import "NextViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"扫描";
    self.view.backgroundColor = [UIColor blackColor];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [LLFScanCode startScanWithView:self];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    LLFScanCode *scanCode = [LLFScanCode shareInstance];
    scanCode.isNext = NO;
    scanCode.scanCode = ^(NSString *code) {
        NSLog(@"%@",code);
        NextViewController *nextvc = [NextViewController new];
        [self.navigationController pushViewController:nextvc animated:YES];
    };
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [LLFScanCode stop];
}

//- (void)viewDidDisappear:(BOOL)animated
//{
//    [super viewDidDisappear:animated];
//    [LLFScanCode stop];
//}

@end
