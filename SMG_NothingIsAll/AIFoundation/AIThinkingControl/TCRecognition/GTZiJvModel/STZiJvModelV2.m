//
//  STZiJvGroup.m
//  SMG_NothingIsAll
//
//  Created by jia on 2026/3/14.
//  Copyright © 2026 XiaoGang. All rights reserved.
//

#import "STZiJvModelV2.h"

@implementation STZiJvModelV2

-(NSMutableDictionary *) bestGVs {
    if (!_bestGVs) _bestGVs = [NSMutableDictionary new];
    return _bestGVs;
}

// 根据已知oldGVs，预计newGV的protoRect（即：用已知protoRects，计算出整体protoRect）。
-(CGRect) hopeProtoRectByIndex:(NSInteger)newBestIndex {
    // index的GV在ST中的Rect
    CGRect newBest_BaseT = [self.baseST rectByIndex:newBestIndex];
    
    // 用newGV_ST、以及已知gvs_Proto、已知gvs_ST，预计出newGV_Proto。
    CGRect newBest_Proto = [self hopeProtoRect:newBest_BaseT];
    return newBest_Proto; // 即为：预计newGV的protoRect。
}

// 根据已有bestGVs，实时推算出当前baseST_Proto。
-(CGRect) hopeProtoRectByAll {
    if (CGRectIsNull(self.hopeProtoRectByAllCache)) {
        // allBases在baseT中的Rect
        CGRect baseT_BaseT = [self.baseST rect];
        CGRect baseT_Proto = [self hopeProtoRect:baseT_BaseT]; // 推算出allBases在Proto中的Rect。
        self.hopeProtoRectByAllCache = baseT_Proto;
    }
    return self.hopeProtoRectByAllCache;
}

// 根据已有bestGVs的线索，推算baseST中新的某部分范围，对应到Proto中的Rect。
-(CGRect) hopeProtoRect:(CGRect)part_BaseST {
    
    // TODO: 当bestGVs为空时，也要根据beginST切入点，来推算出一个默认结果出来。
    
    // bests在baseT中的Rect
    CGRect bests_BaseT = [self bestGVs_ST];
    
    // bests在Proto中的Rect
    CGRect bests_Proto = [self bestGVs_Proto];
    
    // index的GV在ST中的Rect
    CGRect baseT_BaseT = [self.baseST rect];
    
    // 用newGV_ST、以及已知gvs_Proto、已知gvs_ST，预计出newGV_Proto。
    CGRect part_Proto = [SMGUtils convertNewAAtCWithAAtB:bests_BaseT aAtC:bests_Proto newAAtB:part_BaseST];
    
    // 即为：预计newGV的protoRect。
    return part_Proto;
}

-(CGRect) bestGVs_ST {
    return [SMGUtils convertArr2Rect:self.bestGVs.allKeys itemRectBlock:^CGRect(NSNumber *item) {
        return [self.baseST rectByIndex:item.integerValue];
    }];
}

-(CGRect) bestGVs_Proto {
    return [SMGUtils convertArr2Rect:self.bestGVs.allValues itemRectBlock:^CGRect(AIFeatureJvBuItem *item) {
        return item.bestGVAtProtoTRect;
    }];
}

-(CGFloat) stMatchValue {
    return self.bestGVs == 0 ? 0 : [SMGUtils sumOfArr:self.bestGVs.allValues convertBlock:^double(AIFeatureJvBuItem *gv) {
        return gv.matchValue;
    }] / self.bestGVs.count;
}

-(CGFloat) stMatchDegree {
    return self.bestGVs == 0 ? 0 : [SMGUtils sumOfArr:self.bestGVs.allValues convertBlock:^double(AIFeatureJvBuItem *gv) {
        return gv.matchDegree;
    }] / self.bestGVs.count;
}

-(CGFloat) stMatchCountRatio {
    return (float)self.bestGVs.count / self.baseST.count;
}

/**
 *  MARK:--------------------st位置符合度--------------------
 *  @param hopeRect 传所属GT期望当前st在Proto中的位置。
 */
-(CGFloat) stMatchDegree:(CGRect)hopeRect {
    // 当前gtGroup期望其元素stGroup 的 ProtoRect。
    CGRect realRect = self.hopeProtoRectByAll;
    CGFloat stMatchDegree = [SMGUtils rate4IntersectionRectV2:realRect bRect:hopeRect];
    return stMatchDegree;
}

@end
