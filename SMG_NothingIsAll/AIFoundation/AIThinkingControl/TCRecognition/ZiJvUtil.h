//
//  ZiJvUtil.h
//  SMG_NothingIsAll
//
//  Created by jia on 2026/4/10.
//  Copyright © 2026 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@class AIFeatureNode, AIFeatureJvBuItem;

NS_ASSUME_NONNULL_BEGIN

@interface ZiJvUtil : NSObject

/**
 *  MARK:--------------------吸附公式--------------------
 *  @param baseValue         本体值 (0~1)
 *  @param envValue          环境值 (0~1)
 *  @param envWeight         环境权重 (0~1)，权重越大，本体越趋向于环境值
 *  @return                  吸附后的值 (0~1)
 *  @note
 *      公式: result = baseValue * (1 - envWeight) + envValue * envWeight
 *      envWeight = 0: 本体值不变
 *      envWeight = 1: 本体值完全变成环境值
 */
+ (CGFloat) adsorbWithBaseValue_Single:(CGFloat)baseValue envValue:(CGFloat)envValue envWeight:(CGFloat)envWeight;

/**
 *  MARK:--------------------多环境吸附--------------------
 *  @param baseValue         本体值 (0~1)
 *  @param envs              环境数组 (NSArray<id>)
 *  @param envBlock          返回环境值和权重的block @{@"value": @(值), @"weight": @(权重)}
 *  @return                  各环境吸附结果的平均值
 */
+ (CGFloat) adsorbWithBaseValue_Multi:(CGFloat)baseValue envs:(NSArray<id>*)envs envBlock:(NSDictionary*(^)(id env))envBlock;

/**
 *  MARK:--------------------计算单条边的吸附值--------------------
 *  @param baseT             本体AIFeatureNode
 *  @param curIndex          本体下标
 *  @param bestGVs           环境字典
 *  @param edgeFunc          边提取函数
 *  @param denominator       分母（宽或高）
 *  @return                  吸附后的边值
 */
+ (CGFloat) calcAdsorbEdgeWithBaseT:(AIFeatureNode*)baseT curIndex:(NSInteger)curIndex bestGVs:(NSDictionary*)bestGVs edgeFunc:(CGFloat(^)(CGRect))edgeFunc denominator:(CGFloat)denominator;

/**
 *  MARK:--------------------计算吸附后的protoRect--------------------
 *  @param bestGVs           本体bestGVs字典
 *  @param baseT             本体AIFeatureNode
 *  @param curIndex          本体下标
 *  @return                  吸附后的protoRect
 */
+ (CGRect) calcAdsorbProtoRect:(NSDictionary*)bestGVs baseT:(AIFeatureNode*)baseT curIndex:(NSInteger)curIndex;

@end

NS_ASSUME_NONNULL_END
