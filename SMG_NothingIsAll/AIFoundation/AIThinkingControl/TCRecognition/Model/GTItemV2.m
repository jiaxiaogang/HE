//
//  GTItemV2.m
//  SMG_NothingIsAll
//
//  Created by jia on 2026/1/29.
//  Copyright © 2026 XiaoGang. All rights reserved.
//

#import "GTItemV2.h"

@implementation GTItemV2

-(CGRect) assST_ProtoT {
    return self.baseSTModel.assST_ProtoRect;
}

-(CGRect) absST_ProtoT {
    // 设AbsST为A，AssST为B，ProtoT为C计算如下：
    // A_B
    AIPort *conPort = [SMGUtils filterSingleFromArr:self.baseAbsST.conPorts checkValid:^BOOL(AIPort *item) {
        return [item.target_p isEqual:self.baseSTModel.assT.p];
    }];
    CGRect absST_AssST = conPort.rect;
    
    // B_C
    CGRect assST_ProtoT = [self assST_ProtoT];
    
    // BSize
    CGRect assSTRect = [SMGUtils convertArr2Rect:self.baseSTModel.assT.rects itemRectBlock:^CGRect(NSValue *item) {
        return item.CGRectValue;
    }];
    
    // A_C
    CGRect absST_ProtoT = [SMGUtils convertAAtCWithAAtB:absST_AssST bAtC:assST_ProtoT protoBSize:assSTRect.size];
    return absST_ProtoT;
}

-(CGRect) itemST_ProtoT {
    // TODOTOMORROW20260129: 计算这个rect。
    // itemST就是broST
    // 已知broST和absST的Rect
    // 已知absST和ProtoT的Rect
    // 求result
    return CGRectZero;
}

@end
