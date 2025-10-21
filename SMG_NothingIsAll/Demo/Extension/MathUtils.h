//
//  MathUtils.h
//  SMG_NothingIsAll
//
//  Created by jia on 2023/5/21.
//  Copyright © 2023年 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MathUtils : NSObject

//数据范围变换
+(CGFloat) getNegativeTen2TenWithOriRange:(UIFloatRange)oriRange oriValue:(CGFloat)oriValue;
+(CGFloat) getZero2TenWithOriRange:(UIFloatRange)oriRange oriValue:(CGFloat)oriValue;
+(CGFloat) getValueWithOriRange:(UIFloatRange)oriRange targetRange:(UIFloatRange)targetRange oriValue:(CGFloat)oriValue;

//MARK:===============================================================
//MARK:                     < rect >
//MARK:===============================================================

/**
 *  MARK:--------------------取rect并集--------------------
 */
+(CGRect) collectRectA:(CGRect)rectA rectB:(CGRect)rectB;

/**
 *  MARK:--------------------取rect交集--------------------
 */
+(CGRect) filterRectA:(CGRect)rectA rectB:(CGRect)rectB;

/**
 *  MARK:--------------------取start到end之间百分比处的值--------------------
 */
+(CGRect) radioRect:(CGRect)startRect endRect:(CGRect)endRect radio:(CGFloat)radio;

/**
 *  MARK:--------------------牛顿冷却--------------------
 *  @param totalCoolTime 总冷却时间
 *  @param pastTime 已冷却时间
 *  @param finishValue 最终冷却温度 (当28原则时,为0.000322f)
 */
+(CGFloat) getCooledValue:(CGFloat)totalCoolTime pastTime:(CGFloat)pastTime finishValue:(CGFloat)finishValue;
+(CGFloat) getCooledValue_28:(CGFloat)pastRate;
+(CGFloat) getCooledValue:(CGFloat)pastRate finishValue:(CGFloat)finishValue;

//取rect的中心点
+(CGPoint) getRectCenterPoint:(CGRect)rect;

@end
