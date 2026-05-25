//
//  AIFeatureJvBuItem.m
//  SMG_NothingIsAll
//
//  Created by jia on 2025/5/7.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import "AIFeatureJvBuItem.h"

@implementation AIFeatureJvBuItem

+(id) new:(CGRect)bestGVAtProtoTRect matchValue:(CGFloat)matchValue matchDegree:(CGFloat)matchDegree baseGV_p:(AIKVPointer*)baseGV_p {
    AIFeatureJvBuItem *result = [AIFeatureJvBuItem new];
    result.bestGVAtProtoTRect = bestGVAtProtoTRect;
    result.matchValue = matchValue;
    result.matchDegree = matchDegree;
    result.baseGV_p = baseGV_p;
    return result;
}

@end
