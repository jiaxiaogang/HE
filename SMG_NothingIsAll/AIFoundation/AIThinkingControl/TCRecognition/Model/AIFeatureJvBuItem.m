//
//  AIFeatureJvBuItem.m
//  SMG_NothingIsAll
//
//  Created by jia on 2025/5/7.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import "AIFeatureJvBuItem.h"

@implementation AIFeatureJvBuItem

+(id) new:(CGRect)bestGVAtProtoTRect baseGV_p:(AIKVPointer*)baseGV_p baseGVMatchValue:(NSDictionary*)baseGVMatchValue protoGVIndex:(NSDictionary*)protoGVIndex {
    AIFeatureJvBuItem *result = [AIFeatureJvBuItem new];
    result.bestGVAtProtoTRect = bestGVAtProtoTRect;
    result.matchValue = [SMGUtils productOfArr:baseGVMatchValue.allValues convertBlock:^double(NSNumber *obj) {
        return obj.doubleValue;
    }];
    result.baseGV_p = baseGV_p;
    result.baseGVMatchValue = baseGVMatchValue;
    result.protoGVIndex = protoGVIndex;
    return result;
}

@end
