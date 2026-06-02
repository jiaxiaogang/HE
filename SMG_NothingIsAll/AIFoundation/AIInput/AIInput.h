//
//  Input.h
//  SMG_NothingIsAll
//
//  Created by 贾  on 2017/4/9.
//  Copyright © 2017年 XiaoGang. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *  MARK:--------------------输入(计算机视觉,听觉,文字,触觉,网络等)--------------------
 *  @过时废弃注释:
 *      1. 注意力对象有可能是一颗树;或者两颗树;或者注意力仅仅是树的大小;
 *      2. 注意力是可持续的;一次注意力,可以提交很多次数据;有时是声音;有时是图像;有时是大脑指定的属性值;
 *
 *  1,收集摄像头图片(图,文字)
 *  2,收集麦克风声音(音)
 *  3,收集用户输入的Text字符串(Text)
 *  4,收集摄像头视频do行为(视频行为)
 */
@interface AIInput : NSObject

+(void) commitText:(NSString*)text;
+(void) commitIMV:(MVType)type from:(CGFloat)from to:(CGFloat)to;
+(void) commitCustom:(CustomInputType)type value:(NSInteger)value;
+(void) commitView:(UIView*)selfView targetView:(UIView*)targetView rect:(CGRect)rect fromObserver:(BOOL)fromObserver;

/**
 *  MARK:--------------------HTTP文本输入--------------------
 *  接受外部系统POST过来的文本，走commitText通路
 */
+ (void)inputTextFromHttpRequest:(NSString *)text;
+ (void)startHttpInputServer:(NSInteger)port;
+ (void)stopHttpInputServer;

/**
 *  拍照（返回200x200的UIImage）
 */
+ (void)capturePhotoWithCompletion:(void(^)(UIImage *image))completion;

/**
 *  启动摄像头会话
 */
+ (void)startCameraSession;

/**
 *  停止摄像头会话
 */
+ (void)stopCameraSession;

@end
