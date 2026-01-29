//
//  GTItemV2.m
//  SMG_NothingIsAll
//
//  Created by jia on 2026/1/29.
//  Copyright © 2026 XiaoGang. All rights reserved.
//

#import "GTItemV2.h"

@implementation GTItemV2

-(CGRect) assST_ProtoGT {
    return self.stModel.assST_ProtoRect;
}

-(CGRect) absST_ProtoGT {
    // TODOTOMORROW20260129: 计算这个rect。
    return self.stModel.assST_ProtoRect;
}

-(CGRect) itemST_ProtoGT {
    return self.stModel.assST_ProtoRect;
}

@end
