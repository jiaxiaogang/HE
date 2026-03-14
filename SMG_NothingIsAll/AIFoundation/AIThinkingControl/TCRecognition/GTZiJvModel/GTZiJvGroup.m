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
    CGRect bests_BaseT = [SMGUtils convertArr2Rect:self.bestSTs itemRectBlock:^CGRect(STZiJvGroup *item) {
        return [self.baseGT rectByIndex:item.baseSTIndex];
    }];
    
    // bests在Proto中的Rect
    CGRect bests_Proto = [SMGUtils convertArr2Rect:self.bestSTs itemRectBlock:^CGRect(STZiJvGroup *item) {
        return item.baseST_Proto;
    }];
    
    // index的GV在ST中的Rect
    CGRect newBest_BaseT = [self.baseGT rectByIndex:newBestIndex];
    
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
    self.gtMatchValue = self.bestSTs.count == 0 ? 0 : [SMGUtils sumOfArr:self.bestSTs convertBlock:^double(STZiJvGroup *stGroup) {
        CGFloat stMatchValue = (float)stGroup.bestGVs.count / stGroup.baseST.count;
        return stMatchValue;
    }] / self.bestSTs.count;
}

/**
 *  MARK:--------------------辅因子：位置符合度（参考36045）--------------------
 */
-(void) run4GTMatchDegree {
    // 需此时self为单GTGroup
    // 当前GTGroup的所有元素位置符合度的平均值。
    self.gtMatchDegree = self.bestSTs.count == 0 ? 0 : [SMGUtils sumOfArr:self.bestSTs convertBlock:^double(STZiJvGroup *stGroup) {
        // 当前gtGroup期望其元素stGroup 的 ProtoRect。
        CGRect realRect = stGroup.baseST_Proto;
        CGRect hopeRect = [self hopeProtoRectByIndex:stGroup.baseSTIndex];
        CGFloat stMatchDegree = [SMGUtils rate4IntersectionRectV2:realRect bRect:hopeRect];
        return stMatchDegree;
    }] / self.bestSTs.count;
}

/**
 *  MARK:--------------------ST时的匹配度：作用于GT识别竞争因子--------------------
 */
-(void) run4STMatchValue {
    // 需此时self为单GTGroup
    self.stMatchValue = self.bestSTs.count == 0 ? 0 : [SMGUtils sumOfArr:self.bestSTs convertBlock:^double(STZiJvGroup *stGroup) {
        return stGroup.bestGVs == 0 ? 0 : [SMGUtils sumOfArr:stGroup.bestGVs convertBlock:^double(AIFeatureJvBuItem *gv) {
            return gv.matchValue;
        }] / stGroup.bestGVs.count;
    }] / self.bestSTs.count;
}

/**
 *  MARK:--------------------ST时的位置符合度：作用于GT识别竞争因子--------------------
 */
-(void) run4STMatchDegree {
    // 需此时self为单GTGroup
    self.stMatchDegree = self.bestSTs.count == 0 ? 0 : [SMGUtils sumOfArr:self.bestSTs convertBlock:^double(STZiJvGroup *stGroup) {
        return stGroup.bestGVs == 0 ? 0 : [SMGUtils sumOfArr:stGroup.bestGVs convertBlock:^double(AIFeatureJvBuItem *gv) {
            return gv.matchDegree;
        }] / stGroup.bestGVs.count;
    }] / self.bestSTs.count;
}

// GTModel综合评分（用于GT识别竞争）。
-(CGFloat) zonHeScore {
    return self.gtMatchValue * self.gtMatchDegree * self.stMatchValue * self.stMatchDegree;
}

// assST的抽象中，被bestGVs全含的部分（即必能与当前ProtoGT的匹配的absST）。
-(void) run4GTValidAbsPorts {
    NSArray *allAbsPorts = [AINetUtils absPorts_All:self.baseGT];
    NSArray *validIndexes = [SMGUtils convertArr:self.bestSTs convertBlock:^id(STZiJvGroup *obj) {
        return @(obj.baseSTIndex);
    }];
    
    // 方案1、用抽具象的indexDic映射，来判断它是否全含（前提：需要存上抽具象特征的indexDic映射）。
    self.validAbsPorts = [SMGUtils filterArr:allAbsPorts checkValid:^BOOL(AIPort *item) {
        NSDictionary *indexDic = [self.baseGT getAbsIndexDic:item.target_p];
        return ![SMGUtils filterSingleFromArr:indexDic.allValues checkValid:^BOOL(id item) {
            return ![validIndexes containsObject:item];
        }];
    }];
}

@end
