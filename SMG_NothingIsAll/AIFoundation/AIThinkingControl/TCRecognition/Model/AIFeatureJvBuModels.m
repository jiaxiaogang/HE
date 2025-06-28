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
    if (!self.logDics) self.logDics = [NSMutableDictionary new];
    NSMutableDictionary *itemDic = [self.logDics objectForKey:@(stepX)];
    if (!itemDic) {
        itemDic = [NSMutableDictionary new];
        [self.logDics setObject:itemDic forKey:@(stepX)];
    }
    NSNumber *old = [itemDic objectForKey:@((assPId / 100) * 100)];
    [itemDic setObject:@(NUMTOOK(old).integerValue + 1) forKey:@((assPId / 100) * 100)];
}

-(void) printLogDic {
    NSArray *sortKeys = [SMGUtils sortSmall2Big:self.logDics.allKeys compareBlock:^double(NSNumber *obj) {
        return obj.integerValue;
    }];
    for (NSNumber *key in sortKeys) {
        NSMutableDictionary *value = [self.logDics objectForKey:key];
        NSArray *itemLog = [SMGUtils convertArr:[SMGUtils sortSmall2Big:value.allKeys compareBlock:^double(NSNumber *obj) {
            return obj.integerValue;
        }] convertBlock:^id(NSNumber *itemKey) {
            NSNumber *itemValue = [value objectForKey:itemKey];
            return STRFORMAT(@"%ld = %ld",itemKey.integerValue,itemValue.integerValue);
        }];
        NSLog(@"aaaa%ld %@",key.integerValue,CLEANSTR(itemLog));
    }
}

@end
