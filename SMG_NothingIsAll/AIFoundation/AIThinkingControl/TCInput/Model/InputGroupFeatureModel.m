//
//  InputGroupFeatureModel.m
//  SMG_NothingIsAll
//
//  Created by jia on 2025/5/12.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import "InputGroupFeatureModel.h"

@implementation InputGroupFeatureModel

+(id) new:(AIKVPointer*)feature_p rect:(CGRect)rect {
    InputGroupFeatureModel *result = [[InputGroupFeatureModel alloc] init];
    result.rect = rect;
    result.feature_p = feature_p;
    if (rect.size.width == 0 || rect.size.height == 0) {
        ELog(@"查下这里rect尺寸为0复现时，这个尺寸为0哪来的1");
    }
    return result;
}

@end
