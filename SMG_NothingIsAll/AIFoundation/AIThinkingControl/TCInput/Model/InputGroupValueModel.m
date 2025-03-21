//
//  InputDotModel.m
//  SMG_NothingIsAll
//
//  Created by jia on 2025/3/15.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import "InputGroupValueModel.h"

@implementation InputGroupValueModel

+(id) new:(NSArray*)subDots groupValue:(AIKVPointer*)groupValue_p level:(NSInteger)level x:(NSInteger)x y:(NSInteger)y {
    InputGroupValueModel *result = [[InputGroupValueModel alloc] init];
    result.subDots = subDots;
    result.level = level;
    result.x = x;
    result.y = y;
    result.groupValue_p = groupValue_p;
    return result;
}

@end
