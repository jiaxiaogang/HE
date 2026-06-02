//
//  Input.m
//  SMG_NothingIsAll
//
//  Created by 贾  on 2017/4/9.
//  Copyright © 2017年 XiaoGang. All rights reserved.
//

#import "AIInput.h"
#import "AIReactorControl.h"
#import "AICameraCapture.h"
#import "AIHttpInput.h"

@implementation AIInput

+(void) commitText:(NSString*)text{
    //2017.04
    //[theThink commitUnderstandByShallowFromInput:text];//从input常规输入的浅度理解即可;(简单且错误,参考N4P2)
    
    //2017.10.13修正,input->aiNet->funcModel->aiNet->awareness作预测对比(参考n7p6)
    //[theNet commitString:text];
    
    //2017.11.13修正,input->AIAwareness->AIThinkingControl->aiNet->...
    //[theAIAwarenessControl commitInput:text];
    
    //2017.12.15修正,参考Note9SMG软件架构3
    [AIReactorControl commitInput:text];
}

/**
 *  MARK:--------------------提交mvType--------------------
 *  @params from : 0-10 (0为最饥,1为最饱)
 *  @params to : 0-10
 */
+(void) commitIMV:(MVType)type from:(CGFloat)from to:(CGFloat)to{
    //1. 将imv信号转成imvModel并提交给TC;
    ImvAlgsModelBase *imvModel = [AIImvAlgs commitIMV:type from:from to:to];
    [theTC commitInputAsync:imvModel];
}

+(void) commitCustom:(CustomInputType)type value:(NSInteger)value{
    [AIReactorControl commitCustom:type value:value];
}

+(void) commitView:(UIView*)selfView targetView:(UIView*)targetView rect:(CGRect)rect fromObserver:(BOOL)fromObserver {
    //2024.07.23: 先打开被动触发的视觉 (参考32111-方案2);
    //if (!fromObserver) return;//把非广播触发的视觉关掉;
    [AIReactorControl commitView:selfView targetView:targetView rect:rect];
}

+ (void)capturePhotoWithCompletion:(void(^)(UIImage *))completion {
    [AICameraCapture capturePhotoWithCompletion:completion];
}

+ (void)startCameraSession {
    [AICameraCapture startSession];
}

+ (void)stopCameraSession {
    [AICameraCapture stopSession];
}

#pragma mark - HTTP文本输入

+ (void)inputTextFromHttpRequest:(NSString *)text {
    [self commitText:text];
}

+ (void)startHttpInputServer:(NSInteger)port {
    [AIHttpInput startServer:port];
}

+ (void)stopHttpInputServer {
    [AIHttpInput stopServer];
}

@end
