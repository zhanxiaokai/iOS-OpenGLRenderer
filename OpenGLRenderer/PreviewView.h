//
//  PreviewView.h
//  OpenGLRenderer
//
//  Created by apple on 2017/2/9.
//  Copyright © 2017年 xiaokai.zhan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PreviewView : UIView

- (id) initWithFrame:(CGRect)frame filePath:(NSString*) filePath;

- (void) render;

- (void) destroy;

@end
