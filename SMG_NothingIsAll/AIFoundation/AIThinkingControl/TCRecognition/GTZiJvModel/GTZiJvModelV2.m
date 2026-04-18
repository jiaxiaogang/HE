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
    // index的GV在ST中的Rect
    CGRect newBest_BaseT = [self.baseGT rectByIndex:newBestIndex];
    
    // 用newGV_ST、以及已知gvs_Proto、已知gvs_ST，预计出newGV_Proto。
    CGRect newBest_Proto = [self hopeProtoRect:newBest_BaseT];
    
    // 即为：预计newGV的protoRect。
    return newBest_Proto;
}

// 根据已有bestGVs，实时推算出当前baseST_Proto。
-(CGRect) hopeProtoRectByAll {
    if (CGRectIsNull(self.hopeProtoRectByAllCache)) {
        // allBases在baseT中的Rect
        CGRect baseT_BaseT = [self.baseGT rect];
        CGRect baseT_Proto = [self hopeProtoRect:baseT_BaseT]; // 推算出allBases在Proto中的Rect。
        self.hopeProtoRectByAllCache = baseT_Proto;
    }
    return self.self.hopeProtoRectByAllCache;
}

// 根据已有bestGVs的线索，推算baseST中新的某部分范围，对应到Proto中的Rect。
-(CGRect) hopeProtoRect:(CGRect)part_BaseST {
    // bests在baseT中的Rect
    CGRect bests_BaseT = [SMGUtils convertArr2Rect:self.bestSTs.allKeys itemRectBlock:^CGRect(NSNumber *item) {
        return [self.baseGT rectByIndex:item.integerValue];
    }];
    
    // bests在Proto中的Rect
    CGRect bests_Proto = [SMGUtils convertArr2Rect:self.bestSTs.allValues itemRectBlock:^CGRect(STZiJvModelV2 *item) {
        return item.hopeProtoRectByAll;
    }];
    
    // 用newGV_ST、以及已知gvs_Proto、已知gvs_ST，预计出newGV_Proto。
    CGRect part_Proto = [SMGUtils convertNewAAtCWithAAtB:bests_BaseT aAtC:bests_Proto newAAtB:part_BaseST];
    
    // 即为：预计newGV的protoRect。
    return part_Proto;
}

/**
 *  MARK:--------------------主因子：匹配度--------------------
 */
-(void) run4GTMatchValue {
    // 需此时self为单GTGroup
    self.gtMatchValue = self.bestSTs.count == 0 ? 0 : [SMGUtils productOfArr:self.bestSTs.allValues convertBlock:^double(STZiJvModelV2 *stGroup) {
        return stGroup.stMatchValue;
    }];
}

/**
 *  MARK:--------------------辅因子：位置符合度（参考36045）--------------------
 */
