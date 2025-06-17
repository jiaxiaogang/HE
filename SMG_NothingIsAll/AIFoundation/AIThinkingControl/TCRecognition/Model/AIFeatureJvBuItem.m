//
//  AIFeatureJvBuItem.m
//  SMG_NothingIsAll
//
//  Created by jia on 2025/5/7.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import "AIFeatureJvBuItem.h"

@implementation AIFeatureJvBuItem

+(id) new:(CGRect)bestGVAtProtoTRect matchValue:(CGFloat)matchValue matchDegree:(CGFloat)matchDegree assIndex:(NSInteger)assIndex {
    
    // 2025.06.12：lastProtoRect强转为Int，避免精度太高，各种aiPort中的以rect防重和rect判等都无效。
    //bestGVAtProtoTRect = CGRectMake((int)bestGVAtProtoTRect.origin.x, (int)bestGVAtProtoTRect.origin.y, (int)bestGVAtProtoTRect.size.width, (int)bestGVAtProtoTRect.size.height);
    
    AIFeatureJvBuItem *result = [AIFeatureJvBuItem new];
    result.bestGVAtProtoTRect = bestGVAtProtoTRect;
    
    //TODOTOMORROW20250617: 查小数rects。
    double yv = 1.0;//余1.0，余完后，得到的是整数部分值。
    if(modf(bestGVAtProtoTRect.origin.x, &yv) > 0.1f) {
        NSLog(@"");
    }
    
    result.matchValue = matchValue;
    result.matchDegree = matchDegree;
    result.assIndex = assIndex;
    return result;
}

@end
