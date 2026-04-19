//
//  WeightedSumCutUtil.m
//  SMG_NothingIsAll
//
//  Created by jia on 2026/4/10.
//  Copyright © 2026 XiaoGang. All rights reserved.
//

#import "WeightedSumCutUtil.h"

/**
 *  MARK:--------------------加权求和切图法（又称：吸附切图算法）--------------------
 */
@implementation WeightedSumCutUtil

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
 *  @param bestDic           环境字典
 *  @param curEdgeBlock      个体边提取函数
 *  @param envEdgeBlock      环境边提取函数
 *  @param max               分母（宽或高）
 *  @param force             吸附强度调整参数 (0~1)，越大吸附越强烈（为1时最近的100%匹配则完全吸附，为0.5时最近的100%匹配也只吸一半）
 *  @return                  吸附后的边值
 */
+ (CGFloat) calcAdsorbEdgeWithBaseT:(AIFeatureNode*)baseT curIndex:(NSInteger)curIndex bestDic:(NSDictionary*)bestDic max:(CGFloat)max force:(CGFloat)force
                       curEdgeBlock:(CGFloat(^)(CGRect))curEdgeBlock envEdgeBlock:(CGFloat(^)(CGRect))envEdgeBlock {
    CGFloat curValue = curEdgeBlock([baseT rectByIndex:curIndex]) / max;
    return [self adsorbWithBaseValue_Multi:curValue envs:bestDic.allKeys envBlock:^NSDictionary *(NSNumber *key) {
        // cur和other之间对齐：先取出envValue值（参考37024-TODO6）。
        CGFloat envValue = envEdgeBlock([baseT rectByIndex:key.integerValue]) / max;
        id obj = [bestDic objectForKey:key];
        
        // cur和other之间对齐：计算curValue与envValue对齐值（越近越对齐，越远越对不齐）（参考37024-TODO6）。
        CGFloat distanceWeight = 1.0 - fabs(envValue - curValue);
        
        // 综合考虑距离和匹配度：权重为距离乘匹配度（参考37024-TODO7）。
        CGFloat matchValue = 0;
        if (ISOK(obj, AIFeatureJvBuItem.class)) {
            matchValue = ((AIFeatureJvBuItem*)obj).outerShapeMatchValue;
        } else if (ISOK(obj, STZiJvModelV2.class)) {
            matchValue = ((STZiJvModelV2*)obj).stOuterShapeMatchValue;
        }
        
        // 距离和匹配度，都按冷却曲线，避免远处的影响太大（参考37033B-2疑点）。
        CGFloat cooledDistanceValue = [MathUtils getCooledValue:1 - distanceWeight finishValue:0.02f];
        CGFloat cooledMatchValue = [MathUtils getCooledValue:1 - matchValue finishValue:0.02f];
        
        // 乘以一个force参数来调整吸附强度（参考37023-锚点抖动范围）。
        CGFloat weight = cooledDistanceValue * cooledMatchValue * force;
        return @{@"value": @(envValue), @"weight": @(weight)};
    }];
}

/**
 *  MARK:--------------------计算吸附后的curGV_BaseT--------------------
 *  @param bestDic           本体bestDic字典
 *  @param baseT             本体AIFeatureNode
 *  @param curIndex          本体下标
 *  @param force             吸附强度调整参数 (0~1)，越大吸附越强烈（为1时最近的100%匹配则完全吸附，为0.5时最近的100%匹配也只吸一半）
 *  @return                  吸附后的protoRect
 */
