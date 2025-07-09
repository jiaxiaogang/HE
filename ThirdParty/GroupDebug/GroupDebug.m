//
//  GroupDebug.m
//  SMG_NothingIsAll
//
//  Created by jia on 2025/7/9.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import "GroupDebug.h"

@implementation GroupDebug

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
