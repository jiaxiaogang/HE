//
//  ZiJvUtil.m
//  SMG_NothingIsAll
//
//  Created by jia on 2026/4/10.
//  Copyright © 2026 XiaoGang. All rights reserved.
//

#import "ZiJvUtil.h"
#import "AIFeatureNode.h"
#import "AIFeatureJvBuItem.h"

@implementation ZiJvUtil

+ (CGFloat) adsorbWithBaseValue_Single:(CGFloat)baseValue envValue:(CGFloat)envValue envWeight:(CGFloat)envWeight {
    // value和weight范围都是0~1
    return baseValue * (1.0f - envWeight) + envValue * envWeight;
}

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

+ (CGFloat) calcAdsorbEdgeWithBaseT:(AIFeatureNode*)baseT curIndex:(NSInteger)curIndex bestGVs:(NSDictionary*)bestGVs edgeBlock:(CGFloat(^)(CGRect))edgeBlock max:(CGFloat)max {
    CGFloat curValue = edgeBlock([baseT rectByIndex:curIndex]) / max;
    return [self adsorbWithBaseValue_Multi:curValue envs:bestGVs.allKeys envBlock:^NSDictionary *(NSNumber *key) {
        CGFloat envValue = edgeBlock([baseT rectByIndex:key.integerValue]) / max;
        AIFeatureJvBuItem *value = [bestGVs objectForKey:key];
        CGFloat distanceWeight = 1.0 - fabs(envValue - curValue);
        CGFloat weight = distanceWeight * value.matchValue;
        return @{@"value": @(envValue), @"weight": @(weight)};
    }];
}

+ (CGRect) calcAdsorbProtoRect:(NSDictionary*)bestGVs baseT:(AIFeatureNode*)baseT curIndex:(NSInteger)curIndex {
    // 取整体宽高。
    CGRect baseTRect = baseT.rect;
    CGFloat width = baseTRect.size.width;
    CGFloat height = baseTRect.size.height;

    CGFloat adsorCurMinX = [self calcAdsorbEdgeWithBaseT:baseT curIndex:curIndex bestGVs:bestGVs edgeBlock:^CGFloat(CGRect rect) { return CGRectGetMinX(rect); } max:width];
    CGFloat adsorCurMaxX = [self calcAdsorbEdgeWithBaseT:baseT curIndex:curIndex bestGVs:bestGVs edgeBlock:^CGFloat(CGRect rect) { return CGRectGetMaxX(rect); } max:width];
    CGFloat adsorCurMinY = [self calcAdsorbEdgeWithBaseT:baseT curIndex:curIndex bestGVs:bestGVs edgeBlock:^CGFloat(CGRect rect) { return CGRectGetMinY(rect); } max:height];
    CGFloat adsorCurMaxY = [self calcAdsorbEdgeWithBaseT:baseT curIndex:curIndex bestGVs:bestGVs edgeBlock:^CGFloat(CGRect rect) { return CGRectGetMaxY(rect); } max:height];
    
    // 计算到吸附值后，根据四条边，再拼回rect返回。
    
    // TODO: 实现吸附后的protoRect计算
    return CGRectZero;
}

@end
