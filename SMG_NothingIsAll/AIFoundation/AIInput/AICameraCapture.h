//
//  AICameraCapture.h
//  SMG_NothingIsAll
//
//  Created by Claude on 2026/4/24.
//

#import <Foundation/Foundation.h>

@class UIImage;


/**
 *  MARK:--------------------摄像头视觉，用法--------------------
 *  @用法
 *    [AIInput startCameraSession]; // 启动摄像头会话（常驻后台时调用一次）
 *    [AIInput capturePhotoWithCompletion:^(UIImage *image) { // 拍照，返回UIImage，在这里处理图片 }];
 *    [AIInput stopCameraSession]; // 停止会话（需要时）
 */
@interface AICameraCapture : NSObject

/**
 *  拍照并返回200x200的UIImage
 *  @param completion 拍照完成的回调（主线程）
 */
+ (void)capturePhotoWithCompletion:(void(^)(UIImage *image))completion;

/**
 *  启动摄像头会话（在后台运行时调用）
 */
+ (void)startSession;

/**
 *  停止摄像头会话
 */
+ (void)stopSession;

@end
