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
        return obj.beAssSTStrongRatio * obj.beBroSTStrongRatio;
    }] / self.bestSTDic.count;
}
-(void) run4StrongRatioByContent {
    self.strongRatioByContent = self.bestSTDic.count == 0 ? 0 : [SMGUtils sumOfArr:self.bestSTDic.allValues convertBlock:^double(GTItemV2 *obj) {
        return obj.beAssSTStrongRatioByContent * obj.beBroSTStrongRatioByContent;
    }] / self.bestSTDic.count;
}

@end
