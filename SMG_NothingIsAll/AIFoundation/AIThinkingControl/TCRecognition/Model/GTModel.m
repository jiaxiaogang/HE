//
//  GTModel.m
//  SMG_NothingIsAll
//
//  Created by jia on 2025/9/23.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import "GTModel.h"

@implementation GTModel

+(id) new:(AIGroupFeatureNode*)assGT {
    GTModel *result = [GTModel new];
    result.assGT = assGT;
    return result;
}

@end
