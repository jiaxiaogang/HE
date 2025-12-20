//
//  DDic.m
//  SMG_NothingIsAll
//
//  Created by jia on 2025/5/10.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import "DDic.h"

@implementation DDic

-(NSMutableDictionary *)data {
    if (!_data) _data = [NSMutableDictionary new];
    return _data;
}

-(id) objectForKey:(id)key {
    return [self.data objectForKey:key];
}

-(id) objectV2ForKey1:(id)k1 k2:(id)k2 {
    DDic *v1 = [self.data objectForKey:k1];
    if (!v1) return nil;
    return [v1 objectForKey:k2];
}

-(id) objectV3ForKey1:(id)k1 k2:(id)k2 k3:(id)k3 {
    DDic *v1 = [self.data objectForKey:k1];
    if (!v1) return nil;
    DDic *v2 = [v1 objectForKey:k2];
    if (!v2) return nil;
    return [v2 objectForKey:k3];
}

-(id) objectV4ForKey1:(id)k1 k2:(id)k2 k3:(id)k3 k4:(id)k4 {
    DDic *v1 = [self.data objectForKey:k1];
    if (!v1) return nil;
    DDic *v2 = [v1 objectForKey:k2];
    if (!v2) return nil;
    DDic *v3 = [v2 objectForKey:k3];
    if (!v3) return nil;
    return [v3 objectForKey:k4];
}

-(id) objectV5ForKey1:(id)k1 k2:(id)k2 k3:(id)k3 k4:(id)k4 k5:(id)k5 {
    DDic *v1 = [self.data objectForKey:k1];
    if (!v1) return nil;
    DDic *v2 = [v1 objectForKey:k2];
    if (!v2) return nil;
    DDic *v3 = [v2 objectForKey:k3];
    if (!v3) return nil;
    DDic *v4 = [v3 objectForKey:k4];
    if (!v4) return nil;
    return [v4 objectForKey:k5];
}

-(void) setObject:(id)value forKey:(id)key {
    [self.data setObject:value forKey:key];
}

-(void) setObjectV2:(id)v2 k1:(id)k1 k2:(id)k2 {
    DDic *v1 = [self.data objectForKey:k1];
    if (!v1) v1 = [self createSubDic:k1 base:self];
    [v1 setObject:v2 forKey:k2];
}

-(void) setObjectV3:(id)v3 k1:(id)k1 k2:(id)k2 k3:(id)k3 {
    DDic *v1 = [self.data objectForKey:k1];
    if (!v1) v1 = [self createSubDic:k1 base:self];
    DDic *v2 = [v1 objectForKey:k2];
    if (!v2) v2 = [self createSubDic:k2 base:v1];
    [v2 setObject:v3 forKey:k3];
}

-(void) setObjectV4:(id)v4 k1:(id)k1 k2:(id)k2 k3:(id)k3 k4:(id)k4 {
    DDic *v1 = [self.data objectForKey:k1];
    if (!v1) v1 = [self createSubDic:k1 base:self];
    DDic *v2 = [v1 objectForKey:k2];
    if (!v2) v2 = [self createSubDic:k2 base:v1];
    DDic *v3 = [v2 objectForKey:k3];
    if (!v3) v3 = [self createSubDic:k3 base:v2];
    [v3 setObject:v4 forKey:k4];
}

-(void) setObjectV5:(id)v5 k1:(id)k1 k2:(id)k2 k3:(id)k3 k4:(id)k4 k5:(id)k5 {
    DDic *v1 = [self.data objectForKey:k1];
    if (!v1) v1 = [self createSubDic:k1 base:self];
    DDic *v2 = [v1 objectForKey:k2];
    if (!v2) v2 = [self createSubDic:k2 base:v1];
    DDic *v3 = [v2 objectForKey:k3];
    if (!v3) v3 = [self createSubDic:k3 base:v2];
    DDic *v4 = [v3 objectForKey:k4];
    if (!v4) v4 = [self createSubDic:k4 base:v3];
    [v4 setObject:v5 forKey:k5];
}

/**
 *  MARK:--------------------构建新的子字典--------------------
 */
-(DDic*) createSubDic:(id)subK base:(DDic*)base {
    DDic *subV = [DDic new];
    [base setObject:subV forKey:subK];
    return subV;
}

@end