-(void) run4GTMatchDegree {
    // 需此时self为单GTGroup
    // 当前GTGroup的所有元素位置符合度的平均值。
    self.gtMatchDegree = self.bestSTs.count == 0 ? 0 : [SMGUtils sumOfArr:self.bestSTs.allKeys convertBlock:^double(NSNumber *key) {
        STZiJvModelV2 *stGroup = [self.bestSTs objectForKey:key];
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
    self.stMatchDegree = self.bestSTs.count == 0 ? 0 : [SMGUtils sumOfArr:self.bestSTs.allValues convertBlock:^double(STZiJvModelV2 *stGroup) {
        return stGroup.stMatchDegree;
    }] / self.bestSTs.count;
}

/**
 *  MARK:--------------------ST时的匹配率：作用于GT识别竞争因子--------------------
 */
-(void) run4STMatchCountRatio {
    self.stMatchCountRatio = self.bestSTs.count == 0 ? 0 : [SMGUtils sumOfArr:self.bestSTs.allValues convertBlock:^CGFloat(STZiJvModelV2 *stGroup) {
        return stGroup.stMatchCountRatio;
    }] / self.bestSTs.count;
}

/**
 *  MARK:--------------------匹配率V2：直接按bestGVs总数 / GT的总gv数--------------------
 */
-(void) run4MatchCountRatioV2 {
    NSInteger allBestCount = [self allBestCount];
    NSInteger allGVCount = [self allGVCount];
    self.matchCountRatioV2 = allGVCount > 0 ? (float)allBestCount / allGVCount : 0;
}

-(NSInteger) allBestCount {
    return [SMGUtils sumOfArr:self.bestSTs.allValues convertBlock:^double(STZiJvModelV2 *stGroup) {
        return stGroup.bestGVs.count;
    }];
}

-(NSInteger) allGVCount {
    return [SMGUtils sumOfArr:self.baseGT.content_ps convertBlock:^double(AIKVPointer *st_p) {
        AIFeatureNode *st = [SMGUtils searchNode:st_p];
        return st.count;
    }];
}

/**
 *  MARK:--------------------匹配数归一化值--------------------
 */
-(void) run4CountRatio:(NSInteger)max {
    self.countRatio = (float)self.bestSTs.count / max;
}

/**
 *  MARK:--------------------辅因子：完整性（参考36143-方案）--------------------
 *  @desc 计算所有有效GVs的总着色面积（去重交集），除以protoGT面积，得占用率。
 *  @param protoGTArea protoGT的细节面积（作为分母基准）。
 */
-(void) run4IntactRate_All:(CGFloat)protoGTArea {
    // 1、在protoGT环境占用率 = 所有有效GVs的union面积 / protoGT面积
    CGFloat bests_Proto = [SMGUtils computeArea4STGroups_Proto:self.bestSTs.allValues];
    CGFloat protoRate = (protoGTArea > 0) ? (bests_Proto / protoGTArea) : 0;
    
    // 2、在assGT环境占用率 = 所有有效GVs的union面积 / assGT面积
    CGFloat full_AssGT = [SMGUtils computeArea4Full_AssGT:self.baseGT];
    CGFloat bests_AssGT = [SMGUtils computeArea4Bests_AssGT:self];
    CGFloat assRate = (full_AssGT > 0) ? (bests_AssGT / full_AssGT) : 0;
    
    // 3、二者取其小（参考如下两例，所以得取小）。
    // 示例1、当bests占用proto为100%，但占用assGT为40%时（比如：assGT是0，proto是1，bests只是assGT=0左侧的竖1）。
    // 示例2、当bests占用assGT为100%，但占用proto为40%时（比如：assGT是1，proto是0，bests只匹配到proto=0的左侧）。
    self.intactRate_All = MIN(protoRate, assRate);
    
    // 4、裁剪到0~1
    self.intactRate_All = MIN(1.0f, MAX(0.0f, self.intactRate_All));
}

-(void) run4IntactRate_Proto:(CGFloat)protoGTArea {
    // 1、在protoGT环境占用率 = 所有有效GVs的union面积 / protoGT面积
    CGFloat bests_Proto = [SMGUtils computeArea4STGroups_Proto:self.bestSTs.allValues];
    CGFloat protoRate = (protoGTArea > 0) ? (bests_Proto / protoGTArea) : 0;
    
    // 示例2、当bests占用assGT为100%，但占用proto为40%时（比如：assGT是1，proto是0，bests只匹配到proto=0的左侧）。
    self.intactRate_Proto = protoRate;
}

/**
 *  MARK:--------------------辅因子：稳定性（参考36145-方案）--------------------
 */
-(void) run4AverageContentStrong {
    self.averageContentStrong = [self.baseGT getAverageContentStrong:self.bestSTs.allKeys];
}

// bests根据匹配度末尾淘汰20%（参考35138-TODO1）。
-(void) filter4MatchValue {
    for (STZiJvModelV2 *stGroup in self.bestSTs.allValues) {
        [stGroup filter4MatchValue];
    }
    
    NSArray *sortKeys = [SMGUtils sortSmall2Big:self.bestSTs.allKeys compareBlock:^double(NSNumber *key) {
        STZiJvModelV2 *value = [self.bestSTs objectForKey:key];
        return value.stMatchValue;
    }];
    NSArray *rmKeys = ARR_SUB(sortKeys, 0, sortKeys.count * cBestsFilterRate);
    [self.bestSTs removeObjectsForKeys:rmKeys];
}

-(void) filter4OuterShapeMatchValue {
    for (STZiJvModelV2 *stGroup in self.bestSTs.allValues) {
        [stGroup filter4OuterShapeMatchValue];
    }
    
    NSArray *sortKeys = [SMGUtils sortSmall2Big:self.bestSTs.allKeys compareBlock:^double(NSNumber *key) {
        STZiJvModelV2 *value = [self.bestSTs objectForKey:key];
        return value.stOuterShapeMatchValue;
    }];
    NSArray *rmKeys = ARR_SUB(sortKeys, 0, sortKeys.count * cBestsFilterRate);
    [self.bestSTs removeObjectsForKeys:rmKeys];
}

// GTModel综合评分（用于GT识别竞争）。
-(CGFloat) zonHeScore {
    // v1: 先不计self.stMatchDegree，因为GV的符合度，到GT识别时，已经算隔层了，再算进来，等于掐断形似匹配。
    // return self.gtMatchValue * self.gtMatchDegree * self.countRatio * (self.gtMatchCountRatio * self.stMatchCountRatio);
    
    // v2
    // return self.gtMatchValue * (self.gtMatchCountRatio * self.stMatchCountRatio) * self.intactRate;
    
    // v3: 完整性彻底替代匹配率。
    // return self.gtMatchValue * self.matchCountRatioV2 * self.intactRate_Proto;
    
    // v4: 放开交层（向ST识别对齐）。
    // return self.gtMatchValue * self.matchCountRatioV2 * self.allBestCount;
    
    // v5: 随着加权求和切图法上线，匹配数和匹配率全是100%，所以改回只用匹配度。
    return self.gtMatchValue;
}

// GTModel综合评分的描述。
-(NSString*) zonHeDesc {
    // v1
    //return STRFORMAT(@"匹配度:%.2f 符合度:%.2f 匹配数(防过抽):%.2f (%02ld/%02ld) 匹配率(防过具):%.2f = 综合得分:%.3f",self.gtMatchValue,self.gtMatchDegree,self.countRatio,self.bestSTs.count,self.baseGT.count,self.gtMatchCountRatio * self.stMatchCountRatio,self.zonHeScore);
    
    // v2
    // return STRFORMAT(@"匹配度:%.2f 匹配率:%.2f 完整性:%.2f = 综合得分:%.3f",self.gtMatchValue,(self.gtMatchCountRatio * self.stMatchCountRatio),self.intactRate,self.zonHeScore);
    
    // v3: 完整性彻底替代匹配率 & 加上稳定性。
    // return STRFORMAT(@"匹配度:%.2f 匹配率:%.2f 完整性:%.2f = 综合得分:%.3f（稳定性:%.2f）（%ld/%ld）",self.gtMatchValue,self.matchCountRatioV2,self.intactRate_Proto,self.zonHeScore,self.averageContentStrong,[self allBestCount],[self allGVCount]);
    
    // v4: 放开交层（向ST识别对齐）。
    // return STRFORMAT(@"匹配度:%.2f 匹配率:%.2f 匹配数:(%03ld/%03ld) = 综合得分:%.3f（稳定性:%.2f）",self.gtMatchValue,self.matchCountRatioV2,self.allBestCount,self.allGVCount,self.zonHeScore,self.averageContentStrong);
    
    // v5: 随着加权求和切图法上线，匹配数和匹配率全是100%，所以改回只用匹配度。
    return STRFORMAT(@"匹配度:%.2f (%02ld/%02ld) 稳定性:%.2f = 总分:%.3f",self.gtMatchValue,self.bestSTs.count,self.baseGT.count,self.averageContentStrong,self.zonHeScore);
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
