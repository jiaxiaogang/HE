//
//  GTZiJvGroup.m
//  SMG_NothingIsAll
//
//  Created by jia on 2026/3/11.
//  Copyright © 2026 XiaoGang. All rights reserved.
//

#import "GTZiJvModelV2.h"

@implementation GTZiJvModelV2

-(NSMutableDictionary *) bestSTs {
    if (!_bestSTs) _bestSTs = [NSMutableDictionary new];
    return _bestSTs;
}

// 根据已知oldGVs，预计newGV的protoRect（即：用已知protoRects，计算出整体protoRect）。
-(CGRect) hopeProtoRectByIndex:(NSInteger)newBestIndex {
    // bests在baseT中的Rect
    CGRect bests_BaseT = [SMGUtils convertArr2Rect:self.bestSTs.allKeys itemRectBlock:^CGRect(NSNumber *item) {
        return [self.baseGT rectByIndex:item.integerValue];
    }];
    
    // bests在Proto中的Rect
    CGRect bests_Proto = [SMGUtils convertArr2Rect:self.bestSTs.allValues itemRectBlock:^CGRect(STZiJvGroup *item) {
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
    self.gtMatchValue = self.bestSTs.count == 0 ? 0 : [SMGUtils sumOfArr:self.bestSTs.allValues convertBlock:^double(STZiJvGroup *stGroup) {
        return stGroup.stMatchValue;
    }] / self.bestSTs.count;
}

/**
 *  MARK:--------------------辅因子：位置符合度（参考36045）--------------------
 */
-(void) run4GTMatchDegree {
    // 需此时self为单GTGroup
    // 当前GTGroup的所有元素位置符合度的平均值。
    self.gtMatchDegree = self.bestSTs.count == 0 ? 0 : [SMGUtils sumOfArr:self.bestSTs.allKeys convertBlock:^double(NSNumber *key) {
        STZiJvGroup *stGroup = [self.bestSTs objectForKey:key];
        return [stGroup stMatchDegree:[self hopeProtoRectByIndex:key.integerValue]];
    }] / self.bestSTs.count;
}

/**
 *  MARK:--------------------辅因子：元素数归一化值（防过抽：因为只有具象的匹配数count才可能长）--------------------
 */
-(void) run4GTMatchCountRatio {
    self.gtMatchCountRatio = (float)self.bestSTs.count / self.baseGT.count;
}

/**
 *  MARK:--------------------ST时的位置符合度：作用于GT识别竞争因子--------------------
 */
-(void) run4STMatchDegree {
    // 需此时self为单GTGroup
    self.stMatchDegree = self.bestSTs.count == 0 ? 0 : [SMGUtils sumOfArr:self.bestSTs.allValues convertBlock:^double(STZiJvGroup *stGroup) {
        return stGroup.stMatchDegree;
    }] / self.bestSTs.count;
}

/**
 *  MARK:--------------------ST时的匹配率：作用于GT识别竞争因子--------------------
 */
-(void) run4STMatchCountRatio {
    self.stMatchCountRatio = [SMGUtils sumOfArr:self.bestSTs.allValues convertBlock:^CGFloat(STZiJvGroup *stGroup) {
        return stGroup.stMatchCountRatio;
    }] / self.bestSTs.count;
}

/**
 *  MARK:--------------------匹配数归一化值--------------------
 */
-(void) run4CountRatio:(NSInteger)max {
    self.countRatio = (float)self.bestSTs.count / max;
}

// GTModel综合评分（用于GT识别竞争）。
-(CGFloat) zonHeScore {
    // 先不计self.stMatchDegree，因为GV的符合度，到GT识别时，已经算隔层了，再算进来，等于掐断形似匹配。
    return self.countRatio * self.gtMatchValue * self.gtMatchDegree * self.gtMatchCountRatio * self.stMatchCountRatio;
}

// GTModel综合评分的描述。
-(NSString*) zonHeDesc {
    return STRFORMAT(@"匹配度:%.2f 符合度:%.2f 匹配数(防过抽):%.2f (%02ld/%02ld) 匹配率(防过具):%.2f = 综合得分:%.3f",
                     self.gtMatchValue,self.gtMatchDegree,self.countRatio,self.bestSTs.count,self.baseGT.count,self.gtMatchCountRatio * self.stMatchCountRatio,self.zonHeScore);
}

// assST的抽象中，被bestGVs全含的部分（即必能与当前ProtoGT的匹配的absST）。
-(void) run4GTValidAbs_ps {
    NSArray *allAbs = Ports2Pits([AINetUtils absPorts_All:self.baseGT]);
    NSArray *validIndexes = [SMGUtils convertArr:self.bestSTs.allKeys convertBlock:^id(NSNumber *obj) {
        return @(obj.integerValue);
    }];
    
    // 方案1、用抽具象的indexDic映射，来判断它是否全含（前提：需要存上抽具象特征的indexDic映射）。
    NSArray *validAbs = [SMGUtils filterArr:allAbs checkValid:^BOOL(AIKVPointer *item) {
        NSDictionary *indexDic = [self.baseGT getAbsIndexDic:item];
        return ![SMGUtils filterSingleFromArr:indexDic.allValues checkValid:^BOOL(id item) {
            return ![validIndexes containsObject:item];
        }];
    }];
    self.validAbs_ps = [SMGUtils collectArrA:@[self.baseGT.p] arrB:validAbs];
}

@end
