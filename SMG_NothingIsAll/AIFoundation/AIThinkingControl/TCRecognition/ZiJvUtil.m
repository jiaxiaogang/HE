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

+ (CGFloat) adsorbWithBaseValue_Multi:(CGFloat)baseValue envs:(NSArray<id>*)envs valueBlock:(CGFloat(^)(id env))valueBlock weightBlock:(CGFloat(^)(id env))weightBlock {
    if (envs.count == 0) return baseValue;

    CGFloat sum = 0;
    for (id env in envs) {
        CGFloat envValue = valueBlock(env);
        CGFloat envWeight = weightBlock(env);
        sum += [self adsorbWithBaseValue_Single:baseValue envValue:envValue envWeight:envWeight];
    }
    return sum / envs.count;
}

+ (CGRect) calcAdsorbProtoRect:(NSDictionary*)bestGVs baseT:(AIFeatureNode*)baseT curIndex:(NSInteger)curIndex {
    // 取整体宽高。
    CGRect baseTRect = baseT.rect;
    CGFloat width = baseTRect.size.width;
    CGFloat height = baseTRect.size.height;
    
    // 取本体的四条边的归一化值。
    CGRect curRect = [baseT rectByIndex:curIndex];
    CGFloat curMinX = CGRectGetMinX(curRect) / width;
    CGFloat curMaxX = CGRectGetMaxX(curRect) / width;
    CGFloat curMinY = CGRectGetMinX(curRect) / height;
    CGFloat curMaxY = CGRectGetMaxY(curRect) / height;
    
    // 取环境的四条边的归一化值，并计算吸附后的值。
    CGFloat adsorCurMinX = [self adsorbWithBaseValue_Multi:curMinX envs:bestGVs.allKeys valueBlock:^CGFloat(NSNumber *key) {
        CGRect bestRect = [baseT rectByIndex:key.integerValue];
        return CGRectGetMinX(bestRect) / width;
    } weightBlock:^CGFloat(NSNumber *key) {
        CGRect bestRect = [baseT rectByIndex:key.integerValue];
        CGFloat envValue = CGRectGetMinX(bestRect) / width;
        AIFeatureJvBuItem *value = [bestGVs objectForKey:key];
        CGFloat distanceWeight = 1.0 - fabs(envValue - curMinX);
        return distanceWeight * value.matchValue;
    }];
    
    CGFloat adsorCurMaxX = [self adsorbWithBaseValue_Multi:curMaxX envs:bestGVs.allKeys valueBlock:^CGFloat(NSNumber *key) {
        CGRect bestRect = [baseT rectByIndex:key.integerValue];
        return CGRectGetMaxX(bestRect) / width;
    } weightBlock:^CGFloat(NSNumber *key) {
        CGRect bestRect = [baseT rectByIndex:key.integerValue];
        CGFloat envValue = CGRectGetMaxX(bestRect) / width;
        AIFeatureJvBuItem *value = [bestGVs objectForKey:key];
        CGFloat distanceWeight = 1.0 - fabs(envValue - curMaxX);
        return distanceWeight * value.matchValue;
    }];
    
    
    // TODO: 实现吸附后的protoRect计算
    return CGRectZero;
}

@end
