//
//  AIFeatureJvBuModels.m
//  SMG_NothingIsAll
//
//  Created by jia on 2025/5/7.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import "AIFeatureJvBuModels.h"

@implementation AIFeatureJvBuModels

+(id) new:(NSInteger)hash {
    AIFeatureJvBuModels *result = [AIFeatureJvBuModels new];
    result.protoTHash = hash;
    return result;
}

-(NSMutableArray *)stModels {
    if (!_stModels) _stModels = [NSMutableArray new];
    return _stModels;
}

-(NSMutableArray *)gtModels {
    if (!_gtModels) _gtModels = [NSMutableArray new];
    return _gtModels;
}

@end
