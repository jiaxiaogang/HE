//
//  MathUtils.m
//  SMG_NothingIsAll
//
//  Created by jia on 2023/5/21.
//  Copyright © 2023年 XiaoGang. All rights reserved.
//

#import "MathUtils.h"

@implementation MathUtils

+(CGFloat) getNegativeTen2TenWithOriRange:(UIFloatRange)oriRange oriValue:(CGFloat)oriValue{
    return [self getValueWithOriRange:oriRange targetRange:UIFloatRangeMake(-10, 10) oriValue:oriValue];
}
+(CGFloat) getZero2TenWithOriRange:(UIFloatRange)oriRange oriValue:(CGFloat)oriValue{
    return [self getValueWithOriRange:oriRange targetRange:UIFloatRangeMake(0, 10) oriValue:oriValue];
}
+(CGFloat) getValueWithOriRange:(UIFloatRange)oriRange targetRange:(UIFloatRange)targetRange oriValue:(CGFloat)oriValue{
    //1,数据范围检查;
    oriValue = MAX(oriValue, MIN(oriValue, oriRange.maximum));
    //2,checkValue所在的值
    CGFloat percent = 0;
    if (oriRange.minimum != oriValue) {
        percent = (oriValue - oriRange.minimum) / (oriRange.maximum - oriRange.minimum);
    }
    //3,返回变换值
    return (targetRange.maximum - targetRange.minimum) * percent + targetRange.minimum;
}

//MARK:===============================================================
//MARK:                     < rect >
//MARK:===============================================================

/**
 *  MARK:--------------------取rect并集--------------------
 */
+(CGRect) collectRectA:(CGRect)rectA rectB:(CGRect)rectB {
    return CGRectUnion(rectA, rectB);
}

/**
 *  MARK:--------------------取rect交集--------------------
 */
+(CGRect) filterRectA:(CGRect)rectA rectB:(CGRect)rectB {
    //注意: 有时候CGRectIntersects()返回的是一个+-inf的xy
    return CGRectIntersection(rectA, rectB);
}

/**
 *  MARK:--------------------取start到end之间百分比处的值--------------------
 */
+(CGRect) radioRect:(CGRect)startRect endRect:(CGRect)endRect radio:(CGFloat)radio{
    CGFloat x = [self radioFloat:CGRectGetMinX(startRect) endFloat:CGRectGetMinX(endRect) radio:radio];
    CGFloat y = [self radioFloat:CGRectGetMinY(startRect) endFloat:CGRectGetMinY(endRect) radio:radio];
    CGFloat w = [self radioFloat:CGRectGetWidth(startRect) endFloat:CGRectGetWidth(endRect) radio:radio];
    CGFloat h = [self radioFloat:CGRectGetHeight(startRect) endFloat:CGRectGetHeight(endRect) radio:radio];
    return CGRectMake(x, y, w, h);
}

//用radio取float从start到end之间的值;
+(CGFloat) radioFloat:(CGFloat)startFloat endFloat:(CGFloat)endFloat radio:(CGFloat)radio{
    return startFloat + (endFloat - startFloat) * radio;
}

/**
 *  MARK:--------------------牛顿冷却--------------------
 *  @param totalCoolTime 总冷却时间 (需>0)
 *  @param pastTime 已冷却时间
 *  _param pastRate : 已冷却百分比时间;
 *  @param finishValue 环境温度 (输出百分比即可: 0%时冷却到0,100%时不冷却) (当28原则时,为0.000322f)
 *  @result 返回剩下温度百分比 (此值 <= 1 && > finishValue);
 */
+(CGFloat) getCooledValue:(CGFloat)totalCoolTime pastTime:(CGFloat)pastTime finishValue:(CGFloat)finishValue {
    return [self getCooledValue:pastTime / totalCoolTime finishValue:finishValue];
}

+(CGFloat) getCooledValue_28:(CGFloat)pastRate {
    return [self getCooledValue:pastRate finishValue:0.000322f];
}

+(CGFloat) getCooledValue:(CGFloat)pastRate finishValue:(CGFloat)finishValue {
    //2. 冷却系数
    CGFloat coefficient = -logf(finishValue);
    
    //3. 计算出冷却后的值;
    CGFloat cooledValue = expf(-coefficient * pastRate);
    return cooledValue;
}

//取rect的中心点
+(CGPoint) getRectCenterPoint:(CGRect)rect {
    return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
    //return CGPointMake(rect.origin.x + rect.size.width / 2.0f, rect.origin.y + rect.size.height / 2.0f);
}

@end
