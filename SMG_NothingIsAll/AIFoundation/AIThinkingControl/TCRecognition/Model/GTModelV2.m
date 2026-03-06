//
//  GTModelV2.m
//  SMG_NothingIsAll
//
//  Created by jia on 2026/2/1.
//  Copyright © 2026 XiaoGang. All rights reserved.
//

#import "GTModelV2.h"

@implementation GTModelV2

+(id) new:(AIGroupFeatureNode*)assGT {
    GTModelV2 *result = [GTModelV2 new];
    result.assGT = assGT;
    result.bestSTDic = [NSMutableDictionary new];
    return result;
}

-(void) run4ValidAbsPorts {
    NSArray *allAbsPorts = [AINetUtils absPorts_All:self.assGT];
    
    // 方案1、用抽具象的indexDic映射，来判断它是否全含（前提：需要存上抽具象特征的indexDic映射）。
    self.validAbsPorts = [SMGUtils filterArr:allAbsPorts checkValid:^BOOL(AIPort *item) {
        NSDictionary *indexDic = [self.assGT getAbsIndexDic:item.target_p];
        // bestGVs了全含absST，则这条absST有效，收集它。
        return ![SMGUtils filterSingleFromArr:indexDic.allValues checkValid:^BOOL(id item) {
            return ![self.bestSTDic.allKeys containsObject:item];
        }];
    }];
}

/**
 *  MARK:--------------------主因子：匹配度--------------------
 */
-(void) run4MatchValue {
    self.matchValue = self.bestSTDic.count == 0 ? 0 : [SMGUtils sumOfArr:self.bestSTDic.allValues convertBlock:^double(GTItemV2 *obj) {
        return obj.matchValue;
    }] / self.bestSTDic.count;
}

/**
 *  MARK:--------------------辅因子：元素数归一化值（防过抽：因为只有具象的匹配数count才可能长）--------------------
 */
-(void) run4MatchCountRatio:(NSInteger)max {
    self.matchCountRatio = max == 0 ? 0 : (float)self.bestSTDic.count / max;
}

/**
 *  MARK:--------------------辅因子：显著度（GTItem是归一化值，此处取平均值）--------------------
 */
-(void) run4StrongRatio {
    self.strongRatio = self.bestSTDic.count == 0 ? 0 : [SMGUtils sumOfArr:self.bestSTDic.allValues convertBlock:^double(GTItemV2 *obj) {
        return obj.beAssSTStrongRatio;
    }] / self.bestSTDic.count;
}
// 2026.02.18: 关掉显著度，目前显著度效果没体现出来，先关掉测下有没问题，没问题，则彻底删掉。
-(void) run4StrongRatioByContent {
    self.strongRatioByContent = self.bestSTDic.count == 0 ? 0 : [SMGUtils sumOfArr:self.bestSTDic.allValues convertBlock:^double(GTItemV2 *obj) {
        return obj.beAssSTStrongRatioByContent;
    }] / self.bestSTDic.count;
}

/**
 *  MARK:--------------------辅因子：位置符合度（参考36045）--------------------
 */
-(void) run4MatchDegree {
    self.matchDegree = self.bestSTDic.count == 0 ? 0 : [SMGUtils sumOfArr:self.bestSTDic.allValues convertBlock:^double(GTItemV2 *obj) {
        return obj.matchDegree;
    }] / self.bestSTDic.count;
}

@end
