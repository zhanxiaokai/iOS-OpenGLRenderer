//
//  PreviewView.m
//  OpenGLRenderer
//
//  Created by apple on 2017/2/9.
//  Copyright © 2017年 xiaokai.zhan. All rights reserved.
//

#import "PreviewView.h"
#import "RGBAFrameCopier.h"
#import "png_decoder.h"
#import "rgba_frame.h"

@interface PreviewView()
@property (atomic) BOOL readyToRender;
@property (nonatomic, assign) BOOL shouldEnableOpenGL;
@property (nonatomic, strong) NSLock *shouldEnableOpenGLLock;
@end

@implementation PreviewView
{
    dispatch_queue_t                        _contextQueue;
    EAGLContext*                            _context;
    GLuint                                  _displayFramebuffer;
    GLuint                                  _renderbuffer;
    GLint                                   _backingWidth;
    GLint                                   _backingHeight;
    
    BOOL                                    _stopping;
    
    RGBAFrameCopier*                        _frameCopier;
    RGBAFrame*                              _frame;
}

+ (Class) layerClass
{
    return [CAEAGLLayer class];
}

- (id) initWithFrame:(CGRect)frame filePath:(NSString*) filePath;
{
    self = [super initWithFrame:frame];
    if (self) {
        _shouldEnableOpenGLLock = [NSLock new];
        [_shouldEnableOpenGLLock lock];
        _shouldEnableOpenGL = [UIApplication sharedApplication].applicationState == UIApplicationStateActive;
        [_shouldEnableOpenGLLock unlock];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        
        CAEAGLLayer *eaglLayer = (CAEAGLLayer*) self.layer;
        eaglLayer.opaque = YES;
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking,
                                        kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat,
                                        nil];
        _contextQueue = dispatch_queue_create("com.changba.video_player.videoRenderQueue", NULL);
        dispatch_sync(_contextQueue, ^{
            _context = [self buildEAGLContext];
            if (!_context || ![EAGLContext setCurrentContext:_context]) {
                NSLog(@"Setup EAGLContext Failed...");
            }
            if(![self createDisplayFramebuffer]){
                NSLog(@"create Dispaly Framebuffer failed...");
            }
            _frame = [self getRGBAFrame:filePath];
            _frameCopier = [[RGBAFrameCopier alloc] init];
            if (![_frameCopier prepareRender:_frame->width height:_frame->height]) {
                NSLog(@"RGBAFrameCopier prepareRender failed...");
            }
            self.readyToRender = YES;
        });
        
    }
    return self;
}

- (void) render;
{
    if(_stopping){
        return;
    }
    dispatch_async(_contextQueue, ^{
        if(_frame) {
            [self.shouldEnableOpenGLLock lock];
            if (!self.readyToRender || !self.shouldEnableOpenGL) {
                glFinish();
                [self.shouldEnableOpenGLLock unlock];
                return;
            }
            [self.shouldEnableOpenGLLock unlock];
            [EAGLContext setCurrentContext:_context];
            glBindFramebuffer(GL_FRAMEBUFFER, _displayFramebuffer);
            glViewport(0, _backingHeight - _backingWidth - 75, _backingWidth, _backingWidth);
            [_frameCopier renderFrame:_frame->pixels];
            glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
            [_context presentRenderbuffer:GL_RENDERBUFFER];
        }
    });
}

- (RGBAFrame*) getRGBAFrame:(NSString*) pngFilePath;
{
    PngPicDecoder* decoder = new PngPicDecoder();
    char* pngPath = (char*)[pngFilePath cStringUsingEncoding:NSUTF8StringEncoding];
    decoder->openFile(pngPath);
    RawImageData data = decoder->getRawImageData();
    RGBAFrame* frame = new RGBAFrame();
    frame->width = data.width;
    frame->height = data.height;
    int expectLength = data.width * data.height * 4;
    uint8_t * pixels = new uint8_t[expectLength];
    memset(pixels, 0, sizeof(uint8_t) * expectLength);
    int pixelsLength = MIN(expectLength, data.size);
    memcpy(pixels, (byte*) data.data, pixelsLength);
    frame->pixels = pixels;
    decoder->releaseRawImageData(&data);
    decoder->closeFile();
    delete decoder;
    return frame;
}
- (EAGLContext*) buildEAGLContext
{
    return [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
}

- (BOOL) createDisplayFramebuffer;
{
    BOOL ret = TRUE;
    glGenFramebuffers(1, &_displayFramebuffer);
    glGenRenderbuffers(1, &_renderbuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _displayFramebuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderbuffer);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"failed to make complete framebuffer object %x", status);
        return FALSE;
    }
    
    GLenum glError = glGetError();
    if (GL_NO_ERROR != glError) {
        NSLog(@"failed to setup GL %x", glError);
        return FALSE;
    }
    return ret;
}

- (void) destroy;
{
    _stopping = true;
    dispatch_sync(_contextQueue, ^{
        if(_frameCopier) {
            [_frameCopier releaseRender];
        }
        if (_displayFramebuffer) {
            glDeleteFramebuffers(1, &_displayFramebuffer);
            _displayFramebuffer = 0;
        }
        if (_renderbuffer) {
            glDeleteRenderbuffers(1, &_renderbuffer);
            _renderbuffer = 0;
        }
        if ([EAGLContext currentContext] == _context) {
            [EAGLContext setCurrentContext:nil];
        }
    });
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (_contextQueue) {
        _contextQueue = nil;
    }
    _frameCopier = nil;
    _context = nil;
}

- (void)applicationWillResignActive:(NSNotification *)notification {
    [self.shouldEnableOpenGLLock lock];
    self.shouldEnableOpenGL = NO;
    [self.shouldEnableOpenGLLock unlock];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    [self.shouldEnableOpenGLLock lock];
    self.shouldEnableOpenGL = YES;
    [self.shouldEnableOpenGLLock unlock];
}

@end
