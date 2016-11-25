//
//  ViewController.m
//  LLFScanCodeDemo
//
//  Created by gary.liu on 16/11/24.
//  Copyright © 2016年 gary.liu. All rights reserved.
//

#import "ViewController.h"
#import "LLFScanCode.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [LLFScanCode startScanWithView:self];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [LLFScanCode stop];
}

@end