+ (CGRect) calcAdsorbAssRect:(NSDictionary*)bestDic baseT:(AIFeatureNode*)baseT curIndex:(NSInteger)curIndex force:(CGFloat)force {
    // 取整体宽高。
    CGRect baseTRect = baseT.rect;
    CGFloat width = baseTRect.size.width;
    CGFloat height = baseTRect.size.height;
    
    // 四条边分别计算吸附值，范围都是0~1（上对下、下对上、左对右、右对左，参考37036）。
    CGFloat adsorCurMinX = [self calcAdsorbEdgeWithBaseT:baseT curIndex:curIndex bestDic:bestDic max:width force:force
                                            curEdgeBlock:^CGFloat(CGRect r) { return CGRectGetMinX(r); }
                                            envEdgeBlock:^CGFloat(CGRect r) { return CGRectGetMaxX(r); }];
    CGFloat adsorCurMaxX = [self calcAdsorbEdgeWithBaseT:baseT curIndex:curIndex bestDic:bestDic max:width force:force
                                            curEdgeBlock:^CGFloat(CGRect r) { return CGRectGetMaxX(r); }
                                            envEdgeBlock:^CGFloat(CGRect r) { return CGRectGetMinX(r); }];
    CGFloat adsorCurMinY = [self calcAdsorbEdgeWithBaseT:baseT curIndex:curIndex bestDic:bestDic max:height force:force
                                            curEdgeBlock:^CGFloat(CGRect r) { return CGRectGetMinY(r); }
                                            envEdgeBlock:^CGFloat(CGRect r) { return CGRectGetMaxY(r); }];
    CGFloat adsorCurMaxY = [self calcAdsorbEdgeWithBaseT:baseT curIndex:curIndex bestDic:bestDic max:height force:force
                                            curEdgeBlock:^CGFloat(CGRect r) { return CGRectGetMaxY(r); }
                                            envEdgeBlock:^CGFloat(CGRect r) { return CGRectGetMinY(r); }];
    
    // 计算到吸附值后，根据四条边，再拼回rect返回。
    CGFloat adsorX = adsorCurMinX * width;
    CGFloat adsorY = adsorCurMinY * height;
    CGFloat adsorW = (adsorCurMaxX - adsorCurMinX) * width;
    CGFloat adsorH = (adsorCurMaxY - adsorCurMinY) * height;
    return CGRectMake(adsorX, adsorY, adsorW, adsorH);
}

/**
 *  MARK:--------------------获取切图候选范围（返回十条）--------------------
 *  @desc 锚点交由权重求和来计算：根据锚点，求出十种newST_Proto。
 *  @param baseT_Proto : baseT给的总空间非常重要，对每个bestGV最终能切到多少有决定性作用（并且baseST也往往是吸附锚点算出来的，所以必须得传过来）。
 */
+ (NSArray*) calcAdsorbProtoRects:(NSDictionary*)bestDic baseT:(AIFeatureNode*)baseT curIndex:(NSInteger)curIndex baseT_Proto:(CGRect)baseT_Proto {
    // 求出baseT的总rect。
    CGRect baseTRect = baseT.rect;
    
    // 根据吸附强度分别：计算在Ass的始终切图范围（参考37024-TODO8&9）。
    CGRect new_BaseTFrom = [self calcAdsorbAssRect:bestDic baseT:baseT curIndex:curIndex force:0.5f];
    CGRect new_BaseTTo = [self calcAdsorbAssRect:bestDic baseT:baseT curIndex:curIndex force:1.0f];
    
    // 转换为在Proto的始终切图范围（参考37024-TODO4）。
    CGRect new_ProtoFrom = [SMGUtils convertAAtCWithAAtB:new_BaseTFrom bAtC:baseT_Proto protoBSize:baseTRect.size];
    CGRect new_ProtoTo = [SMGUtils convertAAtCWithAAtB:new_BaseTTo bAtC:baseT_Proto protoBSize:baseTRect.size];
    
    // bestDic为空时，from和to都是切入GV自身，不必返回10条，只返回自己一条就行。
    if (CGRectEqualToRect(new_ProtoFrom, new_ProtoTo)) return @[@(new_ProtoFrom)];

    // 从from到to，平均取十帧rect，转成数组返回（参考37024-TODO10）。
    NSMutableArray *result = [NSMutableArray array];
    CGFloat fromX = CGRectGetMinX(new_ProtoFrom), fromY = CGRectGetMinY(new_ProtoFrom), fromW = new_ProtoFrom.size.width, fromH = new_ProtoFrom.size.height;
    CGFloat toX = CGRectGetMinX(new_ProtoTo), toY = CGRectGetMinY(new_ProtoTo), toW = new_ProtoTo.size.width, toH = new_ProtoTo.size.height;
    for (NSInteger i = 0; i < 5; i++) {
        CGFloat t = i / 4.0f; // 0~1（10条分成9份，是为了包含首尾）。
        CGFloat x = fromX + (toX - fromX) * t;
        CGFloat y = fromY + (toY - fromY) * t;
        CGFloat w = fromW + (toW - fromW) * t;
        CGFloat h = fromH + (toH - fromH) * t;
        [result addObject:[NSValue valueWithCGRect:CGRectMake(x, y, w, h)]];
    }
    return result;
}

@end
