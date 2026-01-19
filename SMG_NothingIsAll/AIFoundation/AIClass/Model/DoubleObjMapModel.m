//
//  DoubleObjMapModel.m
//  SMG_NothingIsAll
//
//  Created by jia on 2025/12/18.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import "DoubleObjMapModel.h"

@implementation DoubleObjMapModel

+(DoubleObjMapModel*) newWithDoubleValue:(double)doubleValue obj:(id)obj {
    DoubleObjMapModel *result = [[DoubleObjMapModel alloc] init];
    result.doubleValue = doubleValue;
    result.obj = obj;
    return result;
}

@end
