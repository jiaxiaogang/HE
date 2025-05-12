//
//  InputDotModel.m
//  SMG_NothingIsAll
//
//  Created by jia on 2025/3/15.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import "InputGroupValueModel.h"

@implementation InputGroupValueModel

+(id) new:(AIKVPointer*)groupValue_p rect:(CGRect)rect {
    InputGroupValueModel *result = [[InputGroupValueModel alloc] init];
    result.rect = rect;
    result.groupValue_p = groupValue_p;
    return result;
}

@end
