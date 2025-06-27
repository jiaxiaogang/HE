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

-(NSMutableArray *)models {
    if (!_models) _models = [NSMutableArray new];
    return _models;
}

-(void) updateLogDic:(NSInteger)stepX assPId:(NSInteger)assPId {
    if (!self.logDic1) self.logDic1 = [NSMutableDictionary new];
    if (!self.logDic2) self.logDic2 = [NSMutableDictionary new];
    if (!self.logDic3) self.logDic3 = [NSMutableDictionary new];
    NSMutableDictionary *logDic = stepX == 1 ? self.logDic1 : stepX == 2 ? self.logDic2 : stepX == 3 ? self.logDic3 : [NSMutableDictionary new];
    NSNumber *old = [logDic objectForKey:@((assPId / 100) * 100)];
    [logDic setObject:@(NUMTOOK(old).integerValue + 1) forKey:@((assPId / 100) * 100)];
}

-(void) printLogDic {
    if (self.logDic1.count > 0) NSLog(@"aaaa1 %@",CLEANSTR(self.logDic1));
    if (self.logDic2.count > 0) NSLog(@"aaaa2 %@",CLEANSTR(self.logDic2));
    if (self.logDic3.count > 0) NSLog(@"aaaa3 %@",CLEANSTR(self.logDic3));
}

@end
