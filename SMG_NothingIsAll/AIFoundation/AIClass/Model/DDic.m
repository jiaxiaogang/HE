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

/**
 *  MARK:--------------------objectForKey--------------------
 */
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

-(id) objectV6ForKey1:(id)k1 k2:(id)k2 k3:(id)k3 k4:(id)k4 k5:(id)k5 k6:(id)k6 {
    DDic *base = [self objectV5ForKey1:k1 k2:k2 k3:k3 k4:k4 k5:k5];
    return !base ? nil : [base objectForKey:k6];
}

-(id) objectV7ForKey1:(id)k1 k2:(id)k2 k3:(id)k3 k4:(id)k4 k5:(id)k5 k6:(id)k6 k7:(id)k7 {
    DDic *base = [self objectV6ForKey1:k1 k2:k2 k3:k3 k4:k4 k5:k5 k6:k6];
    return !base ? nil : [base objectForKey:k7];
}

-(id) objectV8ForKey1:(id)k1 k2:(id)k2 k3:(id)k3 k4:(id)k4 k5:(id)k5 k6:(id)k6 k7:(id)k7 k8:(id)k8 {
    DDic *base = [self objectV7ForKey1:k1 k2:k2 k3:k3 k4:k4 k5:k5 k6:k6 k7:k7];
    return !base ? nil : [base objectForKey:k8];
}

/**
 *  MARK:--------------------setObject--------------------
 */
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

-(void) setObjectV6:(id)v6 k1:(id)k1 k2:(id)k2 k3:(id)k3 k4:(id)k4 k5:(id)k5 k6:(id)k6 {
    DDic *base = [self baseForKeyOrCreate:k1 k2:k2 k3:k3 k4:k4 k5:k5];
    [base setObject:v6 forKey:k6];
}

-(void) setObjectV7:(id)v7 k1:(id)k1 k2:(id)k2 k3:(id)k3 k4:(id)k4 k5:(id)k5 k6:(id)k6 k7:(id)k7 {
    DDic *base = [self baseForKeyOrCreate:k1 k2:k2 k3:k3 k4:k4 k5:k5 k6:k6];
    [base setObject:v7 forKey:k7];
}

-(void) setObjectV8:(id)v8 k1:(id)k1 k2:(id)k2 k3:(id)k3 k4:(id)k4 k5:(id)k5 k6:(id)k6 k7:(id)k7 k8:(id)k8 {
    DDic *base = [self baseForKeyOrCreate:k1 k2:k2 k3:k3 k4:k4 k5:k5 k6:k6 k7:k7];
    [base setObject:v8 forKey:k8];
}

/**
 *  MARK:--------------------构建新的子字典--------------------
 */
-(DDic*) createSubDic:(id)subK base:(DDic*)base {
    DDic *subV = [DDic new];
    [base setObject:subV forKey:subK];
    return subV;
}

/**
 *  MARK:--------------------baseDic为空时初始化--------------------
 */
-(DDic*) baseForKeyOrCreate:(id)k1 {
    DDic *result = [self objectForKey:k1];
    if (!result) {
        result = [DDic new];
        [self setObject:result forKey:k1];
    }
    return result;
}

-(DDic*) baseForKeyOrCreate:(id)k1 k2:(id)k2 {
    DDic *result = [self objectV2ForKey1:k1 k2:k2];
    if (!result) {
        result = [DDic new];
        DDic *base = [self baseForKeyOrCreate:k1];
        [base setObject:result forKey:k2];
    }
    return result;
}

-(DDic*) baseForKeyOrCreate:(id)k1 k2:(id)k2 k3:(id)k3 {
    DDic *result = [self objectV3ForKey1:k1 k2:k2 k3:k3];
    if (!result) {
        result = [DDic new];
        DDic *base = [self baseForKeyOrCreate:k1 k2:k2];
        [base setObject:result forKey:k3];
    }
    return result;
}

-(DDic*) baseForKeyOrCreate:(id)k1 k2:(id)k2 k3:(id)k3 k4:(id)k4 {
    DDic *result = [self objectV4ForKey1:k1 k2:k2 k3:k3 k4:k4];
    if (!result) {
        result = [DDic new];
        DDic *base = [self baseForKeyOrCreate:k1 k2:k2 k3:k3];
        [base setObject:result forKey:k4];
    }
    return result;
}

-(DDic*) baseForKeyOrCreate:(id)k1 k2:(id)k2 k3:(id)k3 k4:(id)k4 k5:(id)k5 {
    DDic *result = [self objectV5ForKey1:k1 k2:k2 k3:k3 k4:k4 k5:k5];
    if (!result) {
        result = [DDic new];
        DDic *base = [self baseForKeyOrCreate:k1 k2:k2 k3:k3 k4:k4];
        [base setObject:result forKey:k5];
    }
    return result;
}

-(DDic*) baseForKeyOrCreate:(id)k1 k2:(id)k2 k3:(id)k3 k4:(id)k4 k5:(id)k5 k6:(id)k6 {
    DDic *result = [self objectV6ForKey1:k1 k2:k2 k3:k3 k4:k4 k5:k5 k6:k6];
    if (!result) {
        result = [DDic new];
        DDic *base = [self baseForKeyOrCreate:k1 k2:k2 k3:k3 k4:k4 k5:k5];
        [base setObject:result forKey:k6];
    }
    return result;
}

-(DDic*) baseForKeyOrCreate:(id)k1 k2:(id)k2 k3:(id)k3 k4:(id)k4 k5:(id)k5 k6:(id)k6 k7:(id)k7 {
    DDic *result = [self objectV7ForKey1:k1 k2:k2 k3:k3 k4:k4 k5:k5 k6:k6 k7:k7];
    if (!result) {
        result = [DDic new];
        DDic *base = [self baseForKeyOrCreate:k1 k2:k2 k3:k3 k4:k4 k5:k5 k6:k6];
        [base setObject:result forKey:k7];
    }
    return result;
}

@end
