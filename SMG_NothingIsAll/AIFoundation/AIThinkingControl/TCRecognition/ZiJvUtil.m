//
//  ZiJvUtil.m
//  SMG_NothingIsAll
//
//  Created by jia on 2026/4/10.
//  Copyright © 2026 XiaoGang. All rights reserved.
//

#import "ZiJvUtil.h"

@implementation ZiJvUtil

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
+ (CGFloat) adsorbWithBaseValue_Single:(CGFloat)baseValue envValue:(CGFloat)envValue envWeight:(CGFloat)envWeight {
    // value和weight范围都是0~1
    return baseValue * (1.0f - envWeight) + envValue * envWeight;
}

/**
 *  MARK:--------------------多环境吸附--------------------
 *  @param baseValue         本体值 (0~1)
 *  @param envs              环境数组 (NSArray<id>)
 *  @param envBlock          返回环境值和权重的block @{@"value": @(值), @"weight": @(权重)}
 *  @return                  各环境吸附结果的平均值
 */
+ (CGFloat) adsorbWithBaseValue_Multi:(CGFloat)baseValue envs:(NSArray<id>*)envs envBlock:(NSDictionary *(^)(id))envBlock {
    if (envs.count == 0) return baseValue;

    CGFloat sum = 0;
    for (id env in envs) {
        NSDictionary *envInfo = envBlock(env);
        CGFloat envValue = [envInfo[@"value"] floatValue];
        CGFloat envWeight = [envInfo[@"weight"] floatValue];
        sum += [self adsorbWithBaseValue_Single:baseValue envValue:envValue envWeight:envWeight];
    }
    return sum / envs.count;
}

/**
 *  MARK:--------------------计算单条边的吸附值--------------------
 *  @param baseT             本体AIFeatureNode
 *  @param curIndex          本体下标
 *  @param bestGVs           环境字典
 *  @param edgeBlock         边提取函数
 *  @param max               分母（宽或高）
 *  @param force             吸附强度调整参数 (0~1)，越大吸附越强烈（为1时最近的100%匹配则完全吸附，为0.5时最近的100%匹配也只吸一半）
 *  @return                  吸附后的边值
 */
+ (CGFloat) calcAdsorbEdgeWithBaseT:(AIFeatureNode*)baseT curIndex:(NSInteger)curIndex bestGVs:(NSDictionary*)bestGVs edgeBlock:(CGFloat(^)(CGRect))edgeBlock max:(CGFloat)max force:(CGFloat)force {
    CGFloat curValue = edgeBlock([baseT rectByIndex:curIndex]) / max;
    return [self adsorbWithBaseValue_Multi:curValue envs:bestGVs.allKeys envBlock:^NSDictionary *(NSNumber *key) {
        CGFloat envValue = edgeBlock([baseT rectByIndex:key.integerValue]) / max;
        AIFeatureJvBuItem *value = [bestGVs objectForKey:key];
        CGFloat distanceWeight = 1.0 - fabs(envValue - curValue);
        
        // 综合考虑距离和匹配度：权重为距离乘匹配度（参考37024-TODO7）。
        CGFloat weight = distanceWeight * value.matchValue;
        
        // 乘以一个force参数来调整吸附强度（参考37023-锚点抖动范围）。
        weight *= force;
        return @{@"value": @(envValue), @"weight": @(weight)};
    }];
}

/**
 *  MARK:--------------------计算吸附后的assRect--------------------
 *  @param bestGVs           本体bestGVs字典
 *  @param baseT             本体AIFeatureNode
 *  @param curIndex          本体下标
 *  @param force             吸附强度调整参数 (0~1)，越大吸附越强烈（为1时最近的100%匹配则完全吸附，为0.5时最近的100%匹配也只吸一半）
 *  @return                  吸附后的protoRect
 */
+ (CGRect) calcAdsorbAssRect:(NSDictionary*)bestGVs baseT:(AIFeatureNode*)baseT curIndex:(NSInteger)curIndex force:(CGFloat)force {
    // 取整体宽高。
    CGRect baseTRect = baseT.rect;
    CGFloat width = baseTRect.size.width;
    CGFloat height = baseTRect.size.height;
    
    // 四条边分别计算吸附值，范围都是0~1。
    CGFloat adsorCurMinX = [self calcAdsorbEdgeWithBaseT:baseT curIndex:curIndex bestGVs:bestGVs edgeBlock:^CGFloat(CGRect rect) { return CGRectGetMinX(rect); } max:width force:force];
    CGFloat adsorCurMaxX = [self calcAdsorbEdgeWithBaseT:baseT curIndex:curIndex bestGVs:bestGVs edgeBlock:^CGFloat(CGRect rect) { return CGRectGetMaxX(rect); } max:width force:force];
    CGFloat adsorCurMinY = [self calcAdsorbEdgeWithBaseT:baseT curIndex:curIndex bestGVs:bestGVs edgeBlock:^CGFloat(CGRect rect) { return CGRectGetMinY(rect); } max:height force:force];
    CGFloat adsorCurMaxY = [self calcAdsorbEdgeWithBaseT:baseT curIndex:curIndex bestGVs:bestGVs edgeBlock:^CGFloat(CGRect rect) { return CGRectGetMaxY(rect); } max:height force:force];
    
    // 计算到吸附值后，根据四条边，再拼回rect返回。
    CGFloat adsorX = adsorCurMinX * width;
    CGFloat adsorY = adsorCurMinY * height;
    CGFloat adsorW = (adsorCurMaxX - adsorCurMinX) * width;
    CGFloat adsorH = (adsorCurMaxY - adsorCurMinY) * height;
    return CGRectMake(adsorX, adsorY, adsorW, adsorH);
}

@end
