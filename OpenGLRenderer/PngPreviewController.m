//
//  PngPreviewController.m
//  OpenGLRenderer
//
//  Created by apple on 2017/2/9.
//  Copyright © 2017年 xiaokai.zhan. All rights reserved.
//

#import "PngPreviewController.h"
#import "PreviewView.h"
@interface PngPreviewController ()

@end

@implementation PngPreviewController
{
    PreviewView*            _previewView;
}
+ (id) viewControllerWithContentPath:(NSString*) pngFilePath contentFrame:(CGRect) frame;
{
    return [[PngPreviewController alloc] initWithContentPath:pngFilePath
                                                     contentFrame:frame];
}

- (id) initWithContentPath:(NSString *)path
              contentFrame:(CGRect)frame
{
    NSAssert(path.length > 0, @"empty path");
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _previewView = [[PreviewView alloc] initWithFrame:frame filePath:path];
        _previewView.contentMode = UIViewContentModeScaleAspectFill;
//        _previewView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
        self.view.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
        [self.view insertSubview:_previewView atIndex:0];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [_previewView render];
}
- (void) dealloc {
    if(_previewView){
        [_previewView destroy];
        _previewView = nil;
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
