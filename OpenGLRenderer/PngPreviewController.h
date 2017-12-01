//
//  PngPreviewController.h
//  OpenGLRenderer
//
//  Created by apple on 2017/2/9.
//  Copyright © 2017年 xiaokai.zhan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PngPreviewController : UIViewController

+ (id) viewControllerWithContentPath:(NSString*) pngFilePath contentFrame:(CGRect) frame;

@end
