//
//  MapModel.m
//  SMG_NothingIsAll
//
//  Created by jia on 2023/12/26.
//  Copyright © 2023 XiaoGang. All rights reserved.
//

#import "MapModel.h"

@implementation MapModel

+(MapModel*) newWithV1:(id)v1 v2:(id)v2 {
    return [self newWithV1:v1 v2:v2 v3:nil];
}

+(MapModel*) newWithV1:(id)v1 v2:(id)v2 v3:(id)v3 {
    return [self newWithV1:v1 v2:v2 v3:v3 v4:nil];
}

+(MapModel*) newWithV1:(id)v1 v2:(id)v2 v3:(id)v3 v4:(id)v4 {
    MapModel *result = [[MapModel alloc] init];
    result.v1 = v1;
    result.v2 = v2;
    result.v3 = v3;
    result.v4 = v4;
    return result;
}

-(BOOL)isEqual:(MapModel*)object {
    if (self.v1 && object.v1 && ![self.v1 isEqual:object.v1]) return false;
    if (self.v2 && object.v2 && ![self.v2 isEqual:object.v2]) return false;
    if (self.v3 && object.v3 && ![self.v3 isEqual:object.v3]) return false;
    if (self.v4 && object.v4 && ![self.v4 isEqual:object.v4]) return false;
    return true;
}

@end
