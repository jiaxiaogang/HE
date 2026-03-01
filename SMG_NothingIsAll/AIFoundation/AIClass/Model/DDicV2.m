//
//  DDicV2.m
//  SMG_NothingIsAll
//
//  Created by jia on 2026/3/1.
//  Copyright © 2026 XiaoGang. All rights reserved.
//

#import "DDicV2.h"

@implementation DDicV2

-(DDicV2*) sub:(id)key {
    DDicV2 *sub = [self objectForKey:key];
    return sub;
}

// 为空时，会新建一个。
-(DDicV2*) subOk:(id)key {
    DDicV2 *sub = [self objectForKey:key];
    if (!ISOK(sub, DDicV2.class)) {
        sub = [DDicV2 new];
        [self setObject:sub forKey:key];
    }
    return sub;
}

-(id) objectForKeys:(NSArray*)keys {
    DDicV2 *curV = self;
    for (NSInteger i = 0; i < keys.count; i++) {
        // 数据准备 & 数据检查
        id curK = ARR_INDEX(keys, i);
        if (!ISOK(curV, DDicV2.class)) break;
        
        // 最后一位则返回，否则取subDic。
        if (i == keys.count - 1) {
            return [curV objectForKey:curK];
        } else {
            curV = [curV sub:curK];
        }
    }
    return nil;
}

-(void) setObject:(id)object forKeys:(NSArray*)keys {
    DDicV2 *curV = self;
    for (NSInteger i = 0; i < keys.count; i++) {
        // 数据准备
        id curK = ARR_INDEX(keys, i);
        
        // 最后一位则存值，否则取subDic。
        if (i == keys.count - 1) {
            [curV setObject:object forKey:curK];
        } else {
            curV = [curV subOk:curK];
        }
    }
}

//MARK:===============================================================
//MARK:                     < 示例 >
//MARK:===============================================================
-(id) objectForKey:(id)k1 k2:(id)k2 k3:(id)k3 k4:(id)k4 k5:(id)k5 {
    // return [[[[[self sub:k1] sub:k2] sub:k3] sub:k4] objectForKey:k5];
    return [self objectForKeys:@[k1,k2,k3,k4,k5]];
}

-(void) setObject:(id)v5 k1:(id)k1 k2:(id)k2 k3:(id)k3 k4:(id)k4 k5:(id)k5 {
    // DDicV2 *v4 = [[[[self subOk:k1] subOk:k2] subOk:k3] subOk:k4];
    // [v4 setObject:v5 forKey:k5];
    [self setObject:v5 forKeys:@[k1,k2,k3,k4,k5]];
}

@end
