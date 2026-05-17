//
//  AIVisionAlgsV2.h
//  SMG_NothingIsAll
//
//  Created by jia on 2025/3/15.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface AIVisionAlgsV2 : NSObject

/**
 *  MARK:--------------------commitInput--------------------
 */
+ (void) commitInputV2:(UIImage*)image logDesc:(NSString*)logDesc;

/**
 *  MARK:--------------------获取图片指定区域的RGB值--------------------
 *  @cropRect 注意力范围（为归一化坐标 0-1）
 */
+ (NSDictionary*) getRGBValuesFromImage:(UIImage *)image cropRect:(CGRect)cropRect;

#pragma mark - Test Methods

+ (UIImage *) createTest4ColorImage;
+ (UIImage *) createImageFromMnistImageWithName:(NSString*)imgName forTest:(BOOL)forTest;
+ (UIImage *) createImageFromCustomImageWithName:(NSString*)imgName;

@end
