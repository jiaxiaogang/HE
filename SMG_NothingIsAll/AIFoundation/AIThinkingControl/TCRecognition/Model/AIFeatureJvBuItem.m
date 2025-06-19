//
//  AIFeatureJvBuItem.m
//  SMG_NothingIsAll
//
//  Created by jia on 2025/5/7.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import "AIFeatureJvBuItem.h"

@implementation AIFeatureJvBuItem

+(id) new:(CGRect)bestGVAtProtoTRect matchValue:(CGFloat)matchValue matchDegree:(CGFloat)matchDegree assIndex:(NSInteger)assIndex diffValue:(CGFloat)diffValue {
    AIFeatureJvBuItem *result = [AIFeatureJvBuItem new];
    result.bestGVAtProtoTRect = bestGVAtProtoTRect;
    result.matchValue = matchValue;
    result.matchDegree = matchDegree;
    result.assIndex = assIndex;
    result.diffValue = diffValue;
    return result;
}

@end
