//
//  ViewController.m
//  OpenGLRenderer
//
//  Created by apple on 2017/2/9.
//  Copyright © 2017年 xiaokai.zhan. All rights reserved.
//

#import "ViewController.h"
#import "CommonUtil.h"
#import "PngPreviewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}
- (IBAction)display:(id)sender {
    NSLog(@"Display Pic...");
    NSString* pngFilePath = [CommonUtil bundlePath:@"1.png"];
    PngPreviewController *vc = [PngPreviewController viewControllerWithContentPath:pngFilePath contentFrame:self.view.bounds];
    [[self navigationController] pushViewController:vc animated:YES];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
