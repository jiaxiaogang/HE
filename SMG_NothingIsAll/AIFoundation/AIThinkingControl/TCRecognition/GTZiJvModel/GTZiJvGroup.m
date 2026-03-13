//
//  GTZiJvGroup.m
//  SMG_NothingIsAll
//
//  Created by jia on 2026/3/11.
//  Copyright © 2026 XiaoGang. All rights reserved.
//

#import "GTZiJvGroup.h"

@implementation GTZiJvGroup

// 根据已知oldGVs，预计newGV的protoRect（即：用已知protoRects，计算出整体protoRect）。
-(CGRect) hopeProtoRectByIndex:(NSInteger)newBestIndex {
    // bests在baseT中的Rect
    CGRect bests_BaseT = [SMGUtils convertArr2Rect:self.bests itemRectBlock:^CGRect(id obj) {
        if (ISOK(obj, AIFeatureJvBuItem.class)) {
            AIFeatureJvBuItem *item = (AIFeatureJvBuItem*)obj;
            return [self.baseT rectByIndex:item.baseIndex];
        } else if (ISOK(obj, GTZiJvGroup.class)) {
            GTZiJvGroup *item = (GTZiJvGroup*)obj;
            return [self.baseT rectByIndex:item.baseSTIndex];
        }
        return CGRectNull;
    }];
    
    // bests在Proto中的Rect
    CGRect bests_Proto = [SMGUtils convertArr2Rect:self.bests itemRectBlock:^CGRect(id obj) {
        if (ISOK(obj, AIFeatureJvBuItem.class)) {
            AIFeatureJvBuItem *item = (AIFeatureJvBuItem*)obj;
            return item.bestGVAtProtoTRect;
        } else if (ISOK(obj, GTZiJvGroup.class)) {
            GTZiJvGroup *item = (GTZiJvGroup*)obj;
            return item.baseST_Proto;
        }
        return CGRectNull;
    }];
    
    // index的GV在ST中的Rect
    CGRect newBest_BaseT = [self.baseT rectByIndex:newBestIndex];
    
    // 用newGV_ST、以及已知gvs_Proto、已知gvs_ST，预计出newGV_Proto。
    CGRect newBest_Proto = [SMGUtils convertNewAAtCWithAAtB:bests_BaseT aAtC:bests_Proto newAAtB:newBest_BaseT];
    
    // 即为：预计newGV的protoRect。
    return newBest_Proto;
}

/**
 *  MARK:--------------------主因子：匹配度--------------------
 */
-(void) run4GTMatchValue {
    // 需此时self为单GTGroup
    self.gtMatchValue = self.bests.count == 0 ? 0 : [SMGUtils sumOfArr:self.bests convertBlock:^double(GTZiJvGroup *stGroup) {
        CGFloat stMatchValue = (float)stGroup.bests.count / stGroup.baseT.count;
        return stMatchValue;
    }] / self.bests.count;
}

/**
 *  MARK:--------------------辅因子：位置符合度（参考36045）--------------------
 */
-(void) run4GTMatchDegree {
    // 需此时self为单GTGroup
    // 当前GTGroup的所有元素位置符合度的平均值。
    self.gtMatchDegree = self.bests.count == 0 ? 0 : [SMGUtils sumOfArr:self.bests convertBlock:^double(GTZiJvGroup *stGroup) {
        // 当前gtGroup期望其元素stGroup 的 ProtoRect。
        CGRect realRect = stGroup.baseST_Proto;
        CGRect hopeRect = [self hopeProtoRectByIndex:stGroup.baseSTIndex];
        CGFloat stMatchDegree = [SMGUtils rate4IntersectionRectV2:realRect bRect:hopeRect];
        return stMatchDegree;
    }] / self.bests.count;
}

/**
 *  MARK:--------------------ST时的匹配度：作用于GT识别竞争因子--------------------
 */
-(void) run4STMatchValue {
    // 需此时self为单GTGroup
    self.stMatchValue = self.bests.count == 0 ? 0 : [SMGUtils sumOfArr:self.bests convertBlock:^double(GTZiJvGroup *stGroup) {
        return stGroup.bests == 0 ? 0 : [SMGUtils sumOfArr:stGroup.bests convertBlock:^double(AIFeatureJvBuItem *gv) {
            return gv.matchValue;
        }] / stGroup.bests.count;
    }] / self.bests.count;
}

/**
 *  MARK:--------------------ST时的位置符合度：作用于GT识别竞争因子--------------------
 */
-(void) run4STMatchDegree {
    // 需此时self为单GTGroup
    self.stMatchDegree = self.bests.count == 0 ? 0 : [SMGUtils sumOfArr:self.bests convertBlock:^double(GTZiJvGroup *stGroup) {
        return stGroup.bests == 0 ? 0 : [SMGUtils sumOfArr:stGroup.bests convertBlock:^double(AIFeatureJvBuItem *gv) {
            return gv.matchDegree;
        }] / stGroup.bests.count;
    }] / self.bests.count;
}

@end
